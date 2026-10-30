# Add the Orion file icons to a copy of JetBrainsMonoNL Nerd Font Mono (the
# "No Ligatures" cut, so <= stays two characters instead of becoming ≤).
# Each icon becomes one character at U+F3000 + n. It is a color glyph (COLR/CPAL:
# one layer per SVG shape, in Orion's own colors), and its plain outline (all
# layers merged) is the fallback where color glyphs aren't drawn.
# usage: python build_font.py OUTDIR
import json, os, re, sys
import xml.etree.ElementTree as ET
import pathops
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.svgLib.path import parse_path
from fontTools.colorLib.builder import buildCOLR, buildCPAL

THEME = os.path.expanduser("~/Documents/Amphion/orion/Orion/ide/extensions/theme-orion-icons/src/orion-icon-theme.json")
FONTS = os.path.expanduser("~/Library/Fonts")
STYLES = ["Regular", "Bold", "Italic", "BoldItalic"]
FIRST = 0xF3000
SIZE = 960          # an icon's 24-unit viewBox spans this many font units (cell is 600 wide; art is ~3/4 of it)
CENTER = (300, 360) # middle of the cell: x half the advance, y middle of the line box
NS = "{http://www.w3.org/2000/svg}"
OUT = sys.argv[1]


NAMED = {"white": "#ffffff", "black": "#000000"}


def hex_rgba(color, alpha):
    """'#abc', '#aabbcc', 'rgb(10%,20%,30%)', 'rgb(1,2,3)' or 'white' -> (r, g, b, a) in 0..1"""
    color = NAMED.get(color.strip().lower(), color.strip())
    m = re.match(r"rgba?\(([^)]*)\)", color)
    if m:
        parts = [v.strip() for v in m.group(1).split(",")]
        rgb = tuple(float(v[:-1]) / 100 if v.endswith("%") else float(v) / 255 for v in parts[:3])
        return rgb + (alpha * (float(parts[3]) if len(parts) > 3 else 1),)
    c = color.lstrip("#")
    if len(c) in (3, 4):
        c = "".join(ch * 2 for ch in c)
    a = int(c[6:8], 16) / 255 if len(c) == 8 else 1
    return tuple(int(c[i:i + 2], 16) / 255 for i in (0, 2, 4)) + (alpha * a,)


def read_icon(path):
    """[(pathops.Path in SVG coords, (r,g,b,a))] for every visible shape, plus the viewBox."""
    root = ET.parse(path).getroot()
    vb = root.get("viewBox")
    vb = [float(v) for v in vb.split()] if vb else [0, 0, float(root.get("width")), float(root.get("height"))]
    stops = {}  # gradient id -> first stop color (COLR v0 has no gradients)
    for grad in root.iter():
        if grad.tag in (NS + "linearGradient", NS + "radialGradient"):
            stop = grad.find(NS + "stop")
            stops[grad.get("id")] = (stop.get("stop-color") or "#000000", float(stop.get("stop-opacity") or 1))
    shapes = []
    for el in root.iter(NS + "path"):
        fill = el.get("fill") or "#000000"
        alpha = float(el.get("opacity") or 1) * float(el.get("fill-opacity") or 1)
        m = re.match(r"url\(#(.+)\)", fill)
        if m:
            if m.group(1) not in stops:
                continue  # a bitmap <pattern> (firebase's shading overlay): skip it
            fill, stop_alpha = stops[m.group(1)]
            alpha *= stop_alpha
        if fill == "none" or alpha <= 0.01:
            continue
        rgba = hex_rgba(fill, alpha)
        if rgba[3] <= 0.01:
            continue
        p = pathops.Path()
        parse_path(el.get("d"), p.getPen())
        p.fillType = pathops.FillType.EVEN_ODD if el.get("fill-rule") == "evenodd" else pathops.FillType.WINDING
        p.simplify(fix_winding=True)  # TrueType fills by nonzero winding
        shapes.append((p, rgba))
    return shapes, vb


def to_glyph(path, vb):
    s = SIZE / max(vb[3], vb[2])
    cx, cy = vb[0] + vb[2] / 2, vb[1] + vb[3] / 2
    # SVG y points down, font y points up
    xform = (s, 0, 0, -s, CENTER[0] - cx * s, CENTER[1] + cy * s)
    tt = TTGlyphPen(None)
    path.draw(TransformPen(Cu2QuPen(tt, max_err=1.0, reverse_direction=True), xform))
    return tt.glyph()


def main():
    theme = json.load(open(THEME))
    ids = sorted(theme["iconDefinitions"])
    icons = {}
    for n, icon_id in enumerate(ids):
        svg = os.path.basename(theme["iconDefinitions"][icon_id]["iconPath"])
        shapes, vb = read_icon(os.path.join(os.path.dirname(__file__), "pico", svg))
        icons[icon_id] = {"cp": FIRST + n, "shapes": shapes, "vb": vb}

    # One shared palette of every color used
    palette, color_index = [], {}
    for icon in icons.values():
        for _, rgba in icon["shapes"]:
            key = tuple(round(v, 4) for v in rgba)
            if key not in color_index:
                color_index[key] = len(palette)
                palette.append(key)

    os.makedirs(OUT, exist_ok=True)
    for style in STYLES:
        font = TTFont(os.path.join(FONTS, f"JetBrainsMonoNLNerdFontMono-{style}.ttf"))
        order = font.getGlyphOrder()
        glyf, hmtx = font["glyf"], font["hmtx"]
        colr = {}
        for icon_id, icon in icons.items():
            base = f"orion.{icon_id}"
            union = pathops.Path()
            layers = []
            for k, (p, rgba) in enumerate(icon["shapes"]):
                union.addPath(p)
                layer = f"{base}.{k}"
                glyf[layer] = to_glyph(p, icon["vb"])
                layers.append((layer, color_index[tuple(round(v, 4) for v in rgba)]))
            try:
                union.simplify(fix_winding=True)
            except pathops.PathOpsError:
                pass  # overlapping shapes still fill correctly (nonzero winding)
            glyf[base] = to_glyph(union, icon["vb"])
            colr[base] = layers
            for t in font["cmap"].tables:
                if t.format == 12:
                    t.cmap[icon["cp"]] = base
        order = list(dict.fromkeys(glyf.glyphOrder))  # glyf[...] = appended the new names
        glyf.glyphOrder = order
        font.setGlyphOrder(order)
        for g in order:
            if g not in hmtx.metrics:
                glyf[g].recalcBounds(glyf)
                hmtx[g] = (600, getattr(glyf[g], "xMin", 0))
        font["COLR"] = buildCOLR(colr, version=0)
        font["CPAL"] = buildCPAL([palette])

        # New family name so it installs next to the original
        family, ps_style = "JetBrainsMono Orion", style
        sub = {"BoldItalic": "Bold Italic"}.get(style, style)
        name = font["name"]
        for rec in list(name.names):
            if rec.nameID in (1, 2, 3, 4, 6, 16, 17):
                name.removeNames(nameID=rec.nameID)
        rib = sub if sub in ("Regular", "Bold", "Italic", "Bold Italic") else "Regular"
        name.setName(family, 1, 3, 1, 0x409); name.setName(family, 1, 1, 0, 0)
        name.setName(rib, 2, 3, 1, 0x409); name.setName(rib, 2, 1, 0, 0)
        name.setName(f"{family} {sub}", 4, 3, 1, 0x409); name.setName(f"{family} {sub}", 4, 1, 0, 0)
        name.setName(f"JetBrainsMonoOrion-{ps_style}", 6, 3, 1, 0x409); name.setName(f"JetBrainsMonoOrion-{ps_style}", 6, 1, 0, 0)
        name.setName(f"JetBrainsMonoOrion-{ps_style};orion-icons", 3, 3, 1, 0x409)
        font.save(os.path.join(OUT, f"JetBrainsMonoOrion-{style}.ttf"))
        print("built", style, len(order), "glyphs")

    json.dump({i: {"cp": v["cp"], "colors": [
        ["#%02x%02x%02x" % tuple(round(c * 255) for c in rgba[:3]), rgba[3], p.area] for p, rgba in v["shapes"]]}
        for i, v in icons.items()}, open(os.path.join(OUT, "icons.json"), "w"), indent=0)


main()
