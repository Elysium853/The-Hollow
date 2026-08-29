#!/usr/bin/env bash
#
# check-parity.sh — verify The-Hollow's repository-wide invariants.
#
# For every album folder:
#   1. each track lyric file `NN - Title.md` must have a matching MP3 with the
#      identical base name (`NN - Title.mp3`), and vice versa;
#   2. the only non-track file allowed is the album's prose story `<Folder>.md`;
#   3. prints per-folder track counts and a grand total.
# Then a repo-wide pass:
#   4. the ID3 tag layer of every MP3 (artist/album/track/genre/year/USLT),
#      checked when python3 with mutagen is available (see scripts/tag.sh);
#   5. canon & text checks: banned stale canon values in lyric files, a
#      `## Lyrics` section in every lyric file, the arithmetic-lock count
#      line, and LF-only line endings in tracked text files (see CANON.md).
#      Generated `*.pdf` exports are excluded from the LF scan — PDF internals
#      legitimately use CRLF; the export is pinned `binary` in .gitattributes.
#
# Usage:        scripts/check-parity.sh
# Exit code:    0 when the whole repository is consistent, 1 otherwise.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "error: cannot cd to repo root: $ROOT" >&2; exit 1; }

status=0
albums=0
grand_total=0

printf '%-44s %7s %7s %7s   %s\n' "Album" "Tracks" "MD" "MP3" "Status"
printf '%s\n' "--------------------------------------------------------------------------"

for dir in */; do
  dir="${dir%/}"
  case "$dir" in
    .git|.github|.logs|.private|.temp|_POTENTIAL-UPDATES|node_modules|scripts) continue ;;
  esac
  [ -d "$dir" ] || continue
  [ -n "$(ls -A "$dir")" ] || continue   # skip empty dirs (no album content)

  md=()
  mp3=()
  other=()

  for f in "$dir"/*.md "$dir"/*.mp3; do
    [ -e "$f" ] || continue
    name="${f##*/}"
    if [[ "$name" =~ ^[0-9]{1,2}\ -[^.]*\.(md|mp3)$ ]]; then
      base="${name%.*}"
      case "$name" in
        *.md)  md+=("$base") ;;
        *.mp3) mp3+=("$base") ;;
      esac
    else
      other+=("$name")
    fi
  done

  md_sorted="$(printf '%s\n' "${md[@]}" | sort -u)"
  mp3_sorted="$(printf '%s\n' "${mp3[@]}" | sort -u)"

  # base names present on only one side → pair is missing
  only_md="$(comm -23 <(printf '%s' "$md_sorted") <(printf '%s' "$mp3_sorted"))"
  only_mp3="$(comm -13 <(printf '%s' "$md_sorted") <(printf '%s' "$mp3_sorted"))"

  # duplicate base names within one side
  dup_md=""
  dup_mp3=""
  [ "${#md[@]}"  -gt 0 ] && dup_md="$(printf '%s\n' "${md[@]}" | sort | uniq -d)"
  [ "${#mp3[@]}" -gt 0 ] && dup_mp3="$(printf '%s\n' "${mp3[@]}" | sort | uniq -d)"

  # non-track files: must contain exactly the prose story `<Folder>.md`, nothing else
  prose_found=0
  stray=""
  if [ "${#other[@]}" -gt 0 ]; then
    for f in "${other[@]}"; do
      if [ "$f" = "$dir.md" ]; then
        prose_found=1
      else
        stray+="  stray file: ${dir}/${f}"$'\n'
      fi
    done
  fi
  [ "$prose_found" -eq 1 ] || stray+="  expected prose story: ${dir}/${dir}.md"$'\n'

  problems=""
  if [ -n "$only_md" ]; then
    problems+="$(printf '%s\n' "${only_md}" | sed 's/^/  missing MP3: /')"$'\n'
  fi
  if [ -n "$only_mp3" ]; then
    problems+="$(printf '%s\n' "${only_mp3}" | sed 's/^/  missing MD: /')"$'\n'
  fi
  if [ -n "$dup_md" ]; then
    problems+="$(printf '%s\n' "${dup_md}" | sed 's/^/  duplicate MD: /')"$'\n'
  fi
  if [ -n "$dup_mp3" ]; then
    problems+="$(printf '%s\n' "${dup_mp3}" | sed 's/^/  duplicate MP3: /')"$'\n'
  fi
  problems+="$stray"

  md_n="${#md[@]}"
  mp3_n="${#mp3[@]}"
  tracks="$md_n"

  if [ -z "$problems" ]; then
    printf '%-44s %7s %7s %7s   OK\n' "$dir" "$tracks" "$md_n" "$mp3_n"
    albums=$((albums + 1))
    grand_total=$((grand_total + tracks))
  else
    printf '%-44s %7s %7s %7s   FAIL\n' "$dir" "$tracks" "$md_n" "$mp3_n"
    printf '%s' "$problems"
    status=1
  fi
done

# ---------------------------------------------------------------------------
# ID3 tag layer (distribution metadata — see _POTENTIAL-UPDATES items #4/#10)
# Needs a python3 with the `mutagen` package; skipped with a warning if absent.
# ---------------------------------------------------------------------------
TAG_PY=""
for candidate in "${HOME}/.venvs/hollow/bin/python3" "$(command -v python3 2>/dev/null || true)"; do
  [ -n "$candidate" ] && [ -x "$candidate" ] \
    && "$candidate" -c 'import mutagen' >/dev/null 2>&1 \
    && { TAG_PY="$candidate"; break; }
done

if [ -n "$TAG_PY" ]; then
  printf '%s\n' "--------------------------------------------------------------------------"
  printf '%s\n' "ID3 tag layer (artist / album / track / genre / year / lyrics):"
  if ! "$TAG_PY" - <<'PYEOF'; then
import glob
import os
import sys

from mutagen.id3 import ID3

SKIP = {".git", ".github", ".logs", ".private", ".temp", "_POTENTIAL-UPDATES", "node_modules", "scripts"}
ARTIST = "Echoes of 1848"   # official credit, settled 2026-08-27
GENRE = "Mixed"
YEAR = "2026"
YEAR_KEYS = ("TYER", "TDRC")   # mutagen reads a stored v2.3 TYER back as TDRC


def lyrics_body(md):
    try:
        with open(md, encoding="utf-8") as fh:
            lines = fh.read().replace("\r\n", "\n").split("\n")
    except OSError:
        return None
    body, inside = [], False
    for ln in lines:
        if not inside:
            if ln.strip() == "## Lyrics":
                inside = True
            continue
        body.append(ln)
    while body and not body[0].strip():
        body.pop(0)
    while body and not body[-1].strip():
        body.pop()
    return "\n".join(body) if inside else None


def text(tags, key):
    frame = tags.get(key)
    if frame is None or not hasattr(frame, "text") or not frame.text:
        return None
    return frame.text[0]


bad = checked = 0
for folder in sorted(os.listdir(".")):
    if folder in SKIP or not os.path.isdir(folder):
        continue
    mp3s = sorted(glob.glob(os.path.join(folder, "*.mp3")))
    if not mp3s:
        continue
    album = folder.replace("-", " ")
    problems = []
    for mp3 in mp3s:
        checked += 1
        base = os.path.basename(mp3)[:-4]
        if " - " not in base:
            problems.append(f"  {base}.mp3: base name has no 'NN - ' prefix")
            continue
        nn, title = base.split(" - ", 1)
        nn = nn.zfill(2)
        try:
            tags = ID3(mp3)
        except Exception as error:
            problems.append(f"  {base}.mp3: cannot read tags ({error})")
            continue
        year = None
        for key in YEAR_KEYS:
            year = text(tags, key)
            if year is not None:
                break
        expected = {
            "TIT2": title, "TRCK": nn, "TPE1": ARTIST, "TPE2": ARTIST,
            "TALB": album, "TCON": GENRE, "TYER/TDRC": YEAR,
        }
        got = {
            "TIT2": text(tags, "TIT2"), "TRCK": text(tags, "TRCK"),
            "TPE1": text(tags, "TPE1"), "TPE2": text(tags, "TPE2"),
            "TALB": text(tags, "TALB"), "TCON": text(tags, "TCON"),
            "TYER/TDRC": year,
        }
        for tag, expected_value in expected.items():
            if str(got[tag]).strip() != str(expected_value):
                problems.append(f"  {base}.mp3: {tag} = {got[tag]!r}, expected {expected_value!r}")
        if not tags.getall("USLT"):
            problems.append(f"  {base}.mp3: no USLT lyrics frame")
        else:
            body = lyrics_body(os.path.join(folder, base + ".md"))
            if body is not None and tags.getall("USLT")[0].text != body:
                problems.append(f"  {base}.mp3: USLT lyrics differ from the '## Lyrics' body")
    if problems:
        bad += 1
        print(f"FAIL {folder}")
        for problem in problems:
            print(problem)
    else:
        print(f"ok   {folder} — {len(mp3s)} tracks fully tagged")
print(f"tag check: {checked} MP3s, {bad} album(s) failing")
sys.exit(1 if bad else 0)
PYEOF
    status=1
  fi
else
  printf 'WARN: python3 with mutagen not found — tag-layer check skipped. One-time setup: python3 -m venv ~/.venvs/hollow && ~/.venvs/hollow/bin/pip install mutagen\n' >&2
fi

# -----------------------------------------------------
# Canon & text checks (no external dependencies; see CANON.md)
# -----------------------------------------------------
lyric_files=0
missing_lyrics=0
banned_hits=0
crlf_files=0
text_problems=""

# 1. Every lyric file must carry a "## Lyrics" section, and must not contain
#    banned stale canon values (the P0 age/count leak from The-Hollow-Destroyed).
while IFS= read -r f; do
  [ -n "$f" ] || continue
  lyric_files=$((lyric_files + 1))
  if ! grep -q '^## Lyrics[[:space:]]*$' "$f"; then
    text_problems+="  ${f}: missing '## Lyrics' section"$'\n'
    missing_lyrics=$((missing_lyrics + 1))
  fi
  hits="$(grep -niE '(thirty-six|forty-three)' "$f" || true)"
  hits+="$(grep -niE 'fifteen years (of (waiting|your love|hidden love)|hidden|i loved in silence)' "$f" || true)"
  if [ -n "$hits" ]; then
    while IFS= read -r ln; do
      text_problems+="  ${f}: banned stale value: ${ln}"$'\n'
      banned_hits=$((banned_hits + 1))
    done <<< "$hits"
  fi
done < <(git ls-files '*/[0-9]*.md')

# sanity: a full album set of lyric files is expected, so a zero count means
# the git listing broke and the checks above would silently pass.
if [ "$lyric_files" -lt 100 ]; then
  text_problems+="  expected >= 100 lyric files, found ${lyric_files} (git ls-files '*/[0-9]*.md')"$'\n'
fi

# 2. The arithmetic-lock count line (the grandmothers' count of the hollow,
#    per CANON.md "The arithmetic lock") must stay in Bloodlines track 01.
count_lock="Bloodlines/01 - The Grandmothers' Fire.md"
if ! grep -q 'ten, eleven, twelve, and one to come' "$count_lock"; then
  text_problems+="  ${count_lock}: count lock line missing ('ten, eleven, twelve, and one to come')"$'\n'
fi

# 3. No tracked text file may carry CR bytes (non-LF line endings; .gitattributes).
while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in
    *.mp3|*.png|*.jpg|*.jpeg|*.pdf) continue ;;
  esac
  if LC_ALL=C grep -Uq $'\r' "$f"; then
    text_problems+="  ${f}: contains CR (non-LF line endings)"$'\n'
    crlf_files=$((crlf_files + 1))
  fi
done < <(git ls-files)

if [ -n "$text_problems" ]; then
  status=1
  printf 'TEXT CHECK FAIL : canon & text layer\n'
  printf '%s' "$text_problems"
else
  printf 'text check: %d lyric files; all with ## Lyrics; 0 banned values; count lock present; 0 CRLF\n' "$lyric_files"
fi

printf '%s\n' "--------------------------------------------------------------------------"
if [ "$status" -eq 0 ]; then
  printf 'OK: %d albums, %d tracks — every track MD has a matching MP3 with the same base name.\n' \
    "$albums" "$grand_total"
else
  printf 'FAIL: fix the items above, then re-run %s.\n' "${BASH_SOURCE[0]}" >&2
fi
exit "$status"
