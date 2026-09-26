# Play Store listing — draft

Copy-paste into Play Console. Character limits noted; counts are current.

---

## App name (30 max)

```
Crux Check
```

Alternative if you want the keyword in the title, at the cost of a clean name
(28 chars): `Crux Check: Climbing Grade`

## Short description (80 max — this is 65)

```
Estimate your bouldering grade from hangboard and strength tests.
```

## Full description (4000 max — this is ~2,900)

```
Crux Check turns hangboard and strength testing into one number: the bouldering grade your body is currently built for.

Record what you can hang, pull and hold. The app converts each result into a grade-equivalent, combines them, and gives you a range rather than false precision — plus the one thing actually capping you.

WHAT YOU TEST
• Max finger strength on a 20 mm edge
• The smallest edge you can hold at bodyweight
• Max pulling strength, and pull-up reps
• Contact strength on a campus board
• Explosive power, lock-off, power-endurance
• Core, hip mobility, body composition
• Climbing experience

Every test comes with a full protocol: equipment, steps, common mistakes, and what the evidence behind it actually shows. Skip any of them — the estimate works on partial input and simply widens its confidence range to match.

WHAT YOU GET
• A grade estimate with an honest confidence range, in V-scale or Fontainebleau
• Your physical ceiling next to what your experience alone would predict
• Your top limiters — the results sitting furthest below the rest of you
• A profile chart of every metric against climbing norms
• History, so you can see whether a training block actually moved anything

HOW IT ESTIMATES
Finger strength anchors everything: it is the strongest single predictor of bouldering grade in the published data. Results are corrected for body size, because muscular strength scales with cross-section rather than with bodyweight, and raw %BW quietly flatters lighter climbers.

The metrics are not averaged together. Climbing is limited by its weakest link — elite pulling cannot be applied to a hold your fingers will not hold — so a smooth-minimum model lets your weakest result cap the estimate instead of being averaged away by your strongest. That is what makes the limiter list worth reading.

WHAT THIS IS NOT
The estimate is a statistical guess built from published benchmark data and approximate models. It describes what your physical profile resembles. It is not a measurement of what you can climb, and it knows nothing about technique, tactics or head game — frequently the actual gap.

PRIVATE BY DEFAULT
No account. No servers. No analytics. No ads. No permissions requested. Everything you record stays in the app's private storage on your own phone, and uninstalling deletes it. You can also wipe everything from inside the app at any time.

Because nothing is stored anywhere else, there is no backup: a reinstall loses your history.

WHAT YOU NEED
A hangboard with a 20 mm edge is essential, and a range of smaller edges helps. Some tests also want a pull-up bar, a way to add or remove load, and a campus or benchmark board. Any test you have no kit for can simply be left blank.

SAFETY
These are maximal-effort tests and they carry a real risk of injury, particularly to the finger pulleys. Warm up fully, add load gradually, and stop at any sharp pain. If you are under 18 your finger growth plates have not finished closing — do not do maximal finger loading without guidance from a doctor. Crux Check is not a medical device and gives no medical advice.

Free, with no ads and nothing to unlock.
```

---

## Console form answers

| Field | Answer |
|---|---|
| App or game | App |
| Category | Health & Fitness |
| Tags | Exercise & Fitness, Personal Training |
| Email | 4jasonmann@gmail.com |
| Privacy policy | https://sirjjthewise.github.io/ClimbProject/privacy |
| Contains ads | **No** |
| In-app purchases | **No** — the tip jar is an external donation link that unlocks nothing |
| Target audience | 18+ (the safety notice tells under-18s not to use it unsupervised) |

### Data safety

Every answer is **no**. The app collects and shares nothing, has no account,
makes no network requests of its own, and requests no Android permissions.
The only outbound traffic is the optional tip-jar link, which opens the
system browser and sends nothing with it.

### Content rating questionnaire

Nothing in the app is violent, sexual, or gambling-related and there is no
user-generated content or communication. Expect Everyone / PEGI 3. Do
disclose that it gives fitness guidance when asked.

---

## Assets

| Asset | File |
|---|---|
| App icon 512×512 | `assets/icon/play_store_512.png` |
| Feature graphic 1024×500 | `assets/icon/play_feature_graphic_1024x500.png` |
| Phone screenshots | 1080×2400 captures (min 2, max 8) |
| App bundle | `build/app/outputs/bundle/release/app-release.aab` |

## Notes on the wording

Two things are deliberate and worth keeping if you rewrite this:

- **The estimate is described as a guess, twice.** The benchmark curves are
  calibrated on very few published anchor points and several scoring
  constants are tuned rather than measured. Claiming accuracy the model does
  not have invites one-star reviews from anyone who cross-checks it.
- **The hangboard requirement is stated plainly.** Without one the app cannot
  produce its anchor metric, and users who discover that after installing
  will say so in the reviews.
