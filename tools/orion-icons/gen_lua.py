# Write ~/.config/nvim/lua/orion_icons/data.lua: Orion's icon theme mappings
# (file names, extensions, folder names, languages) pointing at the glyphs that
# build_font.py added to the "JetBrainsMono Orion" font.
# usage: python gen_lua.py out/icons.json OUTFILE
import colorsys, glob, json, os, sys

IDE = os.path.expanduser("~/Documents/Amphion/orion/Orion/ide/extensions")
theme = json.load(open(f"{IDE}/theme-orion-icons/src/orion-icon-theme.json"))
glyphs = json.load(open(sys.argv[1]))

# VS Code language id -> Neovim filetype, where the names differ
FT = {"shellscript": "sh", "ignore": "gitignore", "plaintext": "text", "makefile": "make",
      "dockerfile": "dockerfile", "jsonc": "jsonc", "objective-c": "objc", "objective-cpp": "objcpp",
      "csharp": "cs", "fsharp": "fsharp", "bat": "dosbatch", "restructuredtext": "rst",
      "git-commit": "gitcommit", "git-rebase": "gitrebase", "jade": "pug", "pip-requirements": "requirements",
      "ssh_config": "sshconfig", "latex": "tex", "tex": "plaintex", "properties": "jproperties"}


def main_color(colors):
    """The icon's dominant visible color: biggest area, ignoring near-black shapes."""
    best, best_area = None, -1
    for hexc, alpha, area in colors:
        r, g, b = (int(hexc[i:i + 2], 16) / 255 for i in (1, 3, 5))
        if alpha < 0.3 or colorsys.rgb_to_hls(r, g, b)[1] < 0.18:
            continue
        if area > best_area:
            best, best_area = hexc, area
    return best or (colors[0][0] if colors else "#d4d4d4")


# Expand the theme's languageIds into extensions / file names, the way VS Code does
langs = {}
for p in glob.glob(f"{IDE}/*/package.json"):
    try:
        contrib = json.load(open(p)).get("contributes", {})
    except Exception:
        continue
    for lang in contrib.get("languages", []):
        e = langs.setdefault(lang["id"], {"ext": set(), "names": set()})
        e["ext"].update(x.lower().lstrip(".") for x in lang.get("extensions", []))
        e["names"].update(x.lower() for x in lang.get("filenames", []))

extensions = {k.lower(): v for k, v in theme["fileExtensions"].items()}
filenames = {k.lower(): v for k, v in theme["fileNames"].items()}
filetypes = {}
for lang_id, icon in theme["languageIds"].items():
    for ext in langs.get(lang_id, {}).get("ext", ()):
        extensions.setdefault(ext, icon)   # an explicit fileExtensions entry wins
    for name in langs.get(lang_id, {}).get("names", ()):
        filenames.setdefault(name, icon)
    filetypes[FT.get(lang_id, lang_id)] = icon

used = set(extensions.values()) | set(filenames.values()) | set(filetypes.values()) \
    | set(theme["folderNames"].values()) | {theme["file"], theme["folder"]}


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def table(name, d):
    rows = [f"  [{lua_str(k)}] = {lua_str(v)}," for k, v in sorted(d.items())]
    return f"M.{name} = {{\n" + "\n".join(rows) + "\n}\n"


out = [
    "-- GENERATED from Orion's file icon theme (theme-orion-icons). Don't edit by hand:",
    "-- rerun the build scripts instead. Each icon is one character in the",
    '-- "JetBrainsMono Orion" font, drawn in Orion\'s colors; `color` is the',
    "-- icon's main color, used where a terminal draws icons in one color.",
    "local M = {}",
    "",
    f'M.default_file = {lua_str(theme["file"])}',
    f'M.default_folder = {lua_str(theme["folder"])}',
    "",
    "-- icon id -> { character, main color }",
    "M.icons = {",
]
for icon_id in sorted(used):
    g = glyphs[icon_id]
    out.append(f'  [{lua_str(icon_id)}] = {{ "\\u{{{g["cp"]:X}}}", "{main_color(g["colors"])}" }},')
out.append("}\n")
out.append("-- file extension (no dot, lowercase; \"d.ts\" style compound ones too) -> icon id")
out.append(table("extensions", extensions))
out.append("-- exact file name (lowercase) -> icon id")
out.append(table("filenames", filenames))
out.append("-- folder name (lowercase) -> icon id")
out.append(table("folders", {k.lower(): v for k, v in theme["folderNames"].items()}))
out.append("-- Neovim filetype -> icon id (for buffers with no file name, like a new buffer)")
out.append(table("filetypes", filetypes))
out.append("return M")
os.makedirs(os.path.dirname(sys.argv[2]), exist_ok=True)
open(sys.argv[2], "w").write("\n".join(out) + "\n")
print("icons", len(used), "extensions", len(extensions), "filenames", len(filenames),
      "folders", len(theme["folderNames"]), "filetypes", len(filetypes))
