#!/bin/sh
# swayidle_tick.sh
# swayidle's 600s idle-tick handler.
#
# swayidle `timeout` commands fire ONCE per idle stretch; timers only re-arm
# on real input or a fresh swayidle process. So this handler must own the
# "re-check later" logic. It does that by restarting this unit (a fresh
# swayidle registers a brand-new 600s window), never by polling.
#
# State machine (two markers, /tmp -> cleared on every boot):
#   playing tick            -> mark saw_playback, disarm grace, restart, exit
#   quiet tick, never played-> suspend now            (normal 10-min suspend)
#   quiet tick, saw playing -> arm grace, restart     (one full cycle, exit)
#   quiet tick, grace armed -> suspend                (>=~10 min after stop)
#
# The grace guarantees "some time passes" between playback stopping and the
# machine sleeping, without ever suspending under a user who has returned
# (their input re-arms swayidle's timers, so a later tick means 10 more idle
# minutes -> safe to suspend).
#
# NOTE: ExecStop of swayidle.service is `kill -9` so the periodic restart
# never executes stale pending `resume` commands (which would switch the
# display back on every cycle).
saw_playback=/tmp/.swayidle-saw-playback
grace=/tmp/.swayidle-grace

if can_sleep.sh; then
	# Something is playing: this restarts swayidle -> fresh timers -> the
	# quiet/playing decision is re-made after another full idle cycle.
	touch "$saw_playback"
	rm -f "$grace"
	systemctl --user restart swayidle.service &
	exit 0
fi

# Nothing is playing.
if [ ! -e "$saw_playback" ]; then
	# Media was never seen playing this stretch: 10-min idle suspend
	# (hibernates automatically after 12 h).
	rm -f "$grace"
	systemctl suspend-then-hibernate &
	exit 0
fi

if [ ! -e "$grace" ]; then
	# Playback was seen earlier but has now stopped: give it one full cycle.
	touch "$grace"
	systemctl --user restart swayidle.service &
	exit 0
fi

# Second consecutive quiet tick after playback stopped: suspend
# (hibernates automatically after 12 h).
rm -f "$grace" "$saw_playback"
systemctl suspend-then-hibernate &