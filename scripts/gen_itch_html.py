#!/usr/bin/env python3
"""
gen_itch_html.py — Patch a PICO-8 exported index.html for nicer itch.io embeds.

What it does by default (idempotent):
- Remove body background-color so itch can control page BG (guide #3)
- Make frame fill allotted space: max-width 100vw, max-height 100vh (guide #4)
- Tighten and balance menu button spacing; remove extra left gap (guide #5)
- Make splash/start image pixel-perfect (guide #7)

Optional (flags):
- --js <name.js>        -> set the cartridge script src (guide #8)
- --bg-url <data/url>   -> set p8_start_button background image URL (guide #9)
- --autoplay-smooth     -> enable autoplay and hide splash for ~1s to avoid flicker (guide 10–12)
 - --hide-ui             -> hide in-page PICO-8 overlay UI buttons (mute/pause) for a cleaner look

Usage examples:
  python gen_itch_html.py                               # apply defaults to build/index.html
  python gen_itch_html.py --js space_shooter.js         # ensure JS filename is set
  python gen_itch_html.py --bg-url "data:image/png;base64,..."   # replace splash bg
  python gen_itch_html.py --autoplay-smooth             # enable autoplay with smooth splash

Notes:
- Edits are safe to run multiple times; only diffs are applied.
- Pass --html to target a different file.
"""
from __future__ import annotations
import argparse
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
DEFAULT_HTML = HERE / "build" / "index.html"


def sub_once(pattern: str, repl: str, text: str, flags: int = 0) -> tuple[str, bool]:
    new_text, n = re.subn(pattern, repl, text, count=1, flags=flags)
    return new_text, bool(n)


def ensure_body_bg_removed(html: str) -> tuple[str, bool]:
    # Remove background-color:...; from <body style="...">
    pattern = r"(<body\s+style=\"[^\"]*)\s*background-color:\s*#[0-9a-fA-F]{3,8};?\s*(.*?\")"
    repl = r"\1\2"
    return sub_once(pattern, repl, html, flags=re.DOTALL)


def set_frame_fullscreen_caps(html: str) -> tuple[str, bool]:
    # In #p8_frame style, set max-width:100vw and max-height:100vh
    changed = False
    def repl_max_width(m):
        nonlocal changed
        changed = True
        # group(2) is the current vw value
        return m.group(0).replace(m.group(2), "100vw")
    def repl_max_height(m):
        nonlocal changed
        changed = True
        # group(2) is the current vh value
        return m.group(0).replace(m.group(2), "100vh")

    # max-width
    html2 = re.sub(r"(max-width:)\s*([0-9.]+vw)", repl_max_width, html)
    # max-height
    html3 = re.sub(r"(max-height:)\s*([0-9.]+vh)", repl_max_height, html2)
    return html3, changed


def tighten_menu_button_spacing(html: str) -> tuple[str, bool]:
    changed = False
    # CSS: @media block margin-left:12px; margin-bottom:8px; -> 6px each
    css_pat = (r"(@media[^\{]+\{[^\}]*?\.p8_menu_button\{[^\}]*?width:\s*24px;\s*)"
               r"margin-left:\s*([0-9]+)px;\s*margin-bottom:\s*([0-9]+)px;?")
    def css_repl(m):
        nonlocal changed
        changed = True
        prefix = m.group(1)
        return f"{prefix}margin-left:6px; margin-bottom:6px;"
    html2 = re.sub(css_pat, css_repl, html, flags=re.DOTALL)

    # Inline style on #p8_menu_buttons: margin-left:10px; -> 0
    html3, ch2 = sub_once(r"(id=\"p8_menu_buttons\"[^>]*?style=\"[^\"]*?)margin-left:\s*[0-9]+px;?", r"\1", html2)
    return html3, (changed or ch2)


def add_clean_frame_css(html: str) -> tuple[str, bool]:
    """Overlay CSS to remove gray gutters, borders, and any frame backgrounds for a clean itch embed.
    Idempotent: guarded by a unique comment marker.
    """
    if "/* itch: clean frame */" in html:
        return html, False
    rule = (
        "\n/* itch: clean frame */\n"
        "html,body{margin:0 !important;}\n"
        "#p8_frame,#p8_container,#p8_playarea{\n"
        "  background: transparent !important;\n"
        "  box-shadow: none !important;\n"
        "  border: 0 !important;\n"
        "  padding: 0 !important;\n"
        "}\n"
        "#p8_frame::before,#p8_frame::after{display:none !important;}\n"
        "#p8_menu_buttons,.p8_menu_button,.p8_menu_button_container{background:transparent !important;}\n"
        "#p8_frame{max-width:100vw;max-height:100vh;margin:0 auto;}\n"
    )
    new_html, n = sub_once(r"(</STYLE>)", rule + r"\1", html, flags=re.IGNORECASE)
    if not n:
        new_html, n = sub_once(r"(</head>)", f"<style>{rule}</style>\n\1", html, flags=re.IGNORECASE)
    return new_html, True if n else False


def ensure_canvas_pixelated(html: str) -> tuple[str, bool]:
    if "/* itch: pixel-canvas */" in html:
        return html, False
    rule = (
        "\n/* itch: pixel-canvas */\n"
        "#p8_canvas{\n"
        "  image-rendering: pixelated;\n"
        "  image-rendering: crisp-edges;\n"
        "  -ms-interpolation-mode: nearest-neighbor;\n"
        "}\n"
    )
    new_html, n = sub_once(r"(</STYLE>)", rule + r"\1", html, flags=re.IGNORECASE)
    if not n:
        new_html, n = sub_once(r"(</head>)", f"<style>{rule}</style>\n\1", html, flags=re.IGNORECASE)
    return new_html, True if n else False


def hide_overlay_ui(html: str) -> tuple[str, bool]:
    if "/* itch: hide overlay ui */" in html:
        return html, False
    rule = (
        "\n/* itch: hide overlay ui */\n"
        "#p8_menu_buttons, .p8_menu_button, #p8_buttons{ display:none !important; }\n"
    )
    new_html, n = sub_once(r"(</STYLE>)", rule + r"\1", html, flags=re.IGNORECASE)
    if not n:
        new_html, n = sub_once(r"(</head>)", f"<style>{rule}</style>\n\1", html, flags=re.IGNORECASE)
    return new_html, True if n else False


def pixel_perfect_splash(html: str) -> tuple[str, bool]:
    # Add CSS rule to make start button img pixelated if not present
    if "/* itch: pixel-perfect splash */" in html:
        return html, False
    rule = (
        "\n/* itch: pixel-perfect splash */\n"
        ".p8_start_button,\n"
        ".p8_start_button img{\n"
        "  image-rendering: pixelated;\n"
        "  image-rendering: crisp-edges;\n"
        "  -webkit-image-rendering: pixelated;\n"
        "}\n"
        ".p8_start_button{\n"
        "  background-repeat: no-repeat;\n"
        "  background-position: center center;\n"
        "  -webkit-background-size: contain;\n"
        "  -moz-background-size: contain;\n"
        "  -o-background-size: contain;\n"
        "  background-size: contain;\n"
        "}\n"
    )
    new_html, n = sub_once(r"(</STYLE>)", rule + r"\1", html, flags=re.IGNORECASE)
    if not n:
        # Fall back to append near end of <head>
        new_html, n = sub_once(r"(</head>)", f"<style>{rule}</style>\n\1", html, flags=re.IGNORECASE)
    return new_html, True if n else False


def fix_start_button_css(html: str) -> tuple[str, bool]:
    changed = False
    # Repair malformed '-repeat center' to explicit repeat/position
    html2, ch1 = sub_once(
        r"(background:url\([^)]*\);\s*)-repeat\s+center;",
        r"\1background-repeat:no-repeat; background-position:center;",
        html,
        flags=re.DOTALL,
    )
    changed |= ch1
    # Switch background-size: cover -> contain (including vendor prefixes)
    def repl_cover_to_contain(m: re.Match) -> str:
        nonlocal changed
        changed = True
        return m.group(0).replace(":cover", ":contain")

    html3 = re.sub(r"(-webkit-background-size|-moz-background-size|-o-background-size|background-size):\s*cover",
                   repl_cover_to_contain, html2)
    return html3, changed


def set_js_filename(html: str, js_name: str) -> tuple[str, bool]:
    # e.src = "...";
    pat = r'''(e\.src\s*=\s*")[^"]*(";)'''
    repl = rf"\1{re.escape(js_name)}\2"
    return sub_once(pat, repl, html)


def set_start_bg_url(html: str, url: str) -> tuple[str, bool]:
    # in .p8_start_button CSS: background:url("...")
    pat = r'''(\.p8_start_button\s*\{[^}]*?background:url\()("|').*?\2(\))'''
    # Always rewrite using double-quotes
    repl = rf"\1\"{url}\"\3"
    return sub_once(pat, repl, html, flags=re.DOTALL)


def enable_autoplay_smooth(html: str) -> tuple[str, bool]:
    changed = False
    # 1) set var p8_autoplay = true;
    html, ch1 = sub_once(r"(var\s+p8_autoplay\s*=\s*)false", r"\1true", html)
    changed |= ch1
    # 2) hide start button by default (display:none) to avoid showing splash while booting
    html, ch2 = sub_once(r"(<div id=\"p8_start_button\"[^>]*?style=\"[^\"]*?)display:flex;?", r"\1display:none;", html)
    changed |= ch2
    # 3) add delayed reveal if not running (1000 ms)
    if "/* itch: delayed splash reveal */" not in html:
        snippet = (
            "\n    /* itch: delayed splash reveal */\n"
            "    setTimeout(function(){\n"
            "      try { if (!window.p8_is_running) {\n"
            "        var el = document.getElementById('p8_start_button');\n"
            "        if (el) el.style.display = 'flex';\n"
            "      }} catch(e){}\n"
            "    }, 1000);\n"
        )
        html, ch3 = sub_once(r"(p8_update_button_icons\(\);\s*)", r"\1" + snippet, html)
        changed |= ch3
    return html, changed


def main():
    ap = argparse.ArgumentParser(description="Patch PICO-8 index.html for nicer itch.io embeds")
    ap.add_argument("--html", type=Path, default=DEFAULT_HTML, help="Path to index.html (default: build/index.html)")
    ap.add_argument("--js", dest="js_name", help="Set JS filename for e.src (e.g., space_shooter.js)")
    ap.add_argument("--bg-url", dest="bg_url", help="Set p8_start_button background url (data URL or https URL)")
    ap.add_argument("--autoplay-smooth", action="store_true", help="Enable autoplay and delay splash to avoid flicker")
    ap.add_argument("--hide-ui", action="store_true", help="Hide overlay UI buttons (mute/pause) for a cleaner embed")
    args = ap.parse_args()

    html_path: Path = args.html
    if not html_path.exists():
        raise SystemExit(f"File not found: {html_path}")

    src = html_path.read_text(encoding="utf-8", errors="ignore")
    original = src
    total_changes = []

    src, ch = ensure_body_bg_removed(src)
    if ch: total_changes.append("Removed body background-color")

    src, ch = set_frame_fullscreen_caps(src)
    if ch: total_changes.append("Set frame max-width:100vw, max-height:100vh")

    src, ch = tighten_menu_button_spacing(src)
    if ch: total_changes.append("Tightened menu button spacing; removed extra left margin")

    src, ch = add_clean_frame_css(src)
    if ch: total_changes.append("Added clean-frame CSS (transparent background, no gutters)")

    src, ch = pixel_perfect_splash(src)
    if ch: total_changes.append("Added pixel-perfect rule for splash/start image")

    src, ch = ensure_canvas_pixelated(src)
    if ch: total_changes.append("Enforced pixelated rendering on canvas")

    src, ch = fix_start_button_css(src)
    if ch: total_changes.append("Fixed start-button CSS (repeat/position, size contain)")

    if args.js_name:
        src, ch = set_js_filename(src, args.js_name)
        if ch: total_changes.append(f"Set JS filename -> {args.js_name}")

    if args.bg_url:
        src, ch = set_start_bg_url(src, args.bg_url)
        if ch: total_changes.append("Updated start-button background url")

    if args.autoplay_smooth:
        src, ch = enable_autoplay_smooth(src)
        if ch: total_changes.append("Enabled autoplay with delayed splash reveal")

    if args.hide_ui:
        src, ch = hide_overlay_ui(src)
        if ch: total_changes.append("Hid overlay UI buttons")

    if src != original:
        html_path.write_text(src, encoding="utf-8")
        print(f"Patched {html_path}")
        if total_changes:
            for t in total_changes:
                print(" -", t)
    else:
        print("No changes needed; already up to date.")


if __name__ == "__main__":
    main()
