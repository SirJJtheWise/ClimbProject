# Crux Check

Estimates a bouldering grade from hangboard and strength tests. Record what you
can hang, pull and hold; the app converts it into a predicted grade, a
confidence band, and a ranked list of what is actually holding you back.

Everything runs on-device. No accounts, no server, no analytics, no ads, and
the app requests no Android permissions.

## Running it

```bash
flutter pub get
flutter run -d linux     # or: -d <android device id>
flutter test
flutter analyze
```

Development happens against the Linux desktop target because it is the fastest
loop. Android is the shipping target.

## How the grade is calculated

See [GRADE_CALCULATION.md](GRADE_CALCULATION.md) for the whole pipeline —
allometric scaling, the Softmin bottleneck ceiling, Tier 1 vs Tier 2 metrics,
and the tuned constants. Worth reading before changing anything in
`lib/logic/`.

Short version: finger strength sets an anchor, the three Tier 1 metrics are
combined with a smooth minimum so the weakest one caps the estimate rather than
being averaged away, and everything else nudges the result.

## Layout

```
lib/
  data/      metric catalogue, benchmark curves, safety disclaimer text
  logic/     scoring engine, assessment pipeline, grade conversion
  models/    persisted types
  screens/   test hub, test input, results, history, onboarding, disclaimer
  state/     AppState (provider), sqflite wiring
  theme/     colour, spacing, typography
  widgets/   shared components
```

## Things that will bite you

**Removing a metric from `MetricId` breaks saved data.** Rows and saved
assessments store metric names as strings, so a name the enum no longer has
used to throw out of `byName` and fail the entire load — silently emptying the
app. Reads go through `TestResult.tryFromMap` and `knownMetric()`, which skip
unknown names. Keep it that way, and add a migration in `DbHelper._onUpgrade`
if stored values change meaning.

**Normative ranges are the whole calibration** for every metric without a
benchmark curve. A wrong range silently biases the estimate and nothing else
catches it. Two numbers in `metric_definitions.dart` once made rung 4 on a
campus board score at the 29th percentile, so every user was told their contact
strength was a weakness.

**The scoring constants are tuned guesses**, not measurements — the Softmin
temperature, the Tier 2 band, the experience curve, the 70 kg reference mass,
the pulling plateau. All are named constants in `scoring_engine.dart` with
their reasoning attached. Refit them first when real outcome data exists.

**The fun-level names must stay invented.** No real climbers (publicity
rights) and no product names (trademarks). Both have already had to be removed
once.

## App icon

Sources live in `assets/icon/`. `logo-original.jpeg` is the artwork as
supplied; everything else is derived from it.

```bash
dart run flutter_launcher_icons
```

Two things about the derivation are deliberate and easy to undo by accident:

- **The original is reframed.** It arrived 4:3 with the climber filling under a
  third of the width, which is a speck at 48 dp. `icon.png` crops to the ink
  bounding box and scales the figure to 78% of a square tile.
- **`icon_foreground.png` is a different size on purpose.** Android composites
  adaptive icons with a 16% inset and then masks the outer third away, so the
  foreground is scaled to land the figure at ~57% of the finished tile — just
  inside the circle the mask guarantees. Reusing `icon.png` as the foreground
  would crop the climber's hands and feet off.

Play listing assets are generated alongside: `play_store_512.png` and
`play_feature_graphic_1024x500.png`.

The launch screen is the brand ground colour only (`launch_background` in
`values/colors.xml`, with a `values-night` variant), so a cold start does not
flash white before Flutter's first frame.

## Releasing to Play

Requires a JDK, not just a JRE (`sudo apt install openjdk-21-jdk`).

1. Generate an upload keystore — **back it up somewhere safe**, because Play
   cannot rotate it without a support request:

   ```bash
   keytool -genkey -v -keystore ~/crux-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Copy `android/key.properties.example` to `android/key.properties` and fill
   it in. `storeFile` must be an **absolute** path — Gradle resolves relative
   paths there against `android/app/`, which is never what you meant.

3. Build the bundle:

   ```bash
   flutter build appbundle --release
   ```

   Without `key.properties` the release build falls back to debug signing so it
   still runs locally — but Play rejects debug-signed bundles, so that output
   is not publishable.

4. Verify before uploading:

   ```bash
   ./tool/verify_signing.sh
   ```

   This exists because the fallback in step 3 fails silently: a debug-signed
   bundle builds without a single warning and is only rejected once Play has
   it. The script compares the bundle's certificate against
   `~/.android/debug.keystore` and refuses the debug key.

The `.aab` is around 57 MB, most of which is debug symbols for crash
deobfuscation plus three ABIs. Play splits it per device; the actual download
is roughly 10–12 MB.

### Play Console data safety

Nothing is collected and nothing leaves the device, so every question answers
"no".

The privacy policy lives at [`docs/privacy.md`](../docs/privacy.md) and is
published via GitHub Pages at
<https://sirjjthewise.github.io/ClimbProject/privacy>. That URL goes in the
Play listing. Edit the file in `docs/` — it is the only copy, so there is
nothing to keep in sync.

## Disclaimer

The safety notice in `lib/data/safety_disclaimer.dart` was not written by a
lawyer. It covers the ground these usually cover and the liability section is
drafted to preserve what cannot lawfully be excluded, but it has not been
reviewed. Get it looked at before shipping.
