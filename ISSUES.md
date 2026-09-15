# The Hollow — Repository Issues

*Full review conducted 2026-09-15. Scope: all tracked content in `The-Hollow` (prose, lyrics, audio, docs, scripts, CI), with verification via `scripts/check-parity.sh` (exit 0), `AUDIO-BASELINE.tsv`, and cross-referencing of `README.md`, `CANON.md`, `SPOILERS.md`, `CAPTIONS.md`, and `.private/MEMORY.md`.*

---

## Summary

The repository is in **excellent mechanical health**: `scripts/check-parity.sh` passes clean (10 albums, **147 tracks**, full MD↔MP3 parity, complete ID3 tag layer, no banned canon values, count-lock present, LF-only text). The original review found 5 issues (all fixed). **A follow-up deep review (2026-09-15) surfaced 4 additional findings** (M3–M5, L4) — three canon/consistency items in the newest bonus content and the Bloodlines birth-year data, one stale count reference in SPOILERS, and one caption-coverage gap. No blockers; the mechanical gate remains green.

**Status:** All original + follow-up issues resolved and pushed (M1–M5, L1–L4, P0–P1). Only the intentional P2 "Six points" wrinkle remains open (by design).

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

#### P0 — "Four Bleeding Testimonies" (Dawn 22) assigns the four women non-canon ages

- **Status:** RESOLVED
- **Found:** 2026-09-15 (deep-review pass, ISSUES.md M3)
- **Canon source of truth:** `CANON.md` → "The arithmetic lock" (§ rule 4: never invent a new age for Lina, Marisol, Tess, Jo, Ulan, or Dalisay; Lina 46 / b.1979, Jo 47 / b.1978 pinned)
- **Where it appears:** `Dawn-of-the-Void/22 - [Bonus Track] Four Bleeding Testimonies.md` — voice-direction labels `[Voice 1: LINA - Age 34]`, `[Voice 2: MARISOL - Age 29]`, `[Voice 3: TESS - Age 24]`, `[Voice 4: JO - Age 19]`
- **The discrepancy:** The four are canonically 44–47 in 2025 (birth years 1979/1980/1981/1978); the track's voice notes aged them 19–34 with no in-track dating as a flashback. Same class as the P0 age leak that shipped once before.
- **Evidence:** `CANON.md:44` (Lina 46 b.1979, Jo 47 b.1978); `The-Red-Hollow-of-Kentucky.md` (Lina 46, Marisol 45, Tess 44, Jo 47); `Bloodlines.md` table (b.1979/1980/1981/1978) vs the track's voice labels.
- **Proposed fix:** Correct the voice-direction ages to the pinned canon ages (Lina 46, Marisol 45, Tess 44, Jo 47).
- **Resolved in:** commit `…` (2026-09-15; voice labels corrected, MP3 re-tagged)

#### P1 — Bloodlines birth-year ordering conflicts (header vs table vs CANON)

- **Status:** RESOLVED
- **Found:** 2026-09-15 (deep-review pass, ISSUES.md M4)
- **Canon source of truth:** `CANON.md` → "The arithmetic lock" (§ rule 4, ages); the four birth years are implied by the pinned ages (Lina b.1979, Jo b.1978)
- **Where it appears:** `Bloodlines/Bloodlines.md` — header "The girls — 1978, 1979, 1980, 1981" and prose "1978, 1979, 1980, 1981" vs the album's own table (Lina b.1979, Marisol b.1980, Tess b.1981, Jo b.1978)
- **The discrepancy:** The header/prose sequence implied Lina=1978, Marisol=1979, Tess=1980, Jo=1981, but the table assigned Lina=1979, Marisol=1980, Tess=1981, Jo=1978. The table also made Jo the oldest (b.1978) while she's written as the gentle, "widowed too young" youngest-feeling of the four. Red Hollow story states ages Lina 46, Marisol 45, Tess 44, Jo 47 — consistent with the *table* (1979/1980/1981/1978 in 2025) but inconsistent with the header sequence.
- **Evidence:** `Bloodlines.md` §"PART SIX: THE COUNTING OF FOUR" (header + prose) vs §table (lines 169–172); `CANON.md:44`; `The-Red-Hollow-of-Kentucky.md` (ages 46/45/44/47).
- **Proposed fix:** Reconcile header/prose (and the `Bloodlines/11 - The Counting of Four.md` intro) to the authoritative table: Lina 1979, Marisol 1980, Tess 1981, Jo 1978.
- **Resolved in:** commit `…` (2026-09-15; header, prose, and track-11 intro corrected; MP3 re-tagged)

*(Open register items: P2 "Six points" wrinkle. P0 and P1 resolved 2026-09-15. Add the next item above when a conflict is found.)*

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

## Follow-up review — 2026-09-15 (deeper canon/story/file pass)

*A second, deeper pass focused on canon consistency, story-level details, and file coverage. `check-parity.sh` still exits 0; the issues below are content/canon/coverage findings not caught by the mechanical gate.*

### M3 — "Four Bleeding Testimonies" (Dawn 22) voice-direction ages contradict canon ✅ RESOLVED

**Severity:** Medium
**Affected:** `Dawn-of-the-Void/22 - [Bonus Track] Four Bleeding Testimonies.md`

The track's voice-direction labels assigned the four women ages that contradicted the pinned canon:

- `[Voice 1: LINA - Age 34 ...]`
- `[Voice 2: MARISOL - Age 29 ...]`
- `[Voice 3: TESS - Age 24 ...]`
- `[Voice 4: JO - Age 19 ...]`

But canon (CANON.md:44, and the Red Hollow story) pins the four at **Lina 46, Marisol 45, Tess 44, Jo 47** in 2025 (birth years 1979/1980/1981/1978). The track was framed as a "testimony" but did not date itself as a flashback to their youth, so the ages read as a canon conflict. These were production/voice-direction notes (not spoken lyrics), but per CANON rule 4 ("never invent a new age for Lina, Marisol, Tess, Jo, Ulan, or Dalisay") they conflicted.

**Fix applied (2026-09-15):** Corrected the four voice-direction labels to the pinned canon ages — **Lina 46, Marisol 45, Tess 44, Jo 47** — and removed the "young woman's voice" / "youngest but most certain" descriptors tied to the wrong ages. Re-ran `tag.sh --album Dawn-of-the-Void` so the MP3's embedded `USLT` frame reflects the corrected lyrics. `grep` confirms zero stale ages remain.

---

### M4 — Bloodlines birth-year inconsistency (header vs table) ✅ RESOLVED

**Severity:** Medium
**Affected:** `Bloodlines/Bloodlines.md`

The section header and prose said the girls were born "**1978, 1979, 1980, 1981**" (implying Lina=1978, Marisol=1979, Tess=1980, Jo=1981 in order), but the album's own table assigned:

- **Lina** (b. 1979)
- **Marisol** (b. 1980)
- **Tess** (b. 1981)
- **Jo** (b. 1978)

The table's ordering contradicted the header sequence. The table made **Jo b.1978 the oldest** (47 in 2025, matching CANON's "Jo (47, b.1978)"), yet she's described as "widowed too young" and is the gentle/youngest-feeling of the four — while the prose "1978, 1979, 1980, 1981" sequence would have made **Lina the oldest (b.1978)**, conflicting with the table's Lina b.1979 and CANON's Lina b.1979. The four age/birth data points (Red Hollow story, Bloodlines header, Bloodlines table, CANON.md) did not agree.

**Fix applied (2026-09-15):** Made the header and prose match the authoritative table — **Lina b.1979, Marisol b.1980, Tess b.1981, Jo b.1978** — in Lina-first presentation order, and removed the "one hour apart in history" line that conflicted with the 4-year spread. Also corrected the matching spoken-intro lyric in `Bloodlines/11 - The Counting of Four.md` (the "1978, 1979, 1980, 1981 — four children in four hospitals, an hour apart" intro) to the same canon ordering, and re-ran `tag.sh --album Bloodlines` so the MP3's `USLT` frame reflects the corrected lyrics. `grep` confirms zero stale birth-year sequences remain.

---

### M5 — CAPTIONS.md missing the 20 Dawn-of-the-Void bonus tracks (16–35) ✅ RESOLVED

**Severity:** Medium
**Affected:** `CAPTIONS.md`

`CAPTIONS.md` had **127 caption entries**; the saga has **147 tracks**. The gap was exactly the **20 Dawn-of-the-Void bonus tracks (16–35)** — the Origin section stopped at track 15. All other albums' captions matched their track counts exactly (Red Hollow 10, Amuyao 12, Unholy Blood 12, Permanent Season 13, Solitary Path 12, Hollow Destroyed 17, Cebu 12, Eleventh Figure 12, Bloodlines 12, Dawn 15). Previously listed as a "lower-priority observation," it was filed as an issue since the bonus tracks are committed content and the captions document is meant to "keep the count live."

**Fix applied (2026-09-15):** Wrote 20 captions in the existing style for tracks 16–35 (each written from that track's own title + lyrics) and appended them to the Dawn section. CAPTIONS.md now has **147 captions** matching **147 tracks**, with per-album counts equal across all 10 albums. LF-only preserved; `check-parity.sh` remains exit 0.

---

### L4 — SPOILERS.md still says "127 tracks" (stale count) ✅ RESOLVED

**Severity:** Low
**Affected:** `SPOILERS.md:96`

`SPOILERS.md:96` still read "ten albums, **127 tracks**, 'one unbroken count'" — the same stale count fixed in README/MEMORY during the M1 pass, but missed here. Should read **147 tracks**. (`grep` confirmed it was the only remaining "127 tracks" in tracked non-ISSUES content.)

**Fix applied (2026-09-15):** Changed "127 tracks" → **"147 tracks"** at `SPOILERS.md:96`.

---

## Lower-priority observations (not filed as issues)

- **`The-Hollow.html` and `The-Hollow.pdf` predate the bonus tracks** (Aug 29) and the saga-wide montage/README edits — they are regenerable exports and may be out of date. Regenerate if the exports are meant to include the full 147-track saga. (Left as-is per Ely's decision during the `.temp` cleanup.)
- **`Dawn-of-the-Void/Dawn-of-the-Void.md` (the story) makes no mention of the bonus tracks** — no reference to tracks 16–35. Likely intentional (bonus material), but worth a one-line note if the story doc is meant to be exhaustive.
- **README cast gives Tess "forty-four" and the Red Hollow story gives Marisol "forty-five"** — these match the Bloodlines table (b.1981 / b.1980) and are internally consistent with the story's ages; the only true conflict is the header-vs-table birth-year ordering in M4.
- **The `[` ghost file** — two no-op "Updated" commits (85becb8, 86a8570) reference a file literally named `[` with no content; it does not exist on disk and is not tracked. Harmless artifact of an empty commit; can be ignored.

---

## Verification record

- `scripts/check-parity.sh` → **exit 0**, all 10 albums OK, 147 tracks, tag layer complete, text layer clean.
- MD↔MP3 base-name parity: **10/10 albums OK**.
- Per-album track counts: Red Hollow 10 · Amuyao 12 · Unholy Blood 12 · Permanent Season 13 · Solitary Path 12 · Hollow Destroyed 17 · Cebu 12 · Eleventh Figure 12 · Bloodlines 12 · Dawn of the Void 35.
- `AUDIO-BASELINE.tsv`: **147 rows** matching 147 MP3s on disk (0 missing, 0 extra), 0 fails, 0 warns, **8h 33m** total (re-audited 2026-09-15).
- Working tree clean; `main` pushed.
- Only stale-value check: none found in lyrics (banned values absent, count-lock line present).
- Follow-up canon scan: no new banned values in bonus-track lyrics; the "Four Bleeding Testimonies" age labels (M3) and Bloodlines birth-year ordering (M4) are the canon conflicts found; count line intact everywhere.

---

*Compiled for Ely by the repo-review pass. All five issues fixed, verified, and pushed — this document is kept as the record of the review.*
