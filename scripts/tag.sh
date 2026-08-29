#!/usr/bin/env bash
#
# tag.sh — distribution-ready ID3 tag pass for every track MP3 in The-Hollow.
#
# Writes a canonical ID3v2.3 frame set onto every `NN - Title.mp3`:
#   TIT2 = track title (the `Title` part of the file base name; no number)
#   TRCK = the `NN` from the file base name (zero-padded)
#   TPE1 = artist       = "$ARTIST"        (official credit, settled 2026-08-27)
#   TPE2 = album artist = "$ARTIST"
#   TALB = album name   = album folder name, kebab-case -> title (e.g.
#         `The-Red-Hollow-of-Kentucky` -> `The Red Hollow of Kentucky`)
#   TCON = genre        = "$GENRE"
#   TYER = release year = "$YEAR"
#   USLT = lyrics       = the `## Lyrics` body of the sibling `NN - Title.md`
#         (markdown heading stripped, section tags kept — matches the source MD)
#   COMM = comment      = the Suno "made with suno; … id=…" comment, recovered
#         from the existing tag so the Suno track ID survives
#   WOAS/APIC/TXXX(sga) = Suno track URL, cover art and quality flag, preserved
#         when present
#
# The audio frames are never touched (metadata-only rewrite), so decoded audio
# is byte-identical before/after. Run `scripts/check-parity.sh` afterwards —
# it now verifies the tag layer against the expected values.
#
# Requires: a python3 with the `mutagen` package. One-time setup:
#     python3 -m venv ~/.venvs/hollow
#     ~/.venvs/hollow/bin/pip install mutagen
#
# Usage:
#     scripts/tag.sh               tag every album folder
#     scripts/tag.sh --dry-run     print what would change, change nothing
#     scripts/tag.sh --album X     tag only album folder X (kebab-case name)
#
# Exit code: 0 when every album folder processed cleanly, 1 otherwise.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ARTIST="Echoes of 1848"   # official artist / album-artist credit
GENRE="Mixed"             # genre branding on every track
YEAR="2026"               # release year
ALBUM_FILTER=""
DRY_RUN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --album) ALBUM_FILTER="$2"; shift ;;
    -h|--help) sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

# locate a python interpreter that can import mutagen
PY=""
for candidate in "${HOME}/.venvs/hollow/bin/python3" "$(command -v python3 2>/dev/null || true)"; do
  if [ -n "$candidate" ] && [ -x "$candidate" ] && "$candidate" -c 'import mutagen' >/dev/null 2>&1; then
    PY="$candidate"
    break
  fi
done
if [ -z "$PY" ]; then
  cat >&2 <<'SETUP'
error: no python3 with the `mutagen` package found.
One-time setup:
    python3 -m venv ~/.venvs/hollow
    ~/.venvs/hollow/bin/pip install mutagen
SETUP
  exit 1
fi

export HOLLOW_ARTIST="$ARTIST" HOLLOW_GENRE="$GENRE" HOLLOW_YEAR="$YEAR"
export HOLLOW_ALBUM_FILTER="$ALBUM_FILTER" HOLLOW_DRY_RUN="$DRY_RUN"

"$PY" - <<'PYEOF'
import glob
import os
import re
import sys

from mutagen.id3 import ID3, TIT2, TRCK, TPE1, TPE2, TALB, TCON, TYER, USLT, COMM

ARTIST = os.environ["HOLLOW_ARTIST"]
GENRE = os.environ["HOLLOW_GENRE"]
YEAR = os.environ["HOLLOW_YEAR"]
FILTER = os.environ["HOLLOW_ALBUM_FILTER"]
DRY_RUN = os.environ["HOLLOW_DRY_RUN"] == "1"
ROOT = os.getcwd()

# Mirror the album discovery / skip list used by scripts/check-parity.sh.
SKIP = {
    ".git", ".github", ".logs", ".private", ".temp",
    "_POTENTIAL-UPDATES", "node_modules", "scripts",
}
TRACK_MD = re.compile(r"^\d{1,2} - .+\.md$")


def album_dirs():
    for name in sorted(os.listdir(ROOT)):
        if name in SKIP or not os.path.isdir(name):
            continue
        if glob.glob(os.path.join(name, "*.mp3")):
            yield name


def album_name(folder):
    """Prettify the kebab-case folder name into the credited album title."""
    return folder.replace("-", " ")


def extract_lyrics(md):
    """The lyrics body only — everything after `## Lyrics`, no markdown header."""
    with open(md, encoding="utf-8") as fh:
        lines = fh.read().replace("\r\n", "\n").split("\n")
    body, in_lyrics = [], False
    for ln in lines:
        if not in_lyrics:
            if ln.strip() == "## Lyrics":
                in_lyrics = True
            continue
        body.append(ln)
    while body and not body[0].strip():
        body.pop(0)
    while body and not body[-1].strip():
        body.pop()
    return "\n".join(body) if in_lyrics else ""


def old_comment(tags):
    """Recover the Suno comment (with its track ID) from COMM or TXXX frames."""
    for c in tags.getall("COMM"):
        if c.text and c.text[0].strip():
            return str(c.text[0])
    for t in tags.getall("TXXX"):
        if t.desc == "comment" and t.text and str(t.text[0]).strip():
            return str(t.text[0])
    return "made with suno"


fail = 0
tagged = 0
for folder in album_dirs():
    if FILTER and folder != FILTER:
        continue
    album = album_name(folder)
    mp3s = sorted(glob.glob(os.path.join(folder, "*.mp3")))
    for mp3 in mp3s:
        base = os.path.basename(mp3)[:-4]
        md = os.path.join(folder, base + ".md")
        if not os.path.exists(md):
            print(f"  MISSING MD for {mp3}", file=sys.stderr)
            fail = 1
            continue
        if " - " not in base:
            print(f"  BAD base name (no 'NN - ' part): {mp3}", file=sys.stderr)
            fail = 1
            continue
        nn, title = base.split(" - ", 1)
        nn = nn.zfill(2)
        body = extract_lyrics(md)
        tags = ID3(mp3)
        comment = old_comment(tags)
        preserved = tags.getall("WOAS")
        preserved += [t for t in tags.getall("TXXX") if t.desc == "sga"]
        pics = tags.getall("APIC")

        new = ID3()
        new.add(TIT2(encoding=3, text=[title]))
        new.add(TRCK(encoding=3, text=[nn]))
        new.add(TPE1(encoding=3, text=[ARTIST]))
        new.add(TPE2(encoding=3, text=[ARTIST]))
        new.add(TALB(encoding=3, text=[album]))
        new.add(TCON(encoding=3, text=[GENRE]))
        new.add(TYER(encoding=3, text=[YEAR]))
        if body:
            new.add(USLT(encoding=3, lang="eng", desc="", text=body))
        new.add(COMM(encoding=3, lang="eng", desc="", text=comment))
        for frame in preserved:
            new.add(frame)
        for pic in pics:
            new.add(pic)

        if DRY_RUN:
            print(f"  [dry-run] {folder}/{base}.mp3  album={album!r} track={nn} "
                  f"lyrics={len(body)} chars")
            continue
        new.save(mp3, v2_version=3)
        tagged += 1
        print(f"  OK  {folder}/{base}.mp3  album={album!r} track={nn} "
              f"lyrics={len(body)} chars")
        if not body:
            print(f"    WARN lyrics empty (missing '## Lyrics' in {md})", file=sys.stderr)

    n_md = sum(1 for m in glob.glob(os.path.join(folder, "*.md"))
               if TRACK_MD.match(os.path.basename(m)))
    print(f"{folder}: {len(mp3s)} MP3 tagged, {n_md} track MDs")

if DRY_RUN:
    print("dry run only — nothing written.")
elif tagged:
    print(f"tagged {tagged} file(s) — run scripts/check-parity.sh to verify the tag layer")
sys.exit(fail)
PYEOF
