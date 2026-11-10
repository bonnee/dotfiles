#!/usr/bin/env python3
"""Pinned screenshot with selectable OCR text drawn per character.

Usage:
  santino-gui.py [-l LANG]                 slurp a region, capture it, pin it
  santino-gui.py --image FILE --region X,Y,W,H [-l LANG]
                                            pin an existing capture

The window is placed by sway so that its image content covers exactly the
pinned region. One drawing widget spans the whole region, so every line of
recognized text belongs to a single selection scope (one virtual textbox).
Each line renders one glyph per tesseract makebox character, so every
overlaid character sits in the exact rectangle of the screenshot's glyph
(per-character alignment). In the default state nothing is drawn on top of
the image, so the pin looks exactly like the capture. Hovering text draws
only a soft band; dragging paints a selection highlight over exactly the
screenshot's own glyph boxes while the OCR text itself stays invisible, so
it reads as selecting the real text in the capture. Press t to reveal the
recognized text when you want to verify it.

Mouse:
  double click   select the word
  triple click   select the line
  drag           any range, crossing lines freely

Keys:
  Esc            close
  Ctrl+C/Insert  copy the selection; copies all text if nothing is selected
  Ctrl+A         select everything (every line)
  t              reveal/hide the OCR glyphs over the text (band stays)
"""

import argparse
import atexit
import json
import math
import os
import select
import signal
import socket
import struct
import subprocess
import sys
import tempfile
import threading
import time

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("PangoCairo", "1.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk, Pango, PangoCairo

try:                                    # GLib >= 2.56: unix signal sources
    from gi.repository import GLibUnix  # without deprecating GLib's copy
except ImportError:
    GLibUnix = None

# Temporary files this process owns. Every exit path routes through
# _cleanup(): atexit alone is not enough, because a SIGTERM from a session
# manager (or a plain kill) never runs it.
_TMP = []


def _cleanup():
    while _TMP:
        try:
            os.unlink(_TMP.pop())
        except OSError:
            pass


def notify(urgency, summary, body):
    """Desktop notification; never fatal (notify-send may be absent)."""
    try:
        subprocess.run(["notify-send", "-a", "santino", "-t", "5000", "-u",
                        urgency, summary, body],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       timeout=10)
    except Exception:
        pass


MIN_CONF = 40


# --- direct sway IPC (window-event subscription) -------------------------
# `swaymsg -m -t subscribe` gives no way to know when it is actually
# subscribed, so the worker could race window creation and miss the map
# events (falling back to a slow polling timeout -> a visible mid-screen
# flash). Subscribing over the raw socket returns an acknowledgement, which
# we use to gate window mapping: by the time the window can appear, we are
# guaranteed to already be listening for its events.

_SWAY_MAGIC = b"i3-ipc"


def _sway_pack(mtype, payload=b""):
    return _SWAY_MAGIC + struct.pack("<II", len(payload), mtype) + payload


def _sway_read_exact(s, n):
    buf = b""
    while len(buf) < n:
        try:
            chunk = s.recv(n - len(buf))
        except Exception:
            return None
        if not chunk:
            return None
        buf += chunk
    return buf


def sway_subscribe_window():
    """Subscribe to sway window events; return the socket once acknowledged."""
    path = os.environ.get("SWAYSOCK")
    if not path:
        return None
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        s.settimeout(2.0)
        s.connect(path)
        s.sendall(_sway_pack(2, b'["window"]'))
        hdr = _sway_read_exact(s, 14)
        if not hdr:
            raise ValueError("no reply")
        _magic, length, _t = struct.unpack("<6sII", hdr)
        pl = _sway_read_exact(s, length) if length else b""
        if not (pl and json.loads(pl).get("success")):
            raise ValueError("subscribe not acknowledged")
        s.settimeout(5.0)
        return s
    except Exception:
        try:
            s.close()
        except Exception:
            pass
        return None


# sway_next_event() used to return None both when nothing had arrived yet and
# when the subscription had died, so a compositor that was merely quiet for
# 300ms silently dropped us off the exact event path and into get_tree
# polling. Two distinct sentinels keep those apart.
_EVENT_TIMEOUT = object()      # nothing yet, socket still healthy
_EVENT_ERROR = object()        # subscription is gone, stop listening


def sway_next_event(sock, timeout=0.3):
    """Next event dict, _EVENT_TIMEOUT, or _EVENT_ERROR."""
    try:
        ready, _, _ = select.select([sock], [], [], timeout)
        if not ready:
            return _EVENT_TIMEOUT
        hdr = _sway_read_exact(sock, 14)
        if not hdr:
            return _EVENT_ERROR
        _magic, length, _t = struct.unpack("<6sII", hdr)
        pl = _sway_read_exact(sock, length) if length else b""
        if not pl:
            return _EVENT_ERROR
        return json.loads(pl)
    except Exception:
        return _EVENT_ERROR


def _sway_request(mtype, payload=b""):
    """One-shot IPC round-trip over a fresh socket (no fork/exec -> fast)."""
    path = os.environ.get("SWAYSOCK")
    if not path:
        return None
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        s.settimeout(5.0)
        s.connect(path)
        s.sendall(_sway_pack(mtype, payload))
        hdr = _sway_read_exact(s, 14)
        if not hdr:
            return None
        _magic, length, _t = struct.unpack("<6sII", hdr)
        return _sway_read_exact(s, length) if length else b""
    except Exception:
        return None
    finally:
        try:
            s.close()
        except Exception:
            pass


def sway_run(cmd):
    """Run a sway command string; returns the raw reply bytes or None."""
    return _sway_request(0, cmd.encode())


def sway_tree():
    """get_tree as parsed JSON (or None)."""
    pl = _sway_request(4)
    try:
        return json.loads(pl) if pl else None
    except Exception:
        return None


def find_window(pid):
    tree = sway_tree()
    if not tree:
        return None
    found = {}

    def walk(n):
        if found:
            return
        if n.get("pid") == pid:
            found["node"] = n
            return
        for c in n.get("nodes", []) + n.get("floating_nodes", []):
            walk(c)

    walk(tree)
    return found.get("node")


def measure(node):
    r = node["rect"]
    wr = node["window_rect"]
    # The pin uses a symmetric pixel border, so deriving it from the size
    # difference is reliable even during sway's transient "floating" event,
    # where window_rect's x/y offset has not been applied yet (it can read 0
    # on one side while the size is already final).
    bh = max(0, r["width"] - wr["width"])
    bv = max(0, r["height"] - wr["height"])
    return {
        "content": (r["x"] + wr["x"], r["y"] + wr["y"],
                    wr["width"], wr["height"]),
        "borders": {
            "left": bh // 2,
            "top": bv // 2,
            "right": bh - bh // 2,
            "bottom": bv - bv // 2,
        },
    }


# Focus: out of scope. This tool never requests focus and must not start.
# The pin is a passive surface; the no_focus rule in 50_rules.conf is what
# keeps sway from handing it focus at map time. Selection and hover work
# regardless -- they ride on pointer events, which go to whatever surface is
# under the cursor whether or not it has keyboard focus.


def snap_to_region(pid, rx, ry, rw, rh, node=None):
    """Float the window so its content covers (rx,ry,rw,rh).

    The placement is issued as a single batched sway command straight from the
    map event (no get_tree round-trip), with one optional correction after it.
    The sway border is kept (it frames the pin so it stays visible on screen);
    the offset math accounts for it, so the content lands on the region. The
    content may end up a couple of px taller/wider than the region, since sway
    and GTK enforce a minimum window size -- see placed_ok().
    """
    def place(n, how):
        b = measure(n)["borders"]
        ox, oy = rx - b["left"], ry - b["top"]
        ow = rw + b["left"] + b["right"]
        oh = rh + b["top"] + b["bottom"]
        if ow < 1 or oh < 1:
            return
        cmd = ("[pid=%d] floating enable, resize set %d %d, "
               "move absolute position %d %d"
               % (pid, round(ow), round(oh), round(ox), round(oy)))
        sway_run(cmd)                          # direct IPC: lands this frame

    def placed_ok(n):
        """Only position is worth checking here.

        The size cannot be verified: sway and GTK floor the window a couple of
        px above the region, so "does the content equal the region?" is never
        answered yes -- and re-sending the command cannot lift a floor anyway.
        Position either landed or it did not (a move issued before the window
        was floating is simply dropped), so that is the signal that matters.
        """
        cx, cy = measure(n)["content"][:2]
        return abs(cx - rx) <= 1 and abs(cy - ry) <= 1

    if node is not None and not placed_ok(node):
        place(node, "map-event")    # not yet placed: shot, no tree trip

    # Exactly one corrective placement, then stop. No polling loop: the
    # pipelined command (presnap_worker) and the shot above land in the same
    # sway event-loop pass as the map, so one fresh look afterwards is enough
    # to mop up a rejected first shot. A loop buys nothing and costs a lot --
    # it retried ~10 times per pin for a size it could never reach, which was
    # also what silently undid drags.
    n = find_window(pid)              # fresh state, not the map-event snapshot
    if n is not None and not placed_ok(n):
        place(n, "correct")
    return True


DEFAULT_BORDER = 4                # matches sway's `default_border pixel N`


def sway_border():
    """Total (horizontal, vertical) border sway applies, or None.

    Every window uses the configured `default_border`, so any window already
    in the tree reports it as (outer - content). Needed only to pre-place the
    pin before it exists; snap_to_region re-measures the exact value off our
    own window straight afterwards, so a wrong guess here costs at most a few
    pixels on the first frame and never survives past it.
    """
    tree = sway_tree()
    if not tree:
        return None
    found = []

    def walk(n):
        if found:
            return
        r, wr = n.get("rect"), n.get("window_rect")
        if (n.get("app_id") or n.get("window")) and r and wr and \
                r["width"] > wr["width"] and r["height"] > wr["height"]:
            found.append((r["width"] - wr["width"],
                          r["height"] - wr["height"]))
        for c in n.get("nodes", []) + n.get("floating_nodes", []):
            walk(c)

    walk(tree)
    return found[0] if found else None


def presnap_worker(pid, rx, ry, rw, rh, border, stop):
    """Keep the placement command queued in sway so one is pending at the map.

    sway maps a window and paints it in the same pass, so the map event can
    only ever be delivered *after* the first frame is committed: reacting to
    it always loses, which is why the pin flashed at screen centre first. A
    command still sitting unread in sway's socket is handled in the same
    event-loop iteration as the map, so frame one is already in the right
    place and at the right size.

    Commands are pipelined rather than awaited one round trip at a time --
    a round trip leaves the socket empty again, which is exactly when a map
    would slip through. Replies are drained as they arrive so sway's side
    can never back up. Anything sent before the window exists fails
    harmlessly, and position_worker ends this the moment the real window is
    seen, leaving the exact re-measured placement the last word.

    When wlroots grows xx-zones-v1 this whole burst collapses to a single
    request. The protocol (merged into wayland-protocols Feb 2026, still
    under the experimental `xx-` prefix and implemented by no compositor)
    offers xx_zone_item_v1.set_position(x, y), double-buffered and applied
    on the next wl_surface.commit -- exactly what is being faked here, but
    authoritative instead of racy. It also emits frame_extents(), which
    would replace the border guess in main(). Do not delete this function
    when that lands: the spec lets the compositor refuse a placement and
    answer position_failed(), so the IPC path stays as the fallback.
    """
    path = os.environ.get("SWAYSOCK")
    if not path:
        return
    ow, oh = rw + 2 * border, rh + 2 * border
    msg = _sway_pack(0, ("[pid=%d] floating enable, resize set %d %d, "
                         "move absolute position %d %d"
                         % (pid, round(ow), round(oh),
                            round(rx - border), round(ry - border))).encode())
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        s.settimeout(2.0)
        s.connect(path)
        s.setblocking(False)
        deadline = time.time() + 2.0
        # Paced, not a tight loop. What makes frame one land in the right
        # place is that at least one command is sitting unread in sway's
        # socket when the map is processed -- not how many. A tight loop
        # pushed ~2600 identical commands per pin for the same result: pacing
        # at 0.5ms measured 20/20 correctly placed against 19/20 for the
        # tight loop, at ~64 commands instead of ~2600.
        pace = 0.0005
        while not stop.is_set() and time.time() < deadline:
            try:
                s.sendall(msg)
            except (BlockingIOError, InterruptedError):
                pass           # kernel buffer full: that is the point -- keep it full
            try:
                if select.select([s], [], [], 0)[0]:
                    s.recv(262144)
            except Exception:
                pass
            time.sleep(pace)
    except Exception:
        pass
    finally:
        try:
            s.close()
        except Exception:
            pass


def position_worker(pid, rx, ry, rw, rh, ready=None, stop=None, placed=None):
    """Detect the window the moment sway maps it, then snap it in place.

    Subscribes to sway window events directly (acknowledged, so it is active
    before the window is mapped), then acts on the first event that carries
    real geometry (sway emits a "floating" event once the float rule applied)
    so the first painted frame is already at the right position (no flash).
    `ready` is set once we are listening, so the caller can gate mapping on
    it; `stop` ends the pre-map placement burst (see presnap_worker) as soon
    as the real window exists; `placed` is called once the pin is in its
    final position, which is what lets the caller finally show the capture.
    """
    try:
        sock = sway_subscribe_window()
        if ready is not None:
            ready.set()                # subscribed (or gave up): safe to map
        deadline = time.time() + 12.0
        node = None
        if sock is not None:
            try:
                while time.time() < deadline:
                    ev = sway_next_event(sock, 0.3)
                    if ev is _EVENT_ERROR:
                        break          # subscription lost: fall back to polling
                    if ev is _EVENT_TIMEOUT:
                        continue       # still listening, sway is just quiet
                    c = ev.get("container") or {}
                    if c.get("pid") != pid:
                        continue
                    node = c                   # latest known state
                    r = c.get("rect") or {}
                    if r.get("width") and r.get("height"):
                        break                  # settled enough to place
            finally:
                try:
                    sock.close()
                except Exception:
                    pass
        while node is None and time.time() < deadline:
            node = find_window(pid)
            if node is None:
                time.sleep(0.02)
        if stop is not None:
            stop.set()      # pre-map burst over: exact placement has the last word
        if node:
            snap_to_region(pid, rx, ry, rw, rh, node)
        if placed is not None:
            placed()        # in place (or never coming): safe to show the capture
    finally:
        if stop is not None:
            stop.set()


# --------------------------------------------------------------------------
# OCR data: TSV gives the trusted lines/words, makebox gives per-character
# boxes so every overlaid glyph lands on the screenshot's own glyph.
# --------------------------------------------------------------------------

def parse_tsv_words(tsv_text):
    """Tesseract TSV -> list of (blk, par, line, x, y, w, h, conf, text)."""
    words = []
    for row in tsv_text.splitlines()[1:]:
        f = row.split("\t")
        if len(f) < 12:
            continue
        try:
            level = int(f[0])
            blk, par, ln = int(f[2]), int(f[3]), int(f[4])
            conf = float(f[10])
        except ValueError:
            continue
        if level != 5:           # word level carries the text
            continue
        txt = f[11]
        if not txt.strip() or conf < MIN_CONF:
            continue
        x, y, w, h = int(f[6]), int(f[7]), int(f[8]), int(f[9])
        words.append((blk, par, ln, x, y, w, h, conf, txt))
    return words


def group_words(words):
    groups = []
    cur = []
    for wd in words:
        key = (wd[0], wd[1], wd[2])
        if cur and key != (cur[-1][0], cur[-1][1], cur[-1][2]):
            groups.append(cur)
            cur = []
        cur.append(wd)
    if cur:
        groups.append(cur)
    return groups


def parse_tsv(tsv_text):
    """Merged per-line (x, y, w, h, conf, text) from TSV words."""
    out = []
    for grp in group_words(parse_tsv_words(tsv_text)):
        x = min(w[3] for w in grp)
        y = min(w[4] for w in grp)
        right = max(w[3] + w[5] for w in grp)
        bottom = max(w[4] + w[6] for w in grp)
        text = " ".join(w[8] for w in grp)
        conf = sum(w[7] for w in grp) / len(grp)
        out.append((x, y, right - x, bottom - y, conf, text))
    return out


def parse_makebox(text, ih, iw):
    """tesseract makebox -> list of (x, y, w, h, char), top-origin coords."""
    out = []
    for row in text.splitlines():
        f = row.split()
        if len(f) < 6:
            continue
        c = f[0]
        if not c:
            continue
        try:
            left, bottom, right, top = map(int, f[1:5])
        except ValueError:
            continue
        w, h = right - left, top - bottom
        if w < 1 or h < 1:
            continue
        y = ih - top                     # flip from bottom-origin
        if left < -2 or y < -2 or left + w > iw + 2 or y + h > ih + 2:
            continue
        out.append((max(0, left), max(0, y), w, h, c))
    return out


def build_char_line(chars):
    """Sort chars left-to-right and insert spaces at word gaps.

    Returns (text, cboxes) with cboxes parallel to text; spaces get a box
    spanning the inter-word gap so hit-testing works everywhere.
    """
    chars = sorted(chars, key=lambda c: c[0])
    if not chars:
        return "", []
    heights = sorted(c[3] for c in chars)
    med_h = heights[len(heights) // 2] or 8.0
    gap = max(2.0, 0.4 * med_h)
    text = []
    boxes = []
    prev = None
    for (x, y, w, h, c) in chars:
        if prev is not None and x - (prev[0] + prev[2]) > gap:
            gx = prev[0] + prev[2]
            gw = x - gx
            ty = min(y, prev[1])
            tb = max(y + h, prev[1] + prev[3])
            text.append(" ")
            boxes.append((gx, ty, gw, tb - ty))
        text.append(c)
        boxes.append((x, y, w, h))
        prev = (x, y, w, h)
    return "".join(text), boxes


def synthetic_cboxes(line, ih):
    """Evenly spread a (x,y,w,h,conf,text) line across its box (fallback)."""
    x, y, w, h, conf, text = line
    n = max(len(text), 1)
    cw = w / n
    boxes = []
    for i in range(len(text)):
        boxes.append((x + i * cw, y, max(cw, 1.0), h))
    return boxes


_TESS_CACHE = {}


def tess_args(lang):
    """tesseract argv tail for `lang`, cached per language.

    Prefers the system-installed tessdata, falling back to ~/.tessdata as a
    no-root option. None when the language is unavailable anywhere.
    """
    if lang in _TESS_CACHE:
        return _TESS_CACHE[lang]
    args = None
    try:
        r = subprocess.run(["tesseract", "--list-langs"],
                           capture_output=True, text=True, timeout=30)
        if any(line.strip() == lang for line in r.stdout.splitlines()):
            args = ["-l", lang]
    except Exception:
        pass
    if args is None:
        home_tess = os.path.join(os.path.expanduser("~"), ".tessdata")
        if os.path.isfile(os.path.join(home_tess, "%s.traineddata" % lang)):
            args = ["--tessdata-dir", home_tess, "-l", lang]
    _TESS_CACHE[lang] = args
    return args


def run_tesseract(image, lang, mode):
    """tesseract stdout for `mode` ('tsv' | 'makebox'); '' on any failure."""
    args = tess_args(lang)
    if args is None:
        return ""
    try:
        r = subprocess.run(["tesseract", image, "stdout", *args, mode],
                           capture_output=True, text=True, timeout=30)
    except Exception:
        return ""
    return r.stdout


def ocr_lines(image, lang, ih, iw):
    """Per-line boxes with per-character boxes.

    Each entry: (x, y, w, h, conf, text, cboxes). The text is built from the
    makebox characters (filtered by tesseract TSV word boxes), so the overlay
    text, the char boxes and the copied text are all consistent.
    """
    tsv_out = run_tesseract(image, lang, "tsv")
    lines = parse_tsv(tsv_out)
    if not lines:
        return []
    word_groups = group_words(parse_tsv_words(tsv_out))
    chars = parse_makebox(run_tesseract(image, lang, "makebox"), ih, iw)
    if not chars:
        return [ln + (synthetic_cboxes(ln, ih),) for ln in lines]

    # Every word's x-range (from the accepted TSV words) guards the chars.
    word_xr = []
    for i, (x, y, w, h, conf, text) in enumerate(lines):
        grp = word_groups[i] if i < len(word_groups) else []
        word_xr.append([(g[3], g[3] + g[5]) for g in grp]
                       or [(x, x + w)])

    assigned = [[] for _ in lines]
    for (cx, cy, cw, ch, c) in chars:
        ccy = cy + ch / 2.0
        for i, (x, y, w, h, conf, text) in enumerate(lines):
            if not (y - 2 <= ccy <= y + h + 2):
                continue
            if any(x0 - 4 <= cx <= x1 + 4 for (x0, x1) in word_xr[i]):
                assigned[i].append((cx, cy, cw, ch, c))
            break

    result = []
    for i, (x, y, w, h, conf, text) in enumerate(lines):
        text2, boxes = build_char_line(assigned[i])
        if not text2:
            text2, boxes = text, synthetic_cboxes((x, y, w, h, conf, text), ih)
        x0 = min(b[0] for b in boxes)
        y0 = min(b[1] for b in boxes)
        x1 = max(b[0] + b[2] for b in boxes)
        y1 = max(b[1] + b[3] for b in boxes)
        result.append((x0, y0, x1 - x0, y1 - y0, conf, text2, boxes))
    return result


def char_index(cboxes, x):
    """Character index under x (widget coords); cboxes are (x,y,w,h)."""
    n = len(cboxes)
    if n == 0:
        return 0
    if x < cboxes[0][0]:
        return 0
    last = cboxes[-1]
    if x >= last[0] + last[2]:
        return n - 1
    lo, hi = 0, n - 1
    while lo < hi:
        mid = (lo + hi) // 2
        if x < cboxes[mid][0]:
            hi = mid
        elif x >= cboxes[mid][0] + cboxes[mid][2]:
            lo = mid + 1
        else:
            return mid
    return lo


# --------------------------------------------------------------------------
# Overlay widget: ONE widget covering the whole pinned region, so every OCR
# line shares a single selection scope -- a virtual textbox. Dragging across
# a line break keeps selecting through the gap; Ctrl+A selects everything;
# Ctrl+C copies the (possibly multi-line) selection. Highlight boxes are
# sized to the screenshot's own glyphs; glyphs stay invisible unless toggled
# with `t`.
# --------------------------------------------------------------------------

class OverlayArea(Gtk.DrawingArea):
    FONT_FAMILY = "monospace"
    BAND = (0.667, 0.824, 1.0, 0.22)          # hover band
    SEL = (0.275, 0.510, 1.0, 0.55)           # selection band

    def __init__(self, rw, rh, shown):
        super().__init__()
        self.rw, self.rh = max(1, rw), max(1, rh)
        self.shown = shown                    # callable() -> bool
        self.lines = []    # [{x,y,w,h,text,boxes}] all coords in region space
        self.text = ""     # every line joined with "\n" (the whole textbox)
        self.off = []      # global index of each line's first character
        self.sel = None    # (start, end) global, end >= start
        self._anchor = None    # global index where the drag started
        self.hovered = -1      # line index under the pointer (-1 = none)
        self._over = False     # pointer inside some line's box
        self._dbl = None       # cached double-click (seconds, px) limits
        self._prev_click = None    # (time, x, y, word) of the previous press
        self._click_n = 0          # presses counted inside that window
        self._cursor_text = None   # cached I-beam cursor
        self._cursor_on = False
        self._layouts = {}
        self.set_size_request(self.rw, self.rh)
        self.add_events(
            Gdk.EventMask.BUTTON_PRESS_MASK
            | Gdk.EventMask.BUTTON_RELEASE_MASK
            | Gdk.EventMask.POINTER_MOTION_MASK
            | Gdk.EventMask.ENTER_NOTIFY_MASK
            | Gdk.EventMask.LEAVE_NOTIFY_MASK)
        self.connect("draw", self.on_draw)
        self.connect("button-press-event", self.on_press)
        self.connect("button-release-event", self.on_release)
        self.connect("motion-notify-event", self.on_motion)
        self.connect("enter-notify-event", self.on_enter)
        self.connect("leave-notify-event", self.on_leave)

    # -- geometry helpers ------------------------------------------------

    @staticmethod
    def _fill_round(cr, x, y, w, h, rgba):
        cr.save()
        cr.set_source_rgba(*rgba)
        r = 2.0
        if w > 2 * r and h > 2 * r:
            cr.move_to(x + r, y)
            cr.arc(x + w - r, y + r, r, -math.pi / 2, 0)
            cr.arc(x + w - r, y + h - r, r, 0, math.pi / 2)
            cr.arc(x + r, y + h - r, r, math.pi / 2, math.pi)
            cr.arc(x + r, y + r, r, math.pi, 3 * math.pi / 2)
            cr.close_path()
        else:
            cr.rectangle(x, y, w, h)
        cr.fill()
        cr.restore()

    def _layout_for(self, ch, box_w, box_h):
        key = (ch, int(box_w), int(box_h))
        hit = self._layouts.get(key)
        if hit:
            return hit
        ctx = self.get_pango_context()
        lay = Pango.Layout.new(ctx)
        lay.set_text(ch, -1)

        def measure(pts):
            attrs = Pango.AttrList()
            attrs.insert(Pango.attr_family_new(self.FONT_FAMILY))
            attrs.insert(Pango.AttrSize.new(int(pts * 1024)))
            lay.set_attributes(attrs)
            ink, _ = lay.get_pixel_extents()
            return ink

        ref = 24.0
        ink = measure(ref)
        scale = min(box_h / max(ink.height, 1),
                    box_w / max(ink.width, 1))
        pts = max(4.0, ref * scale)
        ink = measure(pts)
        hit = (lay, ink)
        self._layouts[key] = hit
        return hit

    def _draw_char(self, cr, ln, i):
        if i >= len(ln["text"]) or i >= len(ln["boxes"]):
            return
        c = ln["text"][i]
        if not c.strip():
            return
        x, y, w, h = ln["boxes"][i]
        lay, ink = self._layout_for(c, w, h)
        ox = x + (w - ink.width) / 2.0 - ink.x
        oy = y + (h - ink.height) / 2.0 - ink.y
        cr.move_to(ox, oy)
        PangoCairo.update_layout(cr, lay)
        PangoCairo.show_layout(cr, lay)

    # -- drawing ----------------------------------------------------------

    def on_draw(self, wdg, cr):
        # Text stays invisible by default and while selecting: only the
        # highlight box(es) appear, sized to the screenshot's own glyphs, so
        # it reads as selecting the real text in the capture. Glyphs are only
        # painted when the overlay is explicitly toggled on with `t`.
        for i, ln in enumerate(self.lines):
            if self.shown() or i == self.hovered:
                self._fill_round(cr, ln["x"], ln["y"], ln["w"], ln["h"],
                                 self.BAND)
        if self.sel:
            gs, ge = self.sel
            for i, ln in enumerate(self.lines):       # one scope, all lines
                base = self.off[i]
                s = max(gs, base)
                e = min(ge, base + len(ln["text"]) - 1)
                if s > e:
                    continue                           # no overlap here
                for li in range(s - base, e - base + 1):
                    if li < len(ln["boxes"]):
                        x, y, w, h = ln["boxes"][li]
                        self._fill_round(cr, x, y, w, h, self.SEL)
        if self.shown():
            cr.set_source_rgb(1, 1, 1)
            for ln in self.lines:
                for i in range(min(len(ln["text"]), len(ln["boxes"]))):
                    self._draw_char(cr, ln, i)
        return False

    # -- cursor ----------------------------------------------------------

    def _apply_cursor(self):
        """I-beam over text (and while selecting); default pointer elsewhere."""
        want = self._over or self._anchor is not None
        if want == self._cursor_on:
            return
        gw = self.get_window()
        if gw is None:                       # not realized yet; retry later
            return
        self._cursor_on = want
        if want:
            if self._cursor_text is None:
                self._cursor_text = Gdk.Cursor.new_for_display(
                    self.get_display(), Gdk.CursorType.XTERM)
            gw.set_cursor(self._cursor_text)
        else:
            gw.set_cursor(None)              # compositor default (arrow)

    # -- input -----------------------------------------------------------

    def _update_hover(self, px, py):
        i = self._line_at(px, py)
        self._over = i >= 0
        if i != self.hovered:
            self.hovered = i
            self.queue_draw()
        self._apply_cursor()

    def on_enter(self, wdg, ev):
        self._update_hover(ev.x, ev.y)
        return False

    def on_leave(self, wdg, ev):
        self._over = False
        if self.hovered != -1:
            self.hovered = -1
            self.queue_draw()
        self._apply_cursor()
        return False

    def _dbl_params(self):
        if self._dbl is None:
            t, d = 0.4, 5                     # gtk defaults, if queryable
            st = Gtk.Settings.get_default()
            if st is not None:
                try:
                    t = st.get_property("gtk-double-click-time") / 1000.0
                    d = st.get_property("gtk-double-click-distance")
                except Exception:
                    pass
            self._dbl = (t, d)
        return self._dbl

    def on_press(self, wdg, ev):
        if ev.button != 1:
            return False
        g = self._hit(ev.x, ev.y)
        if g is None:
            return False

        # When GDK re-types a press it ALSO queues the plain press first, so
        # one physical tap can hand us two events. Believe GDK's count
        # outright in that case -- it already applied its own time/distance
        # window -- and only count for ourselves when the backend never
        # re-types. The counter is deliberately not reset after a double, so
        # a triple can chain onto it, and it keeps counting consecutive
        # presses that land on the same word (a trackpad tap drifts a few px,
        # which must not break the chain).
        tmax, dmax = self._dbl_params()
        now = time.monotonic()
        prev = self._prev_click
        word = self.word_at(g)
        et = getattr(ev, "type", None)
        if et == Gdk.EventType.TRIPLE_BUTTON_PRESS:
            n = 3
        elif et == Gdk.EventType.DOUBLE_BUTTON_PRESS:
            n = 2
        elif (prev is not None and now - prev[0] <= tmax
              and ((prev[3] is not None and word == prev[3])
                   or (abs(ev.x - prev[1]) <= dmax
                       and abs(ev.y - prev[2]) <= dmax))):
            n = self._click_n + 1
        else:
            n = 1
        self._click_n = n
        self._prev_click = (now, ev.x, ev.y, word)

        if n >= 3:
            self.select_line(self.line_of(g))    # triple click -> whole line
            self._anchor = None                  # a shaky tap can't undo it
        elif n == 2:
            self.sel = word                      # double click -> whole word
            self._anchor = None
        else:
            self._anchor = g
            self.sel = None                      # plain click collapses
        self.queue_draw()
        self._apply_cursor()
        return True

    def on_motion(self, wdg, ev):
        self._update_hover(ev.x, ev.y)
        if (self._anchor is None
                or not (ev.state & Gdk.ModifierType.BUTTON1_MASK)):
            return False
        g = self._hit(ev.x, ev.y)
        if g is None:
            return False
        a, b = self._anchor, g
        self.sel = (min(a, b), max(a, b)) if a != b else None
        self.queue_draw()
        return True

    def on_release(self, wdg, ev):
        self._anchor = None
        self._apply_cursor()
        return True

    # -- selection (one scope across every line) --------------------------

    def word_at(self, g):
        """Global (start, end) of the run of like characters around `g`.

        Non-whitespace runs act as words; clicking a space selects the gap.
        A line break is whitespace, so a word never crosses lines.
        """
        if not self.text or not (0 <= g < len(self.text)):
            return None
        space = self.text[g].isspace()
        s = e = g
        while s > 0 and self.text[s - 1].isspace() == space:
            s -= 1
        while e + 1 < len(self.text) and self.text[e + 1].isspace() == space:
            e += 1
        return (s, e)

    def line_of(self, g):
        """Index of the line holding global character index `g`."""
        for k in range(len(self.lines)):
            if g < self.off[k] + len(self.lines[k]["text"]):
                return k
        return len(self.lines) - 1 if self.lines else None

    def select_all(self):
        """Select the whole textbox (every line)."""
        if self.text:
            self.sel = (0, len(self.text) - 1)
            self.queue_draw()

    def select_line(self, k):
        if k is not None and 0 <= k < len(self.lines):
            ln = self.lines[k]
            self.sel = (self.off[k], self.off[k] + len(ln["text"]) - 1)
            self.queue_draw()

    def selected_text(self):
        if not self.sel:
            return ""
        s, e = self.sel
        return self.text[s:e + 1]


    # -- model / hit testing --------------------------------------------

    def set_lines(self, lines):
        """(Re)load OCR lines. Coordinates and boxes arrive in region space."""
        rw, rh = self.rw, self.rh
        parts, self.lines = [], []
        for (x, y, w, h, conf, text, cboxes) in lines:
            if not text or not text.strip():
                continue                       # blank lines aren't selectable
            x = max(0, min(x, rw - 1))
            y = max(0, min(y, rh - 1))
            boxes = [(bx, by, bw, bh) for (bx, by, bw, bh) in cboxes]
            w = max(1, min(w, rw - x))
            h = max(1, min(h, rh - y))
            if boxes:
                w = max(w, max(b[0] + b[2] for b in boxes) - x)
                h = max(h, max(b[1] + b[3] for b in boxes) - y)
            self.lines.append({"x": x, "y": y,
                               "w": min(w, rw - x), "h": min(h, rh - y),
                               "text": text, "boxes": boxes})
            parts.append(text)
        self.text = "\n".join(parts)
        self.off, n = [], 0
        for p in parts:
            self.off.append(n)
            n += len(p) + 1                    # +1 for the following newline
        self.sel = None
        self._anchor = None
        self.hovered = -1
        self.queue_draw()

    def _line_at(self, px, py):
        """Index of the line whose box contains the point, else -1."""
        for i, ln in enumerate(self.lines):
            if (ln["x"] <= px <= ln["x"] + ln["w"]
                    and ln["y"] <= py <= ln["y"] + ln["h"]):
                return i
        return -1

    def _nearest_line(self, px, py):
        """Line nearest by vertical centre (clicks land in the line gaps)."""
        best, bestd = -1, None
        for i, ln in enumerate(self.lines):
            d = abs(py - (ln["y"] + ln["h"] / 2.0))
            if bestd is None or d < bestd:
                best, bestd = i, d
        return best

    def _hit(self, px, py):
        """Global character index under the point (None when there is no text)."""
        i = self._line_at(px, py)
        if i < 0:
            i = self._nearest_line(px, py)
        if i < 0:
            return None
        ln = self.lines[i]
        local = char_index(ln["boxes"], px) if ln["boxes"] else 0
        local = min(local, max(0, len(ln["text"]) - 1))
        return self.off[i] + local


def capture_region():
    """Pick a region with slurp and capture it with grim.

    Returns (region, path) to pin, or None when the selection was cancelled
    or the capture failed. grim writes to stdout, so no file exists until
    the capture is complete -- being killed mid-capture leaks nothing.
    """
    try:
        sel = subprocess.run(["slurp", "-f", "%x %y %w %h"],
                             capture_output=True, text=True)
    except FileNotFoundError:
        notify("critical", "Santino", "slurp is not installed.")
        return None
    except Exception:
        return None
    if sel.returncode != 0 or not sel.stdout.strip():
        return None                      # selection cancelled
    try:
        x, y, w, h = sel.stdout.split()
    except ValueError:
        notify("critical", "Santino", "slurp returned an unexpected selection.")
        return None

    try:
        # "-" is grim's stdout marker. Without it this build exits 0 and
        # writes nothing at all, which surfaces as "Failed to capture".
        cap = subprocess.run(["grim", "-g", "%s,%s %sx%s" % (x, y, w, h), "-"],
                             capture_output=True, timeout=60)
        if cap.returncode != 0 or not cap.stdout:
            raise RuntimeError("grim produced nothing")
    except FileNotFoundError:
        notify("critical", "Santino", "grim is not installed.")
        return None
    except Exception:
        notify("critical", "Santino", "Failed to capture the region.")
        return None

    fd, path = tempfile.mkstemp(prefix="santino.", suffix=".png")
    try:
        # Through a file object, not a bare os.write(): os.write is permitted
        # to do a short write, and grim's stdout for a large region is several
        # MB, so a bare write could silently truncate the PNG.
        with os.fdopen(fd, "wb") as fh:
            fh.write(cap.stdout)
    except Exception:
        try:
            os.close(fd)
        except OSError:
            pass
        raise
    _TMP.append(path)
    return "%s,%s,%s,%s" % (x, y, w, h), path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-l", "--lang", default="eng")
    ap.add_argument("--image", default=None,
                    help="capture to pin (default: slurp a region, grim it)")
    ap.add_argument("--region", default=None, help="X,Y,W,H of --image")
    args = ap.parse_args()

    if args.image is None:
        picked = capture_region()
        if picked is None:
            return 0                    # cancelled: exit quietly
        args.region, args.image = picked
    elif args.region is None:
        ap.error("--region is required with --image")
    rx, ry, rw, rh = map(int, args.region.split(","))

    # Remove our temp files on every exit path. atexit covers a normal quit;
    # GLib's unix signal source covers kill / session shutdown, where a plain
    # Python SIGTERM handler would be deferred behind the GTK main loop.
    atexit.register(_cleanup)
    for _sig in (signal.SIGINT, signal.SIGTERM):
        def _sig_cb(signum=_sig):
            _cleanup()
            os._exit(128 + signum)
        if GLibUnix is not None:
            GLibUnix.signal_add(GLib.PRIORITY_DEFAULT, _sig, _sig_cb)
        else:
            signal.signal(_sig, lambda _s, _f, cb=_sig_cb: cb())

    GLib.set_prgname("santino")

    win = Gtk.Window()
    win.set_title("Santino")
    win.set_decorated(False)
    # NB: gtk_window_set_resizable(FALSE) looks like the right call for a pin,
    # but on a non-decorated window it makes GTK abandon client-side
    # decorations and ask the compositor for server-side ones -- sway then
    # draws its own 31px titlebar, overriding default_border pixel 4. Pin the
    # size with a size request instead.
    win.set_size_request(rw, rh)
    # Until the capture is revealed the pin shows the desktop through it
    # rather than a grey box: an ARGB visual with nothing painted on it reads
    # as fully transparent to the compositor.
    win.set_app_paintable(True)
    _rgba = win.get_screen().get_rgba_visual()
    if _rgba is not None:
        win.set_visual(_rgba)
    _css = Gtk.CssProvider()
    _css.load_from_data(b"window { background: transparent; }")
    win.get_style_context().add_provider(
        _css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)
    # Exactly the region; win.set_size_request() above stops the user shrinking
    # the pin below it.
    win.set_default_size(rw, rh)

    pixbuf = GdkPixbuf.Pixbuf.new_from_file(args.image)
    # The capture is withheld until the pin is actually in place (see reveal()
    # further down). sway paints the frame that maps the window, and that
    # frame lands wherever sway chose -- screen centre -- so showing the image
    # straight away is what made the pin flash in the middle of the screen.
    base = Gtk.Image()

    # The window can end up a hair larger than the selection: sway and GTK both
    # enforce a minimum size, so a very small region leaves slack that would
    # otherwise show up as transparent banding. Scale the capture to the size
    # the window really got, and save exactly that for OCR to read.
    ocr_src = os.path.join(os.environ.get("TMPDIR", "/tmp"),
                           "santino-disp-%d.png" % os.getpid())
    _TMP.append(ocr_src)
    disp = [max(rw, 1), max(rh, 1)]      # size the screenshot really is

    def _fit(w, h):
        try:
            img = pixbuf.scale_simple(max(w, 1), max(h, 1),
                                      GdkPixbuf.InterpType.BILINEAR)
        except GLib.Error:
            img = pixbuf
        disp[0], disp[1] = img.get_width(), img.get_height()
        try:                             # OCR must see the pixels on screen
            img.savev(ocr_src, "png", [], [])
        except GLib.Error:
            pass
        return img

    # Pre-save the OCR source before the worker below starts reading it; the
    # authoritative copy is written by reveal() once the size is known.
    _fit(rw, rh)

    fixed = Gtk.Fixed()
    fixed.set_size_request(rw, rh)
    fixed.set_hexpand(True)
    fixed.set_vexpand(True)

    ov = Gtk.Overlay()
    ov.add(base)
    ov.add_overlay(fixed)
    win.add(ov)

    overlay_shown = False                  # 't' flips this

    def shown_provider():
        return overlay_shown

    # One widget over the whole region => one selection scope for every line
    # (a single virtual textbox), line gaps included.
    area = OverlayArea(rw, rh, shown_provider)
    fixed.put(area, 0, 0)

    def apply_lines(lines):
        # No "is the window realized yet?" guard here. set_lines() only fills
        # a Python list and calls queue_draw(), both of which are safe on an
        # unrealized widget -- and OCR takes ~1s while realization takes
        # ~10ms, so there is no race to lose. A guard would have silently
        # discarded the OCR result with no message and (now that the o
        # keybind is gone) no way to get it back. Dropping text quietly is
        # worse than any theoretical race this could have protected against.
        area.set_lines(lines)

    def all_text():
        return area.text

    def copy_all():
        text = all_text()
        if not text:
            return True
        for sel in (Gdk.SELECTION_CLIPBOARD, Gdk.SELECTION_PRIMARY):
            Gtk.Clipboard.get(sel).set_text(text, -1)
        return True

    def copy_selection_or_all():
        t = area.selected_text()
        if t.strip():
            for sel in (Gdk.SELECTION_CLIPBOARD, Gdk.SELECTION_PRIMARY):
                Gtk.Clipboard.get(sel).set_text(t, -1)
            return True
        return copy_all()

    def on_key(w, ev):
        nonlocal overlay_shown
        kmod = ev.state & Gdk.ModifierType.CONTROL_MASK
        kv = ev.keyval
        if kv == Gdk.KEY_Escape:
            Gtk.main_quit()
            return True
        if kmod and kv in (Gdk.KEY_c, Gdk.KEY_C, Gdk.KEY_Insert):
            return copy_selection_or_all()
        if kmod and kv in (Gdk.KEY_a, Gdk.KEY_A):
            area.select_all()          # one textbox: select everything
            return True
        if kv in (Gdk.KEY_t, Gdk.KEY_T):
            overlay_shown = not overlay_shown
            area.queue_draw()
            return True
        return False

    win.connect("key-press-event", on_key)
    win.connect("destroy", Gtk.main_quit)

    # Show the capture only once the pin is really in place. Until then the
    # window paints nothing at all, so the frame sway chooses for the map
    # (screen centre) is empty -- the screenshot itself can never appear in
    # the wrong place. This is what actually removes the flash; the queued
    # placement below only makes the empty phase as short as possible.
    revealed = []

    def reveal(*_a):
        if revealed:
            return False
        revealed.append(True)
        # Scale to the size the window actually got, not the size we asked
        # for -- otherwise a small selection bands when sway/GTK floor it.
        base.set_from_pixbuf(
            _fit(base.get_allocated_width(), base.get_allocated_height()))
        area.queue_draw()
        return False

    GLib.timeout_add(1500, reveal)   # never leave the pin blank if placement stalls

    # Arm the window-event subscription BEFORE the window maps (and wait for
    # sway's acknowledgement) so we see the pin the instant it exists.
    ready = threading.Event()
    stop_pre = threading.Event()
    pid = os.getpid()
    t = threading.Thread(
        target=position_worker,
        args=(pid, rx, ry, rw, rh, ready, stop_pre,
              lambda: GLib.idle_add(reveal)), daemon=True)
    t.start()
    ready.wait(2.0)                 # do not map until we can see our events

    # Then keep the placement command queued in sway so one is already
    # pending when the map lands -- reacting to the map event is one round
    # trip too late to beat the first frame.
    b = sway_border()
    threading.Thread(
        target=presnap_worker,
        args=(pid, rx, ry, rw, rh, b[0] // 2 if b else DEFAULT_BORDER, stop_pre),
        daemon=True).start()

    win.show_all()

    def ocr_worker():
        lines = ocr_lines(ocr_src, args.lang, disp[1], disp[0])
        GLib.idle_add(lambda: apply_lines(lines))
    threading.Thread(target=ocr_worker, daemon=True).start()

    Gtk.main()
    return 0


if __name__ == "__main__":
    sys.exit(main())