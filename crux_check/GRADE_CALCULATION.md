# How the grade estimate is calculated

A walkthrough of what actually happens between "user records a test" and "app
shows a V-grade". Everything here is read off the code, not the spec — where
the two disagree, this file follows the code.

Main files:

| File | Role |
|---|---|
| `lib/state/app_state.dart` | Collects recorded results into raw values |
| `lib/logic/assessment_calculator.dart` | The pipeline below, start to finish |
| `lib/logic/scoring_engine.dart` | Pure maths helpers, no state |
| `lib/data/benchmarks.dart` | The two grade↔strength curves |
| `lib/data/metric_definitions.dart` | Weights, buckets, normative ranges |

## The short version

Finger strength is converted to a V-grade through a lookup curve to give the
**anchor**. The three **Tier 1**
metrics are combined with a **Softmin** — a smooth minimum — so the weakest one
sets the ceiling instead of being averaged away. Everything else is **Tier 2**
and only nudges that ceiling by a multiplier. Experience scales the result on a
bounded log curve.

The governing idea is Liebig's law: performance is set by the scarcest
resource, not the average one. A climber with V12 pulling and V4 fingers
climbs near V4, because elite pulling cannot be applied to a hold the fingers
will not hold.

## Step 0 — Gathering inputs

`AppState._rawValuesForCalculator()` builds a `Map<MetricId, double>`:

- `fingerStrength` and `pullingStrength` use `computedPctBW`, everything else
  uses `rawValue`.
- `bodyComposition` comes from the latest body measurement, not a test result.
- `apeIndex` is auto-filled by the calculator from the user profile.

No size correction is applied. An allometric one (`pctBW × (m/70)^0.33`)
was tried and removed: the physics is right — muscle force scales with
cross-section, so a heavier climber at equal %BW is relatively stronger — but
the correction cannot be fed into these particular tables.

`pullUpPctBWMale` and the finger curve are **%BW observed at each grade across
climbers of all body masses**. They were never normalised to a 70 kg
reference, so converting a climber's %BW to a "70 kg-equivalent" and then
looking it up compares a size-corrected number against an uncorrected
distribution. The effect was not small: the same 134 %BW pull read V5.8 at
55 kg and V10.2 at 100 kg — a 4.4-grade spread for identical relative
strength, worst on pulling because that curve is flattest (5 %BW per grade).

There is also a climbing-specific argument. Allometric scaling measures
muscular quality independent of size, but climbing means lifting *your own
mass*; %BW is much closer to the quantity that decides whether you get up the
wall. Reinstating a correction would mean rebuilding both benchmark tables
from size-corrected source data, which the published numbers do not support.

### Insufficient data

Ape index auto-fills, so a non-empty input map is *not* the same as "something
was tested". If every present value is in `_unscoredMetrics`, the result is
flagged `insufficientData` and `AppState.livePreview` returns `null`, which
drives the existing "No estimate yet" empty state.

## Step 1 — The anchor grade

```
if fingerStrength exists:
    oneArmEquiv = pctBW * 0.5 - 15          # twoArmToOneArmEquiv
    anchor      = invert(fingerStrengthCurve, oneArmEquiv)
elif pullingStrength exists:
    anchor      = invert(pullUpCurve, pctBW)
else:
    anchor      = 5.0        # anchorIsFallback = true
```

`gradeFromBenchmarkTable` inverts a grade→value table by linear interpolation,
and linear **extrapolation** past either end. Female values are the male curve
minus an offset. Both curve sets are documented in `benchmarks.dart` as
**priors, not ground truth**.

## Step 2 — Per-metric grade equivalents

**Path A — the two metrics with real curves** (`fingerStrength`,
`pullingStrength`): read straight off their benchmark table.

Pulling strength is then **plateaued**:

```
plateauPullingGrade(g) = g <= 10 ? g : 10 + (g - 10) * 0.4
```

Above roughly V10 (≈160–165 %BW male, 135–140 female) average pulling barely
moves across four grades of real progression, so extra pulling force stops
buying grades.

**Path B — everything else**: scored relative to the anchor.

```
percentile = normativeRange.percentileFor(raw)      # 0..100, clamped
grade_i    = anchor + (percentile - 50) / 50 * 3
```

Percentile 50 → the anchor; 0 → anchor − 3; 100 → anchor + 3. Every path-B
metric is therefore bounded to anchor ± 3 grades. The normative range **is**
the whole calibration for these — a wrong range silently biases everything,
which is exactly what the old campus range (`2→9`) did.

## Step 3 — The ceiling: Softmin over Tier 1, modified by Tier 2

**Tier 1** — the metrics with enough independent predictive validity to cap a
grade on their own:

| Tier 1 | Weight |
|---|---|
| Finger strength | 30 |
| Pulling strength | 12 |
| RFD / contact | 6 |

```
J = Σ wᵢ·xᵢ·exp(-β·xᵢ) / Σ wⱼ·exp(-β·xⱼ)        β = 0.5
```

β is the temperature: 0 collapses to the weighted mean, larger approaches a
hard minimum. At 0.5 the canonical case — V12 / V12 / V4 — gives **4.28**,
where a weighted mean gives **9.33**. Computed factored around the smallest
grade so the exponentials stay in (0, 1] and cannot overflow.

**Tier 2** — everything else in a ceiling bucket. These become multipliers, not
grades:

```
tier2Multiplier(percentile) = 0.90 + (percentile / 100) * 0.20
```

so an average result changes nothing, and the aggregate is the **weighted mean**
of the individual multipliers — not their product, which would run to the
bounds on any lopsided profile.

```
ceiling = softmin(Tier 1) * tier2Factor
```

Tier 2 is: min edge, lock-off, explosive power, core, hip abduction, hip
flexion, body fat, pull-up reps. Excluded entirely: **power-endurance**
(weight 0) and **ape index** (unscored — see below).

## Step 4 — Experience

```
experienceMultiplier(idx) = 0.92 + log10(1 + 9·idx/100) * 0.13
predicted = ceiling * experienceMultiplier(experienceIndex)
```

Bounded to **0.92 … 1.05**, log-shaped so the first seasons count for far more
than the tenth. Experience optimises the application of physical traits; it
does not generate force, so it scales the ceiling rather than being averaged
against it — and the bounds mean it can never overwrite a physical bottleneck.
No experience recorded → `predicted == ceiling`.

## Step 5 — Confidence band

```
band  = 1.0
band += (predicted - 10) * 0.5     if predicted > 10
band += 0.25 * (missing high-weight metrics)
band += 0.15 * (low-confidence metrics that are scored)
band += 0.30 * stdDev(Tier 1 grade-equivalents)

low  = clamp(predicted - band, 0, 17)
high = clamp(predicted + band, 0, 17)
```

Scatter is measured across **Tier 1 only** — those are the grades that are
supposed to agree, and disagreement between them is what genuinely makes a
prediction uncertain.

## Step 6 — Limiting factors

```
reference  = weighted mean of all scored grade-equivalents
deficit_i  = reference - grade_i
keep deficit > 0.25, sort descending, take top 3
```

Measured against the weighted **mean**, not the Softmin ceiling. The ceiling
already sits down at the weakest metric, so comparing against it would surface
nothing — the deficit that matters is the one dragging the Softmin down.

⚠️ **The limiter card overstates this.** It reads "X is holding you back by
about N grades", where N is `deficit_i`. That is how far the metric sits below
your average, not what fixing it would gain you, and under a Softmin the two
diverge badly: a Tier 2 metric is a multiplier bounded to 0.90–1.10, so fixing
it can never be worth the grades the card claims, while the true bottleneck is
usually worth more. The replacement — ranking by a counterfactual re-score
instead — is specified as Steps 8–10 under "Weakness Analysis" in the project
spec, and is not built yet.

## Step 7 — Display percentiles

Where a normative range exists, the **raw normative percentile is reported
as-is**, so the bars show standing in the climbing population rather than
standing relative to your own predicted grade.

The two table-scored anchors have no normative range and keep the
grade-relative reading:

```
displayed = clamp(50 + (grade_i - predicted) / 3 * 50, 0, 100)
```

## Worked example

Male, 20 mm two-arm max hang at 150 %BW, core level 6.

```
1. oneArmEquiv = 150 * 0.5 - 15 = 60
   curve: V5 = 55, V6 = 61  ->  anchor = 5 + (60-55)/(61-55) = 5.833

2. core 6 of 9 -> 66.7th pct -> 5.833 + (66.7-50)/50*3 = 6.833

3. Tier 1 = {fingers 5.833}          -> softmin = 5.833
   Tier 2 = {core -> 0.90 + 0.667*0.20 = 1.033}
   ceiling = 5.833 * 1.033 = 6.028

4. no experience -> predicted = 6.028

5. band = 1.0 + 0.25*3 (missing pulling/RFD/bodyfat) + 0.30*0
```

Reported as roughly **V6, V4–V8**.

## Things worth knowing

1. **RFD is Tier 1 but not fully independent.** It has no grade table of its
   own, so its grade is derived *from* the anchor via a normative percentile
   and is bounded to anchor ± 3. It works as a bottleneck detector ("contact
   strength lags your fingers") but cannot express "V4 contact with V12
   fingers". Making it a true anchor needs a campus-rung → V-grade table that
   does not exist yet. It also means finger strength weakly double-counts,
   once directly and once as the base of RFD's grade.

2. **Two metrics out of fourteen carry real grade tables.** Remove finger
   strength and pulling strength and the app has no absolute reference at all.

3. **Ape index is measured and displayed but never scored.** It still gets a
   grade-equivalent for the profile view; it just cannot enter the ceiling or
   be flagged as a limiter. A 25 cm swing in arm span changes the estimate by
   exactly zero. Before, it was auto-filled *and* in the ceiling, so an
   untested user was handed a confident V4.88 computed from their arm span.

4. **Weights are relative, not absolute.** Both the Softmin and the Tier 2
   aggregate renormalise over whatever is present.

5. **Normative ranges are load-bearing and mostly unguarded.** The path-B
   metrics are calibrated entirely by two numbers each in
   `metric_definitions.dart`. Only the campus and min-edge ranges currently
   have tests asserting they are reachable.

6. **The benchmark curves are priors**, and so are the tuned constants here:
   β = 0.5, the 0.90–1.10 Tier 2 band, the 0.92–1.05 experience band, and the
   V10 pulling plateau. All are named constants
   in `scoring_engine.dart` and all are the first things to refit against real
   outcome data.
