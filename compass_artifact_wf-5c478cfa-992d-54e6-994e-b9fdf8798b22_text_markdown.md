# Bouldering Climbing-Assessment App — Complete Buildable Specification

## TL;DR
- **Relative finger strength (half-crimp, %BW on a small edge) is the single dominant predictor of bouldering grade** — Buraas et al. (*European Journal of Applied Physiology*, 2025, n=19 males, redpoint 6b+–8c) found "Very strong and strong associations… between climbing-specific finger strength and bouldering (r = 0.89)"; the Lattice Training boulder dataset (Cameron Hartley, Mar 2025, n=901) found the 7-second max hang "explained 49.6% of the variance in the grade (R² = 0.496)." Finger strength must anchor the model at ~30% weight; max pulling strength (weighted pull-up %BW) is the clear #2 (Lattice R=0.582, R²=0.337).
- Weight the 15 metrics so trainable-physical factors carry ~63%, experience/skill ~14%, and fixed anthropometric traits ~7–8%: finger strength 30%, pulling strength 12%, RFD/contact 6%, lower/upper power 3%, lock-off 4%, power-endurance 4%, finger endurance/critical force 3%, core 5%, hip abduction 3%, hip flexion/high-step 2%, body composition 6%, ape index 2%, bodyweight pull reps 1%, experience 14% (a 15th "edge-tolerance" sub-metric folds into the finger-strength profile).
- Output a **grade RANGE with confidence bands** (not a point estimate), a per-metric percentile radar, an explicit limiting-factor callout, and a "physical ceiling vs experience-typical grade" comparison, mapping a weighted composite to a V-grade via the Lattice finger-strength benchmark curve as the primary anchor and widening the band at elite grades where physical predictors demonstrably lose power.

## Key Findings

### 1. The evidence hierarchy is clear and consistent
Across peer-reviewed studies (Buraas et al. EJAP 2025; the IJSPP 2024 six-grip study; Frontiers reviews) and large coaching datasets (Lattice, n=901 boulderers), the predictor ordering **for bouldering specifically** is: (1) relative finger strength in half-crimp; (2) max relative pulling strength; (3) rate of force development / explosive power; (4) experience/mileage; then body composition, core, and hip mobility as minor contributors; and anthropometry (ape index, height) and pull-up REPS as negligible.

### 2. Finger strength dominates — but its predictive power fades at the elite level
The Lattice bouldering dataset (Cameron Hartley, "How do the predictors for bouldering performance differ between ability levels?", 28 March 2025; 773 male, 98 female, 40 unspecified; grades V1–V15) found the 7-second two-arm max hang on a 20 mm edge "yielded a correlation coefficient (R) of 0.704… The model explained 49.6% of the variance in the grade (R² = 0.496)… F(1, 899) = 885.74, p < 0.001." But when split by ability, finger-strength adjusted R² fell from **0.167** (Advanced V4–V8, "R = 0.411") to **0.099** (Elite V9–V12, "lower R of 0.319") to **0.042** (Higher Elite V13+, "R = 0.225… explains only 4.2% of the variation, p = 0.0187"). The app's physical model is therefore most accurate for roughly V2–V10 and increasingly incomplete above ~V11, where technique/tactics dominate — this must be encoded as widening confidence bands at high grades.

### 3. Pull-up REPS barely matter; max FORCE matters a lot
Muscular-endurance pull-up reps show "no to middle-sized" correlation with climbing ability (systematic reviews), whereas the weighted (2RM) pull-up %BW correlates moderately: Lattice "R = 0.582… The model explained 33.7% of the variance in best boulder worked (R² = 0.337)… F(1, 899) = 459.36, p < 0.001," consistent with the EJAP r=0.55 for pull-up strength. **The app must test maximum added load, not reps.**

### 4. Power-endurance / "pump" resistance is a poor predictor for BOULDERING
Lattice's 60%-max time-to-exhaustion repeaters test correlated essentially zero with boulder grade: "R = 0.007, indicating little to no relationship… R² = -0.001… F(1, 899) = 0.046, p = 0.830." Yet finger-flexor critical force explains ~61% of *sport* and only ~26% of *bouldering* performance (Giles et al. all-out CF study), and Lattice's critical-force-for-sport analysis found R=0.401/R²=0.16. This is a genuine bouldering-vs-sport distinction: give power-endurance a small weight for bouldering, retained mainly for weakness profiling.

### 5. Anthropometry and flexibility are weak; body composition is moderate
Ape index ≈ 0.14 V-grades per inch (a +7-inch ape gains ~1 V-grade; Ben Chan science-fair dataset, n≈669, r/r² small); box-split flexibility for bouldering is weak — Lattice "R = 0.140… R² = 0.020… F(1, 899) = 17.08, p < 0.001." Hip abduction is the strongest mobility signal (Draga et al.: straddle stand r = −0.48, straddle sit r = −0.41). Body fat % correlates moderately negatively (r ≈ −0.42 to −0.49 across body-composition studies; Mermier et al. found anthropometrics explained <1% once strength/endurance were accounted for). BMI is unreliable for climbers because of dense muscle.

### 6. Sex differences: small for relative finger strength, large for pulling
The best large-sample peer-reviewed evidence — Baláš et al. (*Journal of Sports Sciences*, published online 4 Jan 2025; Faculty of Physical Education and Sport, Charles University; **n = 185 male + 122 female**) — found "Finger strength emerged as the dominant factor, explaining the majority of variance in climbing ability (males 68%; females 64%)" and, critically, that relative (body-mass-normalized) finger strength differences "are not significant when the strength is normalized to body mass." Lattice's "perfect climber" standard puts female finger strength only 5 %BW below male (95% vs 100% one-arm hang) but female pulling ~30 %BW below male (135% vs 165% BW for 2 pull-ups) and bench 25% lower (75% vs 100%). **So the app applies a small female offset to finger strength but a large one to pulling.**

## Details

### The Final 15 Metrics — Definitions, Best Tests, Weights, Evidence

| # | Metric | Best self-administered test (protocol) | Units / normalization | Weight | Evidence & correlation |
|---|--------|------------------------------|------------------------|--------|------------------------|
| 1 | **Max finger strength (half-crimp)** | 7-second max dead-hang on a 20 mm edge, strict half-crimp, straight/slightly-bent arms (no 90° lock); warm up, then up to 8 progressive hangs adding/removing load to find max; record best clean hang | %BW = (BW + added)/BW × 100 | 30% | Strongest predictor: Buraas EJAP r=0.89 (on a 22 mm edge); Lattice R=0.704 / R²=0.496; IJSPP 2024 half-crimp R²=0.48–0.58; test–retest ICC 0.78–0.96 |
| 2 | **Max pulling strength** | Weighted pull-up 2RM, pronated shoulder-width grip, full ROM (near-straight arms to chin-over-bar), 3-min rests, add load via harness | %BW = (BW + added)/BW × 100 | 12% | Lattice R=0.582 / R²=0.337; EJAP r=0.55; pull-up 1RM reliability CV=7.7% (Ozimek) |
| 3 | **Rate of force development / contact strength** | Max campus reach: from matched bottom rung, campus one hand to highest reachable rung (1-x); or Tindeq RFD if available | rung # reached (or kg·s⁻¹) | 6% | Distinguishes elite from advanced (Levernier & Laffaye 2019; Stien et al.); power-slap reach r=0.69–0.73, ICC 0.95–0.98 |
| 4 | **Explosive power (upper/lower)** | Max double-dyno / arm-jump distance from jugs, or max campus 1-5-9 progression | rung reached / cm | 3% | Boulderers > lead in all power measures (ES 0.90–1.12, p=0.006–0.023) |
| 5 | **Lock-off strength** | Max 90° bent-arm lock-off hold time, one arm (or weighted two-arm lock-off) | seconds / %BW | 4% | Baláš 2011 r=0.76 (men), 0.80 (women); Tindeq lock-off ICC 0.98 |
| 6 | **Edge tolerance (small-edge finger strength)** | Max hang on a smaller edge (8–10 mm), half-crimp, %BW — profiles finger strength on climbing-relevant micro-edges | %BW | folded into #1 profile | Grip on small edges correlates most strongly with ability (reviews) |
| 7 | **Power-endurance (bouldering-specific)** | Max moves on a benchmark board (MoonBoard/Kilter/Tension) at a fixed sub-max grade, or 7:3 repeaters at 60% max to failure | # moves / seconds | 4% | Bouldering R≈0.007 (weak) — profiling only |
| 8 | **Finger endurance / critical force** | 4-min all-out 7:3 repeaters on 20 mm edge (end-force = CF), or CF pyramid; report CF as %BW | %BW critical force | 3% | Sport R=0.401; bouldering W'/kg R²=0.34; 4-min all-out ICC reliable |
| 9 | **Core strength** | Front-lever progression (tuck → advanced tuck → one-leg → full, max hold time) or L-sit / hanging leg raise | seconds by level (9c ladder) | 5% | Weak–moderate, inconsistent evidence; body-lock-off & superman tests high reliability |
| 10 | **Hip abduction mobility** | Straddle-stand: measure groin (pubic symphysis)-to-floor distance; or box-split heel-to-heel distance | cm, normalized to height | 3% | Straddle stand r=−0.48; straddle sit r=−0.41; box split R=0.14 |
| 11 | **Hip flexion / high-step** | Adapted Grant foot-raise / max high-step height against wall | % leg length (height ÷ leg length × 100) | 2% | Climbing-specific hip flexion moderately correlated; foot-raise higher r than generic tests |
| 12 | **Body composition** | Body-fat % via skinfold or bioimpedance scale (fallback: waist + photo estimate) | % body fat | 6% | r≈−0.42 to −0.49; optimal men 6–12%, women 10–18% (Hörst) |
| 13 | **Ape index** | Arm span − height (also stored as ratio) | cm and ratio | 2% | ~0.14 V-grades/inch; small fixed trait |
| 14 | **Bodyweight pull reps** (secondary) | Max strict bodyweight pull-ups | reps | 1% | Weak (no-to-middle correlation) — profiling |
| 15 | **Experience / mileage** | Composite: years climbing + sessions/week + years/days climbing outdoors | 0–100 experience index | 14% | Among strongest single variables (R²≈0.16); climbing experience explained 42.7% of onsight & 49.5% of redpoint variance (youth study) |

**Bucket totals (sum to 100%):** Trainable physical (1–9, 14) ≈ 68%; body composition (12) 6% (partly trainable); fixed anthropometric (10, 11, 13) ≈ 7%; experience/skill (15) 14% — the small residual is absorbed by renormalization when the user skips tests. Evidence is **strong** for metrics 1, 2 and the sex-difference direction; **moderate** for 3, 5, 12; and an **informed estimate** for 4, 6–11, 13–15 (limited or bouldering-non-specific data — flagged in-app).

### Grade-Benchmark Table — Finger Strength (PRIMARY ANCHOR)

**Male, one-arm-equivalent max hang, 20 mm edge, %BW (7–10 s)** — from the community reverse-engineering of Lattice YouTube data ("Approximating Lattice's Finger Strength Dataset", wmgclimbing, 2024):

| Grade | %BW | Grade | %BW |
|---|---|---|---|
| V4 | 49 | V11 | 91 |
| V5 | 55 | V12 | 96 |
| V6 | 61 | V13 | 101 |
| V7 | 67 | V14 | 106 |
| V8 | 73 | V15 | 110 |
| V9 | 79 | V16 | 114 |
| V10 | 85 | V17 | 118 |

Below V4 (extrapolated at ~6–8%/grade, **high uncertainty**): V3≈43, V2≈37, V1≈31, V0≈25.

**Protocol note (critical for implementation):** the numbers above are *one-arm-equivalent*. Lattice also cite a **two-arm 7-second hang benchmark of ≈128 %BW for V4** (per UKC user reports of Lattice assessments). Because two-arm and one-arm protocols produce very different numbers, the app must **pick ONE test protocol** — the two-arm 7-second hang is safest and easiest for recreational users — and convert internally to the one-arm-equivalent anchor curve (roughly one-arm-equiv ≈ two-arm %BW × ~0.5 plus a bilateral-deficit correction, calibrated against your own data). **Never mix protocols in the same table.**

**Female:** apply the male curve minus ~5 %BW for finger strength (Lattice 95% vs 100% "perfect climber" standard; Baláš/Berta 2025: relative finger strength "not significant when normalized to body mass," so the offset is small and shrinks further at higher grades).

### Grade-Benchmark Table — Weighted Pull-up (2RM, %BW)
Anchored on the 9c strength test (Christophersen & Mobråten) and the Lattice "perfect climber" ceiling (men 2 pull-ups @165 %BW, women @135 %BW). Approximate **male** anchors: V4≈115%, V6≈125%, V8≈140%, V10≈150%, V12≈160%, V14≈165%+ (2RM total load as %BW). **Female:** subtract ~25–30 %BW. These are informed estimates (the 9c test is a coach-derived, not peer-reviewed, mapping) — hold them looser than the finger-strength curve.

### Font ↔ V conversion (dual display)
V0≈4/4+, V1≈5, V2≈5+, V3≈6A/6A+, V4≈6B/6B+, V5≈6C/6C+, V6≈7A, V7≈7A+, V8≈7B, V9≈7C, V10≈7C+, V11≈8A, V12≈8A+, V13≈8B, V14≈8B+, V15≈8C, V16≈8C+, V17≈9A. (Conversions are approximate and community-consensus; widen at the top end.)

### App Logic — Scoring Algorithm

**Step 1 — Normalize each metric to a grade-equivalent (G_i, in V-units).** For metrics with grade tables (finger strength, weighted pull-up), invert the benchmark curve: given the user's measured %BW and sex-adjusted table, linearly interpolate between benchmark rows to get G_i. For metrics without grade tables (core, mobility, body fat, ape, experience), map the raw value to a 0–100 percentile using published normative ranges, then linearly transform that percentile to a grade-equivalent centered on the user's finger-strength anchor grade ± a fixed spread (e.g., percentile 50 → anchor grade; 0 → anchor −3; 100 → anchor +3).

**Step 2 — Composite.** `G_composite = Σ(wᵢ · Gᵢ) / Σ(wᵢ)`, where weights are renormalized over only the metrics the user actually entered (so partial input still yields an estimate, with a wider band).

**Step 3 — Physical ceiling (G_ceiling).** Weighted mean using only trainable-physical + anthropometric metrics (exclude experience). Interpreted as "the grade your body is strong enough for, with perfect technique" — the 9c-test philosophy.

**Step 4 — Predicted / experience-typical grade.** `G_predicted = 0.86·G_ceiling + 0.14·G_experience`. If G_experience ≪ G_ceiling → flag "technique/mileage is your limiter — climb more, especially outdoors." If G_ceiling ≪ G_experience → flag "you climb above your physical numbers; targeted strength gains would raise your ceiling."

**Step 5 — Confidence band.** Base band = ±1 V-grade (reflecting best-predictor R²≈0.5). Widen by: (a) **+0.5 grade per V above V10** (encodes the measured decline in R² at Elite/Higher-Elite); (b) **+0.25 grade per missing high-weight metric**; (c) a term proportional to the **standard deviation of the Gᵢ** (high scatter across metrics → less certain). Output `[G_predicted − band, G_predicted + band]` with a "most likely" midpoint.

**Step 6 — Limiting-factor detection.** For each metric compute `deficit_i = G_ceiling − G_i`. The metrics with the largest positive deficits are the weaknesses; largest negatives are strengths. Surface the top 1–3 weaknesses as actionable callouts.

**Step 7 — Per-metric percentile.** Percentile = the user's Gᵢ relative to the reference distribution at their predicted grade (benchmark tables + normative SDs as the reference).

### App Design / UX

**Screen structure**
1. **Onboarding / Profile:** sex, age, bodyweight, height, arm span (auto-computes ape index), unit toggles (kg/lb, cm/in), grade-scale toggle (V/Font).
2. **Test hub (dashboard):** one card per metric, grouped into Fingers · Pull/Power · Core · Mobility · Body · Experience; each card shows status (untested / value) and a "How to test" button opening an instruction sheet (protocol text + diagram/animation + safety note).
3. **Per-test input screens:** numeric entry with the exact protocol shown; built-in **hang timer** for timed tests; a **load calculator** (enter added/removed kg → auto %BW); an edge-size + grip-type selector for finger tests; and a "Did you hit true max?" confidence toggle that feeds the band width.
4. **Results screen:**
   - Large **grade estimate with range** ("V6–V8, most likely V7") in both V and Font.
   - **Radar/spider chart** across metric axes (each axis = 0–100 percentile).
   - **Level bars** per metric, color-coded (red = weakness, yellow = at-level, green = strength).
   - **Physical-ceiling vs experience-typical** dual marker on a horizontal grade axis.
   - **Weakness callout** cards ("Your fingers support V8 but your pulling strength sits at V5 — your #1 limiter").
   - Retest reminder + progress-history sparkline.
5. **History / progress:** time-series per metric and predicted grade over time.

**Data model (core entities)**
- `User { id, sex, birthdate, heightCm, armSpanCm, unitPrefs, gradeScalePref }`
- `BodyMeasurement { id, userId, date, weightKg, bodyFatPct }`
- `TestResult { id, userId, metricId, date, rawValue, unit, addedLoadKg, computedPctBW, edgeSizeMm, gripType, confidenceFlag }`
- `MetricDef { id, name, protocolText, diagramRef, weight, bucket, benchmarkTable, normativeRanges }`
- `Assessment { id, userId, date, gradeComposite, gradeCeiling, gradeExperience, confidenceLow, confidenceHigh, perMetricPercentiles[], limitingFactors[] }`

**Pure functions to implement:** `pctBWFromLoad(bw, added)`, `gradeFromBenchmark(metric, value, sex)`, `percentileToGrade(pct, anchorGrade)`, `compositeGrade(metricGrades[], weights[])`, `confidenceBand(predicted, missingCount, gradeSpread)`, `limitingFactors(ceiling, metricGrades[])`, `vToFont()` / `fontToV()`.

## Recommendations

**Stage 1 (MVP).** Build the 4-metric core — finger strength (2-arm 20 mm hang), weighted pull-up 2RM, one core test (front-lever/L-sit ladder), one hip-abduction test (straddle-stand) — mirroring the validated Lattice 4-test battery and the 9c test. This captures the majority of predictable variance. Ship the grade-range output, radar, and weakness callout, anchored on the sex-adjusted finger-strength curve. **Benchmark to advance:** if predicted grade lands within ±1 grade of users' self-reported max sends for ≥70% of testers, proceed to Stage 2.

**Stage 2.** Add RFD/campus reach, lock-off, body-fat estimate, the experience index, and the physical-ceiling-vs-experience comparison. Add board-based power-endurance (MoonBoard/Kilter max-moves). **Benchmark:** if adding these narrows the mean prediction error, keep them; if not, demote to profiling-only.

**Stage 3.** Add progress tracking, retest scheduling, and optional **force-sensor integration** (Tindeq/Griptonite) for finger strength, RFD and lock-off (Tindeq ICC 0.99, CV ≤10%) — this materially improves data quality and should become the recommended path for metrics 1/3/5.

**Trigger to recalibrate:** treat the Lattice/9c curves as *priors, not ground truth*. Once you accumulate ≥500 users with self-reported sends, refit the benchmark offsets (especially the two-arm↔one-arm conversion and the female offsets) against your own data. If self-administered max tests prove unreliable, gate metrics 1/3/5 behind a force sensor.

## Caveats
- The finger-strength benchmark table (V4–V17) is a **community reverse-engineering of Lattice YouTube data, not an official peer-reviewed table**; below V4 it is extrapolated with high uncertainty. The Buraas EJAP r=0.89 figure comes from a small sample (n=19) and was measured on a **22 mm edge, not 20 mm** — a reason to hold the correlation as directional, not exact.
- Physical models explain at most ~50% of bouldering-grade variance and **progressively less above V11** (adjusted R² falls to ~0.04 at V13+). The app cannot measure technique, tactics, or psychology, which dominate at the elite level. Always present ranges; never imply false precision.
- The 9c/Lattice batteries were validated primarily on **advanced-to-elite male climbers**; granular female V-grade tables do not exist publicly. The app uses offset factors (small for fingers ≈ 5 %BW, large for pulling ≈ 25–30 %BW) as the best available proxy, per Baláš/Berta 2025 and the Lattice "perfect climber" standards.
- Power-endurance and general flexibility have **near-zero correlation with BOULDERING grade specifically** (Lattice R=0.007 and R=0.140 respectively); they are included for weakness-profiling, not because they move the grade estimate much. Do not let them dominate the composite.
- The weighted-pull-up grade table is coach-derived (9c test + Lattice ceiling), not peer-reviewed — flag it as lower-confidence than the finger-strength anchor.
- Self-administered max tests carry real injury risk (finger pulleys, shoulders); every protocol must include mandatory warm-up guidance, a "stop if sharp pain" rule, and a safety disclaimer before first use.