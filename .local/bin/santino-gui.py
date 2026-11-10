#!/usr/bin/env python3
"""Pinned screenshot with selectable OCR text overlaid where the text is.

Usage:
  santino-gui.py --image FILE --region X,Y,W,H [--lang LANG] [--text TEXT]

The window is placed by sway so that its image content covers exactly the
pinned region. Each OCR line becomes a selectable GtkLabel whose widget covers
the line's exact box in the screenshot; the glyphs are drawn at ~0% opacity so
the pin looks exactly like the capture. Hovering a line draws a soft band
around it and reveals its OCR words; dragging selects them (white on blue).
Since the user reads the screenshot's own text (which can never misalign), the
overlay never masks or distorts the pinned image.

Keys:
  Esc            close
  Ctrl+C/Insert  copy the selection; copies all text if nothing is selected
  Ctrl+A         select all in the focused line
  t              toggle persistent overlay bands/words on/off
  o              re-run OCR on the pinned image
"""

import argparse
import atexit
import json
import os
import subprocess
import sys
import threading
import time

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk, Pango

MIN_CONF = 40

# Pango's color-alpha range is 1..65536 (0 is invalid and gets dropped).
# ALPHA_HIDDEN keeps the overlay glyphs effectively invisible so the pinned
# image stays exactly as captured; the text is still there to select/copy.
ALPHA_HIDDEN = 1
ALPHA_SHOWN = 65535

CSS = b"""
label#ocr {
  font-family: monospace;
}
label#ocr.hilite {
  background-color: rgba(170, 210, 255, 0.22);
  border-radius: 2px;
}
label#ocr:selected {
  background-color: rgba(70, 130, 255, 0.55);
  border-radius: 2px;
}
"""


def swaymsg(*args):
    try:
        return subprocess.run(["swaymsg", *args],
                              capture_output=True, text=True, timeout=5)
    except Exception:
        return None


def find_window(pid):
    r = swaymsg("-t", "get_tree")
    if not r:
        return None
    try:
        tree = json.loads(r.stdout)
    except Exception:
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
    return {
        "content": (r["x"] + wr["x"], r["y"] + wr["y"],
                    wr["width"], wr["height"]),
        "borders": {
            "left": wr["x"],
            "top": wr["y"],
            "right": r["width"] - (wr["x"] + wr["width"]),
            "bottom": r["height"] - (wr["y"] + wr["height"]),
        },
    }


def focus_without_warp(pid):
    """Focus the window without sway warping the pointer to it.

    sway only warps the pointer when the focused window actually gains
    focus *and* mouse_warping is not "none", so we temporararily set it to
    none around the focus command and restore the configured value.
    """
    cur = "output"                       # sway default
    try:
        r = swaymsg("-t", "get_config")
        if r:
            cfg = json.loads(r.stdout).get("config", "")
            vals = [ln.split()[-1] for ln in cfg.splitlines()
                    if ln.strip().startswith("mouse_warping")]
            if vals:
                cur = vals[-1]
    except Exception:
        pass
    swaymsg("mouse_warping", "none")
    try:
        r = swaymsg(f"[pid={pid}]", "focus")
    finally:
        swaymsg("mouse_warping", cur)
    if os.environ.get("SANTINO_DEBUG"):
        try:
            with open("/tmp/opencode/santino-focus.txt", "w") as f:
                f.write("focus result: %s\n" % (r.stdout if r else "no output"))
        except Exception:
            pass


def snap_to_region(pid, rx, ry, rw, rh, node=None):
    """Float the window and place it so its content === (rx,ry,rw,rh)."""
    if node is None:
        for _ in range(300):
            node = find_window(pid)
            if node:
                break
            time.sleep(0.01)
    if not node:
        return False

    swaymsg(f"[pid={pid}]", "floating", "enable")
    # IPC is serialized: the next get_tree already reflects the float state.
    node = find_window(pid) or node
    b = measure(node)["borders"]
    ox, oy = rx - b["left"], ry - b["top"]
    ow, oh = rw + b["left"] + b["right"], rh + b["top"] + b["bottom"]
    if ow < 1 or oh < 1:
        return False

    swaymsg(f"[pid={pid}]", "resize", "set", str(ow), str(oh))
    swaymsg(f"[pid={pid}]", "move", "absolute", "position", str(ox), str(oy))
    time.sleep(0.02)          # let sway settle, then verify/compensate once
    node = find_window(pid)
    if node:
        cx, cy = measure(node)["content"][0], measure(node)["content"][1]
        if cx != rx or cy != ry:
            swaymsg(f"[pid={pid}]", "move", "absolute", "position",
                    str(ox - (cx - rx)), str(oy - (cy - ry)))
    # Give the window keyboard focus (so Esc/Ctrl+C work right away) but
    # without warping the pointer to it.
    focus_without_warp(pid)
    return True


def position_worker(pid, rx, ry, rw, rh):
    """Detect the window the moment sway maps it, then snap it in place.

    Runs before/while the window is shown so the first painted frame is
    already at the right position (no mid-screen flash).
    """
    if os.environ.get("SANTINO_NO_SNAP"):
        return
    sub = None
    try:
        sub = subprocess.Popen(
            ["swaymsg", "-m", "-t", "subscribe", '["window"]'],
            stdout=subprocess.PIPE, universal_newlines=True, bufsize=1,
            stdin=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        sub = None
    deadline = time.time() + 6.0
    node = None
    if sub is not None:
        try:
            for line in sub.stdout:
                if time.time() > deadline:
                    break
                try:
                    ev = json.loads(line)
                except Exception:
                    continue
                if (ev.get("container") or {}).get("pid") == pid:
                    node = ev["container"]
                    break
        finally:
            try:
                sub.kill()
            except Exception:
                pass
    while node is None and time.time() < deadline:
        node = find_window(pid)
        if node is None:
            time.sleep(0.02)
    if node:
        snap_to_region(pid, rx, ry, rw, rh, node)


def parse_tsv(tsv_text):
    """Tesseract TSV -> list of (x, y, w, h, conf, text) merged per line."""
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

    out = []
    for grp in groups:
        x = min(w[3] for w in grp)
        y = min(w[4] for w in grp)
        right = max(w[3] + w[5] for w in grp)
        bottom = max(w[4] + w[6] for w in grp)
        text = " ".join(w[8] for w in grp)
        conf = sum(w[7] for w in grp) / len(grp)
        out.append((x, y, right - x, bottom - y, conf, text))
    return out


def ocr_boxes(image, lang):
    try:
        out = subprocess.run(
            ["santino-ocr.sh", "--tsv", "-l", lang, image],
            capture_output=True, text=True, timeout=30)
        return parse_tsv(out.stdout)
    except Exception:
        return []


_ALPHA_CACHE = {}


def set_line_alpha(lbl, alpha):
    """Set the text opacity of an overlay label (Pango alpha 1..65536)."""
    if _ALPHA_CACHE.get(lbl) == alpha:
        return
    _ALPHA_CACHE[lbl] = alpha
    attrs = lbl.get_attributes()
    if attrs is None:
        attrs = Pango.AttrList()
    # change() replaces the existing full-range foreground-alpha attribute.
    attrs.change(Pango.attr_foreground_alpha_new(alpha))
    lbl.set_attributes(attrs)


def _text_attrs(pts):
    """Size + family attributes. Family is an attribute (not just CSS) so the
    measurement in fit_to_box() and the final render use identical metrics."""
    a = Pango.AttrList()
    a.insert(Pango.attr_family_new("monospace"))
    a.insert(Pango.AttrSize.new(int(pts * 1024)))   # Pango units
    return a


def fit_to_box(lbl, w, h, min_pts=5.0, max_pts=128.0):
    """Font size so the text spans the OCR box width.

    The overlay glyphs are only a proxy for hit-testing (the user actually
    reads the screenshot's own text, which never misaligns), so the size is
    chosen to map pointer position to characters proportionally: largest size
    whose ink width still fits the box, shrunk only if it would tower over it.
    """
    def extents(pts):
        lbl.set_attributes(_text_attrs(pts))
        return lbl.get_layout().get_pixel_extents()

    lo, hi = min_pts, max_pts
    for _ in range(14):                          # largest size with width <= w
        mid = (lo + hi) / 2.0
        ink, _ = extents(mid)
        if ink.width <= w:
            lo = mid
        else:
            hi = mid
    pts = lo
    for _ in range(8):                           # don't tower over the box
        ink, _ = extents(pts)
        if ink.height <= h * 1.4 or pts <= min_pts:
            break
        pts = max(min_pts, pts * (h * 1.4 / ink.height) * 0.97)
    return pts


def build_line_views(fixed, boxes, rw, rh):
    views = []
    for (x, y, w, h, conf, text) in boxes:
        x = max(0, min(x, rw - 1))
        y = max(0, min(y, rh - 1))
        w = min(w, rw - x)
        h = min(h, rh - y)
        lbl = Gtk.Label(label=text)
        lbl.set_name("ocr")
        lbl.set_selectable(True)
        lbl.set_halign(Gtk.Align.START)
        lbl.set_valign(Gtk.Align.START)
        lbl.set_size_request(w, h)     # widget == OCR box: hit area + band
        pts = fit_to_box(lbl, w, h)
        attrs = _text_attrs(pts)
        # default start 0 / end G_MAXUINT applies attrs to the whole text
        attrs.insert(Pango.attr_foreground_new(65535, 65535, 65535))
        attrs.insert(Pango.attr_foreground_alpha_new(ALPHA_HIDDEN))
        lbl.set_attributes(attrs)
        fixed.put(lbl, x, y)
        lbl.show()               # added after win.show_all(): must show manually
        views.append(lbl)
    return views


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--image", required=True)
    ap.add_argument("--region", required=True, help="X,Y,W,H")
    ap.add_argument("--lang", default="eng")
    ap.add_argument("--text", default=None,
                    help="manual text (skips OCR; mainly for testing)")
    args = ap.parse_args()
    rx, ry, rw, rh = map(int, args.region.split(","))

    GLib.set_prgname("santino")

    win = Gtk.Window()
    win.set_title("Santino")
    win.set_decorated(False)
    win.set_default_size(max(rw, 200), max(rh, 150))

    pixbuf = GdkPixbuf.Pixbuf.new_from_file(args.image)
    try:
        full = pixbuf.scale_simple(max(rw, 1), max(rh, 1),
                                   GdkPixbuf.InterpType.BILINEAR)
    except GLib.Error:
        full = pixbuf
    base = Gtk.Image.new_from_pixbuf(full)

    # OCR must see the exact pixels the window displays, so save the scaled
    # pixbuf (in real use the capture is already region-sized, 1:1 with it).
    ocr_src = os.path.join(os.environ.get("TMPDIR", "/tmp"),
                           "santino-disp-%d.png" % os.getpid())
    full.savev(ocr_src, "png", [], [])
    atexit.register(lambda: os.path.exists(ocr_src) and os.unlink(ocr_src))

    css = Gtk.CssProvider()
    css.load_from_data(CSS)
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    fixed = Gtk.Fixed()
    fixed.set_size_request(rw, rh)
    fixed.set_hexpand(True)
    fixed.set_vexpand(True)

    ov = Gtk.Overlay()
    ov.add(base)
    ov.add_overlay(fixed)
    win.add(ov)

    line_views = []
    hovered = set()
    overlay_shown = os.environ.get("SANTINO_OVERLAY") == "1"

    def has_selection(lbl):
        try:
            return bool(lbl.get_selection_bounds()[0])
        except Exception:
            return False

    def state_alpha(lbl):
        shown = overlay_shown or lbl in hovered or has_selection(lbl)
        set_line_alpha(lbl, ALPHA_SHOWN if shown else ALPHA_HIDDEN)

    def set_band(lbl, on):
        ctx = lbl.get_style_context()
        if on and not ctx.has_class("hilite"):
            ctx.add_class("hilite")
        elif not on and ctx.has_class("hilite"):
            ctx.remove_class("hilite")

    def on_enter(lbl, ev):
        hovered.add(lbl)
        set_band(lbl, True)                        # translucent band around the line
        set_line_alpha(lbl, ALPHA_SHOWN)           # reveal the OCR words
        return False

    def on_leave(lbl, ev):
        hovered.discard(lbl)
        set_band(lbl, overlay_shown)
        state_alpha(lbl)          # stays revealed if it still has a selection
        return False

    def reveal_tick():
        for lbl in list(line_views):
            state_alpha(lbl)
        return GLib.SOURCE_CONTINUE

    def apply_boxes(boxes):
        if not win.get_realized():
            return
        nonlocal line_views
        for w in line_views:
            fixed.remove(w)
        line_views = build_line_views(fixed, boxes, rw, rh)
        _ALPHA_CACHE.clear()
        for lbl in line_views:
            lbl.connect("enter-notify-event", on_enter)
            lbl.connect("leave-notify-event", on_leave)
            set_band(lbl, overlay_shown)
            state_alpha(lbl)
        if os.environ.get("SANTINO_DEBUG"):
            def dump_debug():
                with open("/tmp/opencode/santino-debug.txt", "w") as f:
                    f.write("boxes=%d lines=%d overlay_shown=%s\n"
                            % (len(boxes), len(line_views), overlay_shown))
                    f.write(all_text())
                    f.write("\n-- per line --\n")
                    for lbl in line_views:
                        a = lbl.get_allocation()
                        ink, logi = lbl.get_layout().get_pixel_extents()
                        f.write("%r  alloc=(%d,%d %dx%d)"
                                "  ink=(%d,%d %dx%d) logical=(%d,%d %dx%d)\n"
                                % (lbl.get_text(), a.x, a.y, a.width, a.height,
                                   ink.x, ink.y, ink.width, ink.height,
                                   logi.x, logi.y, logi.width, logi.height))
                return GLib.SOURCE_REMOVE
            GLib.timeout_add(900, dump_debug)   # run after layout allocation
        # NOTE: do NOT grab_focus() on a label here — focusing a selectable
        # GtkLabel auto-selects its whole text (ugly blue box); the window
        # key handler works regardless of focus.

    def all_text():
        parts = []
        for lbl in line_views:
            t = lbl.get_text()
            if t.strip():
                parts.append(t)
        return "\n".join(parts)

    def copy_all():
        text = all_text()
        if not text:
            return True
        for sel in (Gdk.SELECTION_CLIPBOARD, Gdk.SELECTION_PRIMARY):
            Gtk.Clipboard.get(sel).set_text(text, -1)
        return True

    def on_key(w, ev):
        nonlocal overlay_shown
        kmod = ev.state & Gdk.ModifierType.CONTROL_MASK
        kv = ev.keyval
        if kv == Gdk.KEY_Escape:
            Gtk.main_quit()
            return True
        fw = w.get_focus()
        if kmod and kv in (Gdk.KEY_c, Gdk.KEY_C, Gdk.KEY_Insert):
            if (isinstance(fw, Gtk.Label) and fw in line_views
                    and fw.get_selection_bounds()):
                return False       # label's own Ctrl+C copies the selection
            return copy_all()
        if kmod and kv in (Gdk.KEY_a, Gdk.KEY_A):
            if isinstance(fw, Gtk.Label) and fw in line_views:
                fw.select_region(0, -1)
            return True
        if kv in (Gdk.KEY_t, Gdk.KEY_T):
            overlay_shown = not overlay_shown
            for lbl in line_views:
                set_band(lbl, overlay_shown)
                state_alpha(lbl)
            return True
        if kv in (Gdk.KEY_o, Gdk.KEY_O):
            def worker():
                boxes = ocr_boxes(ocr_src, args.lang)
                GLib.idle_add(lambda: apply_boxes(boxes))
            threading.Thread(target=worker, daemon=True).start()
            return True
        return False

    win.connect("key-press-event", on_key)
    win.connect("destroy", Gtk.main_quit)

    win.show_all()

    def ocr_worker():
        if args.text is not None:
            boxes = [(0, 0, max(rw, 10), min(rh, 140), 100, args.text)]
            GLib.idle_add(lambda: apply_boxes(boxes))
        else:
            boxes = ocr_boxes(ocr_src, args.lang)
            GLib.idle_add(lambda: apply_boxes(boxes))
    threading.Thread(target=ocr_worker, daemon=True).start()

    t = threading.Thread(
        target=position_worker, args=(os.getpid(), rx, ry, rw, rh), daemon=True)
    t.start()

    if os.environ.get("SANTINO_COPY_TEST"):   # testing hook: copy when text is ready
        def selftest():
            if not all_text():
                return GLib.SOURCE_CONTINUE    # wait for OCR labels
            copy_all()
            return GLib.SOURCE_REMOVE
        GLib.timeout_add(250, selftest)

    GLib.timeout_add(80, reveal_tick)

    if os.environ.get("SANTINO_SELECT"):       # testing hook: select first line
        def do_select():
            if not line_views:
                return GLib.SOURCE_CONTINUE
            line_views[0].select_region(0, -1)   # reveal_tick shows the selection
            return GLib.SOURCE_REMOVE
        GLib.timeout_add(300, do_select)

    Gtk.main()
    return 0


if __name__ == "__main__":
    sys.exit(main())