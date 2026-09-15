# The Hollow — Repository Issues

*Full review conducted 2026-09-15. Scope: all tracked content in `The-Hollow` (prose, lyrics, audio, docs, scripts, CI), with verification via `scripts/check-parity.sh` (exit 0), `AUDIO-BASELINE.tsv`, and cross-referencing of `README.md`, `CANON.md`, `SPOILERS.md`, `CAPTIONS.md`, and `.private/MEMORY.md`.*

---

## Summary

The repository is in **excellent mechanical health**: `scripts/check-parity.sh` passes clean (10 albums, **147 tracks**, full MD↔MP3 parity, complete ID3 tag layer, no banned canon values, count-lock present, LF-only text). The issues below are almost entirely **documentation drift** and **content-coverage gaps** that accumulated after the Dawn-of-the-Void bonus tracks (16–35) were added — plus one naming inconsistency and several stale references.

**Status: all issues fixed and pushed (commit on `main`).** No blockers, no canon breaks, no audio-integrity problems remain.

---

## Canon-drift / P0-style items (register)

*The designated home for canon discrepancies and potential updates, per `CANON.md`: "If a track or a re-read ever contradicts this document, this document is the source of truth and the discrepancy belongs in `ISSUES.md` as a P0-style item."*

**How to use this register:**
1. Add a candidate below in P0-style format — severity, the canon it conflicts with, the evidence, and the proposed fix.
2. Leave it here until the conflict is *verified and resolved*.
3. When promoted into canon, update `CANON.md` (and `scripts/check-parity.sh` if the rule is machine-enforced), then mark the item **RESOLVED** with the commit that closed it.

**P0-style template:**

```markdown
### [P0|P1|P2] — Short title of the discrepancy
- **Status:** OPEN / RESOLVED
- **Found:** YYYY-MM-DD
- **Canon source of truth:** (which CANON.md section this conflicts with)
- **Where it appears:** (album / track / file / line)
- **The discrepancy:** (what the track or re-read says vs. what canon says)
- **Evidence:** (quote the offending text and the canonical text)
- **Proposed fix:** (what to change, and in which file(s); whether check-parity.sh must change)
- **Resolved in:** (commit hash, once resolved)
```

### Register

#### P2 — "Six points" wrinkle in The-Hollow-Destroyed (flagged in canon, not yet enforced)

- **Status:** OPEN
- **Found:** 2026-08-28 (flagged in CANON.md §"Known wrinkles")
- **Canon source of truth:** `CANON.md` → "The arithmetic lock" (§ item 3: the star has exactly four points and wants exactly one fifth — never three, five, or six star-points among the coven)
- **Where it appears:** `The-Hollow-Destroyed/13 - Lumawig's Blade.md` (outro), and the Restoration prose's closing summary table "The Six Points" (in `The-Hollow-Destroyed/The-Hollow-Destroyed.md`)
- **The discrepancy:** The outro sings "Six points of the star / Six women made whole," and the prose names six women (Lina, Marisol, Tess, Jo, Dalisay, Ulan) as "The Six Points" — read per canon as four points + the fifth (Dalisay, the center) + Ulan (the living proof), *not* six star-points. The count itself ("ten, eleven, twelve, and one to come") is unaffected.
- **Evidence:** `The-Hollow-Destroyed/13 - Lumawig's Blade.md` — "Six points of the star / Six women made whole"; `The-Hollow-Destroyed.md` §"The Six Points"
- **Proposed fix:** Leave as-is while the canon reads it as "the new constellation of the healed" (SPOILERS.md §12). Only reconcile the literal "six points" language if track 13 is ever touched for another reason. No `check-parity.sh` change needed (not machine-enforced).
- **Resolved in:** — (OPEN)

*(No other open items — add the next one above when a conflict is found.)*

---

## Issues

### M1 — Track-count and runtime claims are stale (127 → 147 tracks) ✅ RESOLVED

**Severity:** Medium
**Affected:** `README.md`, `.private/MEMORY.md`

The repo now ships **147 tracks** (10 albums, verified by `check-parity.sh`), but two places still claimed **127 tracks ≈ 7h05m**:

- `README.md:53` — `Full saga runtime: **≈7h 05m across 127 tracks** (measured 2026-08-27)`
- `README.md:221` — `...ten albums, 127 tracks, seven hours.`
- `.private/MEMORY.md:28` — `Full saga: **127 tracks, ≈7h05m** (measured 2026-08-27).`

The 20 missing tracks were the **Dawn-of-the-Void bonus tracks (16–35)**, and the stated runtime was stale.

**Fix applied:** Re-measured total runtime via full `audio-audit.sh` decode (147 MP3s, **8h 33m**, 0 fails, 0 warns) and updated `README.md` (line 53 → `≈8h 33m across 147 tracks (measured 2026-09-15)`; line 221 → `147 tracks, over eight and a half hours`; Dawn table row → `35 (15 + 20 bonus)` ≈2h 32m) and `.private/MEMORY.md` (line 28 + Dawn table row). Also refreshed the `~7h05m` note in `scripts/audio-audit.sh` header.

---

### M2 — `AUDIO-BASELINE.tsv` was missing the 20 Dawn-of-the-Void bonus tracks ✅ RESOLVED

**Severity:** Medium
**Affected:** `AUDIO-BASELINE.tsv`

The audio-integrity baseline recorded **127 rows**; the repo holds **147 MP3s**. The 20 tracks absent were exactly the Dawn-of-the-Void bonus tracks 16–35.

**Fix applied:** Re-ran `scripts/audio-audit.sh -o AUDIO-BASELINE.tsv` over the full tree — **147 rows**, 0 fails, 0 warns, total 8h 33m. (Optional future hardening: teach `check-parity.sh` to diff baseline vs. MP3 inventory.)

---

### L1 — Canon-referenced `_POTENTIAL-UPDATES/` folder did not exist ✅ RESOLVED (folder removed)

**Severity:** Low
**Affected:** `CANON.md`, repo root

`CANON.md:127` instructed contributors that any canon discrepancy "belongs in `_POTENTIAL-UPDATES/_POTENTIAL-UPDATES.md` as a P0-style item," but no such folder existed.

**Fix applied (2026-09-15):** The `_POTENTIAL-UPDATES/` folder (and its `_POTENTIAL-UPDATES.md`) was **deleted** per Ely's decision — canon-drift notes now live directly in **this file (`ISSUES.md`)**. `CANON.md` now points discrepancies at `ISSUES.md` as P0-style items; all `_POTENTIAL-UPDATES` references were removed from `.gitignore`, `README.md`, and the `SKIP`/exclusion lists in `scripts/check-parity.sh`, `scripts/tag.sh`, and `scripts/audio-audit.sh`.

---

### L2 — `.github/MEMORY.md` was referenced but the memory actually lives in `.private/` ✅ RESOLVED

**Severity:** Low
**Affected:** `README.md`, `CANON.md`

Three documents referenced a tracked `.github/MEMORY.md`, but the actual AI workspace memory is the gitignored `.private/MEMORY.md` (per the 2026-09-14 convention).

**Fix applied:** Updated `README.md` (lines 81, 83) and `CANON.md` (line 3) to say the AI working memory lives in the gitignored `.private/MEMORY.md`, and removed the stale "tracked normally" / "except workflows and MEMORY.md" language.

---

### L3 — "Dalisy" misspelling of "Dalisay" in three bonus-track files ✅ RESOLVED

**Severity:** Low
**Affected:** `Dawn-of-the-Void/`

The canonical spelling is **Dalisay**. Three files in the Dawn bonus-track block misspelled it as **Dalisy**:

- `Dawn-of-the-Void/20 - [Bonus Track] The Hollow's Lullaby.md` — 3 occurrences (lyrics)
- `Dawn-of-the-Void/21 - [Bonus Track] Dalisy's Menstrual Blood.md` — 9 occurrences, **including the filename** (both `.md` and `.mp3`)
- `Dawn-of-the-Void/26 - [Bonus Track] The Garden of Names.md` — 12 occurrences (dialogue `*Dalisy:*`)

**Fix applied:** Renamed track 21's `.md`/`.mp3` pair to `Dalisay's Menstrual Blood` (via `git mv`), corrected all 24 in-text occurrences, re-ran `scripts/tag.sh --album Dawn-of-the-Void` to fix the ID3 `TIT2` title and re-embed corrected `USLT` lyrics, and updated the matching row in `AUDIO-BASELINE.tsv`. `grep` confirms zero `Dalisy` remains.

---

## Lower-priority observations (not filed as issues)

- **CAPTIONS.md only covers Dawn-of-the-Void tracks 01–15.** The 20 bonus tracks (16–35) have no captions. Purely additive work; not a defect. (1 "Bonus" mention exists but is unrelated.)
- **`The-Hollow.html` and `The-Hollow.pdf` predate the bonus tracks** (Aug 29) and the saga-wide montage/README edits — they are regenerable exports and may be out of date. Regenerate if the exports are meant to include the full 147-track saga.
- **`Dawn-of-the-Void/Dawn-of-the-Void.md` (the story) makes no mention of the bonus tracks** — no reference to tracks 16–35. Likely intentional (bonus material), but worth a one-line note if the story doc is meant to be exhaustive.

---

## Verification record

- `scripts/check-parity.sh` → **exit 0**, all 10 albums OK, 147 tracks, tag layer complete, text layer clean.
- MD↔MP3 base-name parity: **10/10 albums OK**.
- Per-album track counts: Red Hollow 10 · Amuyao 12 · Unholy Blood 12 · Permanent Season 13 · Solitary Path 12 · Hollow Destroyed 17 · Cebu 12 · Eleventh Figure 12 · Bloodlines 12 · Dawn of the Void 35.
- `AUDIO-BASELINE.tsv`: **147 rows** matching 147 MP3s on disk (0 missing, 0 extra), 0 fails, 0 warns, **8h 33m** total (re-audited 2026-09-15).
- Working tree clean; `main` pushed.
- Only stale-value check: none found in lyrics (banned values absent, count-lock line present).

---

*Compiled for Ely by the repo-review pass. All five issues fixed, verified, and pushed — this document is kept as the record of the review.*
