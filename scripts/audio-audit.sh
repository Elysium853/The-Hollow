#!/usr/bin/env bash
#
# audio-audit.sh — one-off audio integrity audit for every track MP3 in The-Hollow.
#
# Runs ffprobe over all album MP3s and, for each file:
#   1. decodes every frame (-count_frames; failures = non-zero exit or any
#      stderr under -v error — ffprobe 6.1.1 has no -xerror), so decode
#      errors / corruption surface as hard FAILs carrying the ffprobe message;
#   2. logs per-file duration, bitrate, sample rate, channels, codec and size
#      — the health baseline (persisted with -o FILE):
#          scripts/audio-audit.sh -o AUDIO-BASELINE.tsv
#   3. warns when the declared duration (LAME/Xing header) disagrees with the
#      duration implied by the decoded frame count by more than ±5%. This is
#      what flags *truncated* files: the header survives a cut, so declared
#      (e.g. 30.55s) lies far above decoded (e.g. 6.86s). A future CI gate
#      can escalate these warnings (or diff against the committed baseline).
#
# A file only fails on a hard decode or format error; warnings never change
# the exit code (baseline mode). Exit code: 0 all clean (warnings allowed),
# 1 one or more failing files, 2 usage error.
#
# Options:
#     scripts/audio-audit.sh           full audit (decodes all frames)
#     scripts/audio-audit.sh --quick   metadata + header probe only (fast)
#     scripts/audio-audit.sh -o FILE   also write the per-file TSV baseline
#     scripts/audio-audit.sh -h        this help
#
# Requires: ffprobe (ships with ffmpeg). The full run decodes ~7h05m of
# audio — a few minutes single-threaded; --quick finishes in seconds.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || { echo "error: cannot cd to repo root: $ROOT" >&2; exit 1; }

OUT=""
QUICK=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --quick) QUICK=1 ;;
    -o) OUT="$2"; shift ;;
    -h|--help) sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

FFPROBE="$(command -v ffprobe 2>/dev/null || true)"
if [ -z "$FFPROBE" ]; then
  echo "error: ffprobe not found — ffmpeg must be installed (ffprobe ships with it)" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# discovery — every MP3 under the repo root except non-album directories
# ---------------------------------------------------------------------------
mapfile -t FILES < <(
  find . -type f -name '*.mp3' \
    -not -path './.git/*' -not -path './.github/*' -not -path './node_modules/*' \
    -not -path './.logs/*' -not -path './.private/*' -not -path './.temp/*' \
    -not -path './_POTENTIAL-UPDATES/*' -not -path './scripts/*' \
    | sed 's|^\./||' | sort
)
total="${#FILES[@]}"
if [ "$total" -eq 0 ]; then
  echo "error: no MP3 files found — run from the repository root" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# per-file baseline (TSV) if requested
# ---------------------------------------------------------------------------
tsv_fd=""
if [ -n "$OUT" ]; then
  : > "$OUT" || { echo "error: cannot write $OUT" >&2; exit 1; }
  exec {tsv_fd}>>"$OUT"
  printf 'path\tduration_s\tbitrate_kbps\tsample_rate\tchannels\tcodec\tsize_bytes\tresult\tnote\n' >&"$tsv_fd"
fi

errfile="$(mktemp)"
trap 'rm -f "$errfile"' EXIT

printf '%-26s %-52s %9s %6s %7s %2s %-5s %10s   %s\n' "Album" "Track" "Dur" "kbps" "SampleRate" "Ch" "Codec" "Size" "Result"
printf '%s\n' "-----------------------------------------------------------------------------------------------------------------------------------------"

fails=0
warns=0
dur_total=0

# parse helpers — two probes per file (container format / audio stream only),
# so key ordering is deterministic even with embedded cover-art streams
get() { printf '%s\n' "$1" | sed -n "s/^$2=//p" | head -n1; }
is_num() { printf '%s' "$1" | grep -qE '^[0-9]+([.][0-9]+)?$'; }
for f in "${FILES[@]}"; do
  album="${f%%/*}"
  track="${f#*/}"
  base_size="$(stat -c %s "$f")"

  # NOTE: ffprobe 6.1.1 has no -xerror; failures = non-zero exit or stderr (-v error)
  # probe 1 — container format (duration, bitrate, size)
  fmt_out="$("$FFPROBE" -v error \
      -show_entries format=format_name,duration,bit_rate,size \
      -of default=noprint_wrappers=1 "$f" 2>"$errfile")"
  rc1=$?
  # probe 2 — audio stream only (skips any embedded cover-art stream)
  str_args=(-v error -select_streams a:0 \
      -show_entries stream=codec_name,sample_rate,channels,bit_rate)
  if [ "$QUICK" -eq 0 ]; then
    str_args+=(-count_frames -show_entries stream=nb_read_frames)
  fi
  str_args+=(-of default=noprint_wrappers=1 "$f")
  str_out="$("$FFPROBE" "${str_args[@]}" 2>>"$errfile")"
  rc2=$?
  errs="$(<"$errfile")"

  duration="$(get "$fmt_out" duration)"
  f_br="$(get "$fmt_out" bit_rate)"
  codec="$(get "$str_out" codec_name)"
  sr="$(get "$str_out" sample_rate)"
  ch="$(get "$str_out" channels)"
  s_br="$(get "$str_out" bit_rate)"
  nframes="$(get "$str_out" nb_read_frames)"

  result="ok"
  note=""
  if [ "$rc1" -ne 0 ] || [ "$rc2" -ne 0 ] || [ -n "$errs" ]; then
    fails=$((fails + 1))
    result="FAIL"
    note="$(printf '%s\n' "$errs" | head -n1)"
  fi

  # duration sanity: declared vs decoded-frame count (mp3: 1152 samples/frame)
  if [ "$QUICK" -eq 0 ] && [ "$result" = "ok" ] && is_num "$sr" && is_num "$nframes"; then
    computed="$(awk -v n="$nframes" -v r="$sr" 'BEGIN { printf "%.3f", n * 1152.0 / r }')"
    if is_num "$duration"; then
      if awk -v d="$duration" -v c="$computed" 'BEGIN {
             if (d <= 0 || c <= 0) exit 1
             ratio = d / c
             exit (ratio > 1.05 || ratio < 0.95) ? 0 : 1
           }'; then
        warns=$((warns + 1))
        note="duration mismatch: declared ${duration}s vs decoded ${computed}s"
      fi
    fi
  fi

  if is_num "$duration"; then
    dur_total="$(awk -v a="$dur_total" -v d="$duration" 'BEGIN { printf "%.3f", a + d }')"
  fi

  kbps=""
  for b in "$f_br" "$s_br"; do
    if [ -n "$b" ] && [ "$b" != "N/A" ] && is_num "$b"; then
      kbps=$((b / 1000))
      break
    fi
  done
  [ -n "$kbps" ] || kbps="-"

  human_dur="$(awk -v s="$duration" 'BEGIN {
      if (s + 0 <= 0) { print "-"; exit }
      m = int(s / 60); sec = s - m * 60
      printf "%d:%05.2f", m, sec
    }')"

  printf '%-26s %-52s %9s %6s %7s %2s %-5s %10s   %s\n' \
    "$album" "$track" "$human_dur" "$kbps" "${sr:--}" "${ch:--}" "${codec:--}" \
    "$base_size" "$result"
  if [ "$result" = "FAIL" ]; then
    printf '%s\n' "$errs" | sed 's/^/  /' | head -n3
  elif [ -n "$note" ]; then
    printf '  %s\n' "warn: $note"
  fi

  if [ -n "$tsv_fd" ]; then
    tsv_kbps="${kbps#-}"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$f" "${duration:-}" "$tsv_kbps" "${sr:-}" "${ch:-}" "${codec:-}" \
      "$base_size" "$result" "$note" >&"$tsv_fd"
  fi
done

[ -n "$tsv_fd" ] && exec {tsv_fd}>&-

total_sec="$(printf '%.0f' "$dur_total")"
h=$((total_sec / 3600))
m=$(((total_sec % 3600) / 60))
printf '%s\n' "-----------------------------------------------------------------------------------------------------------------------------------------"
printf 'audio audit: %d MP3s, %d fail(s), %d warn(s) — %d:%02d total\n' "$total" "$fails" "$warns" "$h" "$m"
[ -n "$OUT" ] && printf 'baseline written: %s (%d rows)\n' "$OUT" "$total"

[ "$fails" -gt 0 ] && exit 1
exit 0

