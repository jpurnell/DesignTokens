#!/usr/bin/env python3
"""Loads a generated GTK stylesheet into a real GTK 4 window and writes a PNG of it, printing every CSS parse error.

Usage: gtk-render.py <stylesheet.css> <out.png> [gtk4|gtk3]
Needs a display (run it from a graphical session, or with WAYLAND_DISPLAY and XDG_RUNTIME_DIR set).
"""
import sys

import gi

css_path, out_path = sys.argv[1], sys.argv[2]
version = sys.argv[3] if len(sys.argv) > 3 else "gtk4"
errors = []

if version == "gtk3":
    gi.require_version("Gtk", "3.0")
    gi.require_version("Gdk", "3.0")
    from gi.repository import Gdk, GLib, Gtk

    provider = Gtk.CssProvider()
    provider.connect("parsing-error", lambda p, section, error: errors.append(f"line {section.get_start_line() + 1}: {error.message}"))
    provider.load_from_path(css_path)
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER)
else:
    gi.require_version("Gtk", "4.0")
    from gi.repository import Gdk, GLib, Gtk

    provider = Gtk.CssProvider()
    provider.connect("parsing-error", lambda p, section, error: errors.append(f"line {section.get_start_location().lines + 1}: {error.message}"))
    provider.load_from_path(css_path)
    Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER)


def build():
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
    for setter in ("set_margin_top", "set_margin_bottom", "set_margin_start", "set_margin_end"):
        getattr(box, setter)(16)
    box.append(Gtk.Label(label="Save changes before closing?", xalign=0)) if version != "gtk3" else box.add(Gtk.Label(label="Save changes before closing?", xalign=0))
    entry = Gtk.Entry(text="Untitled document")
    row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
    buttons = [Gtk.Button(label="Don't Save"), Gtk.Button(label="Cancel"), Gtk.Button(label="Save")]
    buttons[2].add_css_class("suggested-action") if version != "gtk3" else buttons[2].get_style_context().add_class("suggested-action")
    for button in buttons:
        row.append(button) if version != "gtk3" else row.add(button)
    for child in (entry, row):
        box.append(child) if version != "gtk3" else box.add(child)
    return box, buttons[2]


loop = GLib.MainLoop()
if version == "gtk3":
    window = Gtk.Window(title="gtk3")
    box, default = build()
    window.add(box)
    window.set_default_size(360, 140)
    window.show_all()

    def shoot():
        from gi.repository import Gdk as G
        allocation = window.get_allocation()
        pixbuf = G.pixbuf_get_from_window(window.get_window(), 0, 0, allocation.width, allocation.height)
        pixbuf.savev(out_path, "png", [], [])
        loop.quit()
        return False
else:
    window = Gtk.Window(title="gtk4")
    box, default = build()
    window.set_child(box)
    window.set_default_size(360, 140)
    window.set_default_widget(default)
    window.present()

    def shoot():
        paintable = Gtk.WidgetPaintable.new(window)
        width, height = window.get_width(), window.get_height()
        snapshot = Gtk.Snapshot()
        paintable.snapshot(snapshot, width, height)
        node = snapshot.to_node()
        texture = window.get_native().get_renderer().render_texture(node, None)
        texture.save_to_png(out_path)
        loop.quit()
        return False

GLib.timeout_add(1200, shoot)
loop.run()
print("css errors:", len(errors))
for message in errors:
    print("  " + message)
