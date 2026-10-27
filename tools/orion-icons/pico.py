# Convert every Orion SVG to plain filled paths (strokes outlined, transforms baked in).
# picosvg can't do <mask>: Figma uses them as simple clips (-> <clipPath>) or for
# "outside" strokes (dropped: the stroke is then centered, a hair thicker).
import glob, os, re
from picosvg.svg import SVG
SRC = os.path.expanduser("~/Documents/Amphion/orion/Orion/ide/extensions/theme-orion-icons/src/icons")
os.makedirs("pico", exist_ok=True)

def unmask(s):
    for m in re.finditer(r'<mask id="([^"]+)"[^>]*>(.*?)</mask>', s, re.S):
        mid, body = m.group(1), m.group(2)
        if "outside" in mid or 'fill="black"' in m.group(0):
            s = s.replace(m.group(0), "")
            s = s.replace(f' mask="url(#{mid})"', "")
        else:
            s = s.replace(m.group(0), f'<clipPath id="{mid}">{body}</clipPath>')
            s = s.replace(f'mask="url(#{mid})"', f'clip-path="url(#{mid})"')
    return s

bad = []
for f in sorted(glob.glob(SRC + "/*/*.svg")):
    name = os.path.splitext(os.path.basename(f))[0]
    try:
        svg = SVG.fromstring(unmask(open(f).read())).topicosvg()
        open(f"pico/{name}.svg", "w").write(svg.tostring(pretty_print=True))
    except Exception as e:
        bad.append((name, str(e).splitlines()[0][:200]))
print("ok", len(glob.glob("pico/*.svg")), "failed", len(bad))
for b in bad: print(b)
