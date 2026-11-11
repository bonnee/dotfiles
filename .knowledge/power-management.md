# Power management — t490

_Last verified: 2026-11-11._

## Overview

- Kernel supports S3 and hibernate: `/sys/power/state` = `freeze mem disk`;
  `/sys/power/mem_sleep` = `s2idle [deep]` (deep selected);
  `/sys/power/disk` = `[platform] shutdown reboot suspend test_resume`.
- Hibernation is configured and has been used successfully (Oct 19 and Oct 20
  2026): 32 GiB swap on `/dev/nvme0n1p3`, with
  `resume=UUID=7054f9a5-d64a-494e-8448-f6dba7cc16ea` in all systemd-boot entries.
- Stack: TLP 1.10.2 (enabled/active), `tlp-pd` 1.10.2 (backend for the
  power-profiles-daemon D-Bus API used by the Waybar profile switcher;
  the real `power-profiles-daemon` package is not installed), UPower 1.91.5,
  systemd-logind, swayidle 1.9.0.
- TLP profile mapping (`tlp(8)`): `performance` uses `_AC` parameters,
  `balanced` uses `_BAT`, `power-saver` uses `_SAV` and falls back to `_BAT`
  for settings without a `_SAV` variant. Switching in Waybar calls
  `tlp <profile>` through `tlp-pd`.
- `tlp-pd.service` is disabled in `systemctl` terms but runs: it is a
  `Type=dbus` unit with a `net.hadess.PowerProfiles` activation file, so it
  starts on first use (Waybar at session start). TLP's “not enabled” warning
  is cosmetic. `tlpctl get` shows the active profile.
- Intel Rapid Start is not available on this machine — see below.

## Idle flow and swayidle

`~/.config/systemd/user/swayidle.service` (enabled, active, part of
`sway-session.target`) runs `swayidle -w` with:

| Event | Command |
|---|---|
| logind lock | `lockw.sh` |
| 300 s idle | `can_dpms.sh \|\| swaymsg "output * dpms off"` |
| activity after 300 s | `swaymsg "output * dpms on"` |
| 330 s idle | `lockw.sh` |
| 600 s idle | `swayidle_tick.sh` |
| before sleep | `lockw.sh` |
| after resume | `sleep 1; swaymsg "output * dpms on"; swaymsg "output * power on"` |

- Idle timings: screen off at 5 min, lock at 5.5 min, suspend at 10 min.
- `ExecStop=/bin/sh -c 'kill -9 "$$MAINPID" 2>/dev/null || true'`;
  `Restart=on-failure`, `RestartSec=1`. The guard handles `MAINPID` already
  being unset at session shutdown. The tick handler restarts the unit to re-arm;
  SIGKILL avoids stale `resume` commands switching the display back on.
- A no-op `timeout 1 'true'` with the same
  `resume 'swaymsg "output * dpms on"'` keeps a DPMS resume handler alive across
  the tick restarts. A restart discards the pending 300 s resume handler;
  without this, input after a tick restart left the screen DPMS-off until a
  suspend/resume.
- `lockw.sh` runs `swaylock -f` with pywal colors and has a `pgrep -x swaylock`
  guard so a fresh swayidle cycle does not spawn a second locker.
- `can_dpms.sh` exits 0 (skip DPMS off) only when media is playing and the
  default sink looks external; otherwise it exits 1, so on the internal eDP-1
  panel `dpms off` runs.
- `can_sleep.sh` exits 0 when a player reports `Playing`, 1 otherwise, 2 if
  `playerctl` is missing. It is no longer referenced by the unit; kept for
  reference.

### `swayidle_tick.sh` (the 600 s handler)

`timeout` commands fire once per idle stretch; they re-arm only on input or a
fresh swayidle process. The handler owns the re-check logic with two `/tmp`
markers (`/tmp/.swayidle-saw-playback`, `/tmp/.swayidle-grace`; cleared on
boot):

| State | Action |
|---|---|
| playing | touch saw, rm grace, `systemctl --user restart swayidle.service &` |
| quiet, never played | rm grace, `systemctl suspend-then-hibernate &` |
| quiet, saw playing, no grace | touch grace, restart swayidle |
| quiet, saw playing, grace armed | rm both markers, `systemctl suspend-then-hibernate &` |

The self-restart was tested with a throwaway unit: a systemd service restarting
itself from its own cgroup completes reliably.

## Sleep operation and triggers

- The sleep operation is `suspend-then-hibernate`, with
  `/etc/systemd/sleep.conf.d/50-hibernate-delay.conf` setting
  `HibernateDelaySec=12h`.
- `/etc/systemd/logind.conf.d/50-suspend-then-hibernate.conf` sets
  `HandlePowerKey`, `HandleSuspendKey`, `HandleLidSwitch`, and
  `HandleLidSwitchExternalPower` to `suspend-then-hibernate`. The main
  `/etc/systemd/logind.conf` still has `suspend` for those keys and
  `HandlePowerKeyLongPress=hibernate`; the drop-in is parsed later and
  overrides the four keys. Long press remains hibernate.
- `~/.local/bin/pwrmenu.sh` “Suspend” calls
  `systemctl suspend-then-hibernate`; “Hibernate” calls `systemctl hibernate`.
- `~/.local/bin/swayidle_tick.sh` calls
  `systemctl suspend-then-hibernate` in both suspend branches.
- The legacy i3 config (`~/.config/i3/config`, not used by the current Sway
  session) has the same suspend binding updated.
- A bare `systemctl suspend` is still plain suspend; use
  `systemctl suspend-then-hibernate` for the 12 h behavior.

### IdleAction

- `IdleAction` is unset, so logind uses the default `ignore`.
- `swayidle` has no `idlehint`, and the current session reports `IdleHint=no`;
  logind idle actions are not used. `IdleAction` should stay unset: swayidle
  owns idle policy and is media-aware, while logind handles hardware events
  (lid, power key, suspend key).

## Hibernate delay details

- Drop-ins are parsed after `/etc/systemd/sleep.conf`, so the effective value
  is 12 h.
- **Gotcha:** `/etc/systemd/sleep.conf` line 27 still contains
  `HibernateDelaySec=1min` from a test. The drop-in overrides it, but the
  duplicate is a trap; remove it (tracked in `TODO.md`).
- `systemd-suspend-then-hibernate.service` is stock. With a battery it
  hibernates earlier than the delay if the battery drops below 5%
  (`systemd-sleep.conf(5)`). UPower's `CriticalPowerAction=Auto`
  (`PercentageAction=2%`) is therefore safe.
- A manual wake before 12 h cancels the pending hibernate; the machine resumes
  and the idle logic starts a new 12 h window on the next suspend.
- A spurious wake also cancels the pending hibernate. On Oct 14 the
  `suspend-then-hibernate` operation woke after ~80 s; the journal shows
  `typec port1-partner: PM: parent port1 should not be sleeping`, and the
  operation returned `suspend-then-hibernate` instead of hibernating.

## Sleep hooks

- `/usr/lib/systemd/system-sleep/`: `sysstat.sleep`, `tlp`.
- `suspend.target.wants` contains only `linux-enable-ir-emitter.service`
  (enabled). It runs `modprobe uvcvideo` then `linux-enable-ir-emitter run`,
  requires `dev-video2.device`, and is pulled in for suspend, hibernate,
  hybrid-sleep, and suspend-then-hibernate.
- `systemd-suspend.service` has no local override (stock).

## Media pause before sleep

`/etc/systemd/system/playerctl-pause.service` is a system oneshot
(`Type=oneshot`, `User=bonnee`, `Before=sleep.target`,
`WantedBy=sleep.target`, `ExecStart=-/usr/bin/playerctl -a pause`) with
`HOME`, `XDG_RUNTIME_DIR=/run/user/123`, and
`DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/123/bus`. It runs before
`systemd-suspend.service`, `systemd-hibernate.service`, and
`systemd-suspend-then-hibernate.service` (all are `After=sleep.target`) and
before `user.slice` is frozen, so it covers manual, lid, power-key, and
automatic sleep. The process runs as `bonnee`, not root. `swayidle`'s
`before-sleep` now only runs `lockw.sh`.

`systemctl start playerctl-pause.service` runs it on demand (pauses current
players); `systemctl status playerctl-pause.service` shows the last run.

## Known issues

### Mangled analog audio outside performance mode (2026-11-06)

On the built-in speakers/headphones (Realtek ALC257, `snd_hda_intel` on
`00:1f.3`), playback is garbled whenever the Waybar profile is not
`performance`. Cause: TLP's Intel HDA power saving is enabled only in the
non-performance profiles.

- `/etc/tlp.d/10-custom.conf` has `SOUND_POWER_SAVE_ON_AC=0`,
  `SOUND_POWER_SAVE_ON_BAT=1`, `SOUND_POWER_SAVE_CONTROLLER=Y`.
- `performance` uses the `_AC` values → `power_save=0`, clean audio.
- `balanced` uses `_BAT` and `power-saver` inherits `_BAT` → TLP writes
  `power_save=1`, and with `power_save_controller=Y` the HDA controller
  runtime-suspends too. Observed live: profile `balanced`/BAT on battery,
  `power_save=1`, `power_save_controller=Y`.
- The kernel default is `power_save=0`, so the `1` is written by TLP, not the
  module.
- `journalctl -k` has `snd_hda_intel 0000:00:1f.3: Unstable LPIB (261256 >=
  8192); disabling LPIB delay counting` (2026-10-27), a symptom of the
  controller's position register misbehaving around low-power transitions.
- `pw-top` showed `ERR 0` while capture/playback ran, so this is below the
  PipeWire graph (not xruns); it tracks the power-save setting.

Fix: disable TLP sound power save on battery as well (staged
`/tmp/opencode/20-audio-no-powersave.conf`):

```sh
sudo install -m 644 /tmp/opencode/20-audio-no-powersave.conf /etc/tlp.d/20-audio.conf
sudo tlp start   # or toggle the Waybar profile away and back
cat /sys/module/snd_hda_intel/parameters/power_save   # expect 0
```

Do not "fix" it by staying in performance mode: that also forces AC CPU,
Wi-Fi and PCIe settings on battery.

### Suspend-entry delay

On Oct 19 00:31 the auto-suspend spent 41.9 s between
`Freezing user space processes` (monotonic 372326.768) and
`Freezing user space processes completed (elapsed 0.001 seconds)`
(monotonic 372368.670). That is two `pm_freeze_timeout` windows
(`/sys/power/pm_freeze_timeout` = 20000 ms). The machine then entered S3, and
the morning wake was ~1 s. No `refusing to freeze` lines were logged for this
event. At the time, `kworker/u33:1+i915_flip` was in D-state (possibly
unrelated).

It recurred on Oct 23 16:17 (power-key suspend): 43.6 s between
`PM: suspend entry (deep)` (monotonic 422132.369) and
`Freezing user space processes` (422175.987); the freeze itself then took
0.005 s, and the suspend unit consumed 44.897 s wall clock. The wake was fast.
The delay is in the suspend path, not resume. If it recurs, check
`journalctl -k -b | grep -A3 'refusing to freeze'` and inspect D-state tasks.

### Stale SWAYSOCK after a Sway restart

`swayidle.service` and `libinput-gestures.service` inherit `SWAYSOCK` when they
start. After the Sway session restarted on 2026-10-21, both still pointed at the
dead `/run/user/123/sway-ipc.123.2205.sock`; their `swaymsg` children failed
with `Unable to connect ...` after every resume, so swayidle's after-resume and
DPMS commands were no-ops. Restarting both user services on 2026-10-23 gave them
the current socket. Restart them after a Sway restart:
`systemctl --user restart swayidle.service libinput-gestures.service`.

### Resume input/lock delay (2026-10-23)

On the 16:27 wake, `PM: suspend exit` → `user.slice` thawed took 0.8 s, but the
caps-lock LED stayed off while the lock screen was up (it works normally) and the
`gkr-pam` keyring unlock was 4.36 s after resume. That indicates the keyboard
input path was not active during the stall. The keyboard path is kmonad's virtual
`t490` device (the physical `AT Translated Set 2 keyboard` is grabbed by kmonad).

As of 2026-10-23, the swayidle `after-resume` command restarts
`kmonad@t490.service` after a 1 s settle, before the DPMS commands, to re-create
the input path. Verify on the next resume.

### SD card reader lost after resume (2026-11-02)

The RTS522A reader drops its card after S3 resume and after idle/runtime
suspend (`mmc0: error -110 doing runtime resume`, then
`mmc0: card ... removed`; the slot then looks dead until the host is
rebound). Mitigated by an udev rule that keeps the PCI function
runtime-active plus a `post` sleep hook that rebinds the host — see
`sdcard-reader.md`.

### Resume maintenance catch-up

`man-db`, `btrbk`, `logrotate`, and `snapper-timeline` are `OnCalendar`
timers and catch up on resume. On Oct 19 07:26 the kernel/session resume took
~1 s, then `btrbk-backup` ran 12.9 s and `man-db` ran 24.2 s (22.4 s CPU,
263 MB), followed by another btrbk run at 07:30. This is the slow wake that
was investigated; the decision was to leave the timers as-is. Details and the
timer table are in `maintenance.md`.

### Intel Rapid Start

Not available on this T490:

- no partition with GPT type `d3bfe2de-3daf-11df-ba40-e3a556d89593`;
- no `Rapid Start` / `IRST` strings in ACPI tables, dmesg, or EFI variables;
- NVMe-only (WD SN810); Intel Rapid Storage Technology (storage/Optane) is a
  different feature.

Use `suspend-then-hibernate`; the BIOS setting itself was not inspected (the
BIOS `Config -> Power` menu is the place to confirm).

### TPM wedged after hibernation resume (2026-10-24)

- Several SSH identities are TPM-sealed: `~/.ssh/{github,gitlab,codeberg,srht,t490,cloud.polito}.tpm`
  with public halves in the matching `.pub`; no private-key file exists for
  them. `ssh-tpm-agent` serves them on `$XDG_RUNTIME_DIR/ssh-tpm-agent.sock`
  (user socket `ssh-tpm-agent.socket`, enabled in `sockets.target.wants`).
- On 2026-10-24 the second hibernate of the day (`systemctl hibernate` 13:07,
  resumed 15:13:31) left the TPM unresponsive. Seven seconds after
  `PM: hibernation: hibernation exit` the kernel logged
  `tpm tpm0: NULL Seed name comparison failed`, and afterwards every TPM
  command returned EIO 5 (`tpm2_getrandom`, reads of `/dev/tpmrm0` and
  `/dev/tpm0`). `ssh-tpm-agent` failed every signature with
  `failed creating primary key: read /dev/tpmrm0: input/output error`; `ssh`
  reported `agent refused operation` and GitHub rejected the key. HTTPS to
  GitHub was unaffected. The earlier hibernate of the same day (13:03 resume)
  was fine; the cause of the wedge is not known.
- The session hung after this and the machine was force-rebooted with
  7× Ctrl-Alt-Del (`Forcibly rebooting: Ctrl-Alt-Del was pressed more than
  7 times within 2s`, 15:20:22). The TPM answered normally on the next boot;
  a driver unbind/rebind was not tried.
- That reboot came up without a user manager, so `ssh-tpm-agent` was absent;
  starting it by hand (`setsid ssh-tpm-agent </dev/null &`) restored the socket.
  The manager was restored on the same day with `sudo loginctl enable-linger
  bonnee` — see "Missing user manager (linger off)" below.

### Missing user manager (linger off, 2026-10-24)

- Lingering is enabled: `/var/lib/systemd/linger/bonnee` exists (created
  2026-10-24 15:30), `loginctl show-user bonnee` reports `Linger=yes`, and
  `user@123.service` runs. The manager appears as a `manager-early` session
  (`Class=manager-early`, no TTY, no seat).
- The tty logins themselves stay `Class=user-light` (`Service=login`;
  `Type=wayland` once sway has started). User-light sessions do not activate a
  manager (systemd 262 `NEWS`), and nothing else starts it without linger, so
  the user bus is absent and `systemctl --user` fails with
  `Failed to connect to user scope bus via local transport: No such file or
  directory`. Everything in the user slice then stays down: `ssh-tpm-agent`,
  `swayidle`, `kmonad@t490`, `pipewire`, rclone mounts,
  `sway-session.target`.
- Symptom before linger was re-enabled at 15:30: sway started from tty1 but ran
  with no hardware — `swaymsg -t get_outputs` returned `[]`, `get_seats`
  reported capabilities 0 and no devices — while `eDP-1` was connected,
  `card1` could be opened and `drmSetMaster` succeeded, and input nodes were
  readable. Clients still connected (Alacritty instances stayed alive), so the
  panel simply kept showing the console and the compositor looked hung. A later
  start attempt exited during startup instead.
- After enabling linger, a sway started from tty1 came up normally: `eDP-1`
  1920x1080, seat capabilities 3, waybar, swayidle, and kmonad's `t490` virtual
  keyboard present.
- Assumption: that the missing manager itself caused the blind compositor is
  not proven; the same period had VT switches between tty1/tty2/tty3 and sway
  may have started while its session was not the seat's active one. wlroots does
  not re-acquire DRM/input devices when a session activates later, so a
  compositor that starts without them stays blind until restarted. Check the
  cause properly if it repeats.
- The system side of systemd stayed responsive throughout: `systemctl`,
  `loginctl`, `busctl`, `journalctl` answered in milliseconds, no failed system
  units, no pending jobs. Privileged `systemctl` calls need polkit, and commands
  typed on a tty whose foreground process is a blind sway never reach the shell
  — both look like "systemd hangs".

## Useful commands

```sh
systemctl suspend-then-hibernate
systemctl hibernate
systemd-analyze cat-config systemd/sleep.conf
systemd-analyze cat-config systemd/logind.conf
cat /sys/power/state /sys/power/mem_sleep /sys/power/disk
journalctl -k -b | grep -E 'PM: suspend|Freezing'
systemctl --user restart swayidle.service libinput-gestures.service  # after a Sway restart
loginctl lock-session          # triggers swayidle's `lock` -> lockw.sh
loginctl show-user bonnee -p Linger State Service   # linger / user manager state
playerctl status
```
