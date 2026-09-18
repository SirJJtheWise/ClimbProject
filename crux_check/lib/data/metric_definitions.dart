import '../models/enums.dart';
import '../models/metric_def.dart';

/// The 14-metric catalogue from the spec: definitions, protocols, weights,
/// evidence notes and normative ranges. Weights sum to 91, not 100 — the
/// residual is intentional (spec: "absorbed by renormalization when the
/// user skips tests") since the composite formula divides by the sum of
/// weights actually used, not by a fixed 100.
///
/// Every test here measures something the others do not. Where the spec
/// offered two protocol options for a metric, the option chosen is the one
/// that does *not* collide with a neighbouring test:
///
///  * Power-endurance is the board max-moves variant, not 7:3 repeaters,
///    so it does not restate a hangboard protocol. It carries 0% weight:
///    its own evidence (Lattice R=0.007 for bouldering) says it does not
///    predict grade, and a metric that admits it cannot predict should not
///    be allowed to move the prediction. Kept for weakness profiling.
///  * Explosive power is the double-dyno variant only; the "max campus
///    1-5-9" alternative would repeat the campus-reach test used for RFD.
///  * Pull-up reps is framed as a profiling companion to pulling strength
///    rather than a rival strength test, matching its 1% weight.
///  * The fingers group is a load test and a size test, not two load
///    tests. Finger strength asks how much load a 20 mm edge takes; min
///    edge asks how little edge holds bodyweight. Edge tolerance (max
///    added load on a small edge) was dropped because it was the first
///    protocol with the edge swapped, and finger endurance / critical
///    force was dropped because reading a falling force off a hangboard
///    needs a load cell the equipment list never had.
class MetricDefinitions {
  MetricDefinitions._();

  static const String warmUpNote =
      'Warm up thoroughly (5-10 min pulse-raise + progressive loading) before attempting a max effort. Stop immediately on sharp pain.';

  static final Map<MetricId, MetricDef> all = {
    MetricId.fingerStrength: const MetricDef(
      id: MetricId.fingerStrength,
      name: 'Max finger strength (half-crimp)',
      shortName: 'Finger strength',
      group: MetricGroup.fingers,
      bucket: MetricBucket.trainablePhysical,
      weight: 30,
      unit: '%BW',
      hasGradeTable: true,
      summary:
          'Your maximum finger strength on a 20 mm edge. This is the single '
          'strongest predictor of bouldering grade and anchors your whole '
          'estimate.',
      equipment:
          '20 mm hangboard edge, dip belt or harness with plates. A pulley or '
          'resistance band if you need to take weight off.',
      steps: [
        'Warm up: 5-10 minutes pulse-raise, then 3-4 progressively heavier '
            'easy hangs.',
        'Set a strict half-crimp on the 20 mm edge — fingertips loaded, middle '
            'knuckles at roughly 90 degrees, thumb off the edge.',
        'Hang with both hands, arms straight or only slightly bent. Never a '
            '90-degree lock. Keep the shoulders engaged, not shrugged.',
        'Hold for 7 seconds. Made it cleanly? Rest 3 minutes and add load. '
            'Failed early? Take load off.',
        'Bracket your maximum within about 8 hangs, then stop — past that '
            'you are measuring fatigue, not strength.',
      ],
      recordText:
          'Enter your bodyweight and the load added on your best clean '
          '7-second hang. The app converts it to %BW.',
      commonMistakes: [
        'Sliding into a full crimp (thumb over the index) or an open drag — '
            'both change the number and break comparability.',
        'Bending the arms into a lock-off, which brings the biceps in and '
            'inflates the result.',
        'Testing at the end of a session. Finger max needs fresh fingers.',
      ],
      safetyNote:
          '$warmUpNote Finger pulleys are slow to heal — never push through a sharp twinge in a finger joint.',
      evidenceNote:
          'Strongest predictor of bouldering grade (Buraas EJAP 2025 r=0.89 on 22mm edge, n=19; Lattice R=0.704, R²=0.496, n=901).',
      evidenceStrength: EvidenceStrength.strong,
    ),
    MetricId.pullingStrength: const MetricDef(
      id: MetricId.pullingStrength,
      name: 'Max pulling strength',
      shortName: 'Pulling strength',
      group: MetricGroup.pullPower,
      bucket: MetricBucket.trainablePhysical,
      weight: 12,
      unit: '%BW',
      hasGradeTable: true,
      summary:
          'Your maximum pulling force, measured as added load over 2 reps. '
          'Load is what predicts grade here — rep count barely does, which is '
          'why this is a separate test from pull-up reps.',
      equipment: 'Pull-up bar, dip belt or harness, plates.',
      steps: [
        'Warm up with 2-3 sets of easy bodyweight pull-ups.',
        'Take a pronated (overhand) grip, hands roughly shoulder-width.',
        'From near-straight arms, pull until your chin clears the bar, then '
            'lower under control. That is one rep.',
        'Perform exactly 2 reps with added load. Managing 3 or more means the '
            'load is too light.',
        'Rest 3 minutes between attempts and keep adding load until 2 reps is '
            'a genuine maximum.',
      ],
      recordText:
          'Enter your bodyweight and the load you added for your best clean '
          '2-rep set.',
      commonMistakes: [
        'Kipping or swinging the legs to get through the second rep.',
        'Stopping short of chin-over-bar, or not returning to near-straight '
            'arms between reps.',
        'Testing a 1-rep max — the benchmark table assumes 2RM, so a 1RM will '
            'read as a higher grade than you actually have.',
      ],
      safetyNote: warmUpNote,
      evidenceNote:
          'Clear #2 predictor (Lattice R=0.582, R²=0.337; EJAP r=0.55). Test max load, not reps.',
      evidenceStrength: EvidenceStrength.strong,
    ),
    MetricId.rfdContact: const MetricDef(
      id: MetricId.rfdContact,
      name: 'Rate of force development / contact strength',
      shortName: 'RFD / contact',
      group: MetricGroup.pullPower,
      bucket: MetricBucket.trainablePhysical,
      weight: 6,
      unit: 'rung',
      hasGradeTable: false,
      summary:
          'How fast you generate force, measured by how far you can campus in '
          'one explosive pull. This is about the speed of the catch — '
          'explosive power measures how far you can launch.',
      equipment:
          'A campus board with numbered rungs at standard 22 mm-deep, 22 cm '
          'spacing (Metolius-style). Rung spacing varies between boards, so '
          'stay on the same board between retests or the number drifts.',
      steps: [
        'Warm up thoroughly, including several sub-maximal campus moves.',
        'Start matched on rung 1 with both hands.',
        'Campus with one hand to the highest rung you can latch and hold under '
            'control.',
        'A touch does not count — you have to hold the latch for it to count.',
        'Test both hands, rest 3 minutes between attempts, and keep the best '
            'result.',
      ],
      recordText: 'Enter the number of the highest rung you latched and held.',
      commonMistakes: [
        'Counting a rung you slapped but could not hold.',
        'Starting from a rung other than the bottom one, which shortens the '
            'reach and inflates the number.',
        'Generating the move by swinging the legs off the board.',
      ],
      safetyNote:
          '$warmUpNote High-force campus moves stress pulleys and shoulders — only attempt if you already campus board regularly.',
      evidenceNote:
          'Distinguishes elite from advanced climbers (Levernier & Laffaye 2019; Stien et al.). Calibrated so rung 4 is an average result and rung 6 is elite — on 22 cm spacing a one-hand move past rung 6 is roughly a 110 cm reach gain, which almost nobody holds.',
      evidenceStrength: EvidenceStrength.moderate,
      maleNormativeRange: NormativeRange(worst: 2, best: 6),
      femaleNormativeRange: NormativeRange(worst: 1, best: 5),
    ),
    MetricId.explosivePower: const MetricDef(
      id: MetricId.explosivePower,
      name: 'Explosive power (double-dyno)',
      shortName: 'Explosive power',
      group: MetricGroup.pullPower,
      bucket: MetricBucket.trainablePhysical,
      weight: 3,
      unit: 'cm',
      hasGradeTable: false,
      summary:
          'Whole-body explosive power: how far past your static reach you can '
          'launch and stick a double-dyno. Recorded as the gain over your '
          'static reach, so it measures power rather than height.',
      equipment:
          'A steep board or wall with two matched jugs, a tape measure, and '
          'ideally a partner to mark heights.',
      steps: [
        'Warm up with progressively bigger dynamic moves.',
        'Hang from two matched jugs with your feet on the wall.',
        'Reach up statically with one hand and mark the highest point you can '
            'touch. This is your static reach.',
        'From the same jugs, double-dyno for the highest point you can catch '
            'and control with both hands.',
        'Measure from the static-reach mark to the point you caught. Best of '
            '3 attempts.',
      ],
      recordText:
          'Enter your static reach and the height you caught. The app records '
          'the gain in cm.',
      commonMistakes: [
        'Recording absolute catch height instead of the gain — that just '
            'measures how tall you are.',
        'Counting a catch you immediately swung off.',
        'Testing once the fingers are tired. Power fades before strength does.',
      ],
      safetyNote: warmUpNote,
      evidenceNote:
          'Boulderers outperform lead climbers on all power measures (ES 0.90-1.12).',
      evidenceStrength: EvidenceStrength.informedEstimate,
      maleNormativeRange: NormativeRange(worst: 20, best: 90),
      femaleNormativeRange: NormativeRange(worst: 15, best: 75),
    ),
    MetricId.lockOff: const MetricDef(
      id: MetricId.lockOff,
      name: 'Lock-off strength',
      shortName: 'Lock-off',
      group: MetricGroup.pullPower,
      bucket: MetricBucket.trainablePhysical,
      weight: 4,
      unit: 'seconds',
      hasGradeTable: false,
      summary:
          'How long you can hold a bent-arm position. This is the static '
          'strength that lets you move off a hold in control instead of '
          'pulling past it and hoping.',
      equipment:
          'Pull-up bar or a jug. A weight harness for the two-arm '
          'variation.',
      steps: [
        'Warm up with easy pull-ups and a few short lock-offs.',
        'Pull up to a 90-degree bent arm — elbow at a right angle, forearm '
            'roughly vertical.',
        'Release the other hand and hold, one arm, with the body still.',
        'Start the timer as you let go; stop it the moment the elbow angle '
            'starts to open.',
        'If a one-arm lock-off is not accessible yet, use a weighted two-arm '
            'lock-off at the same angle and note that you did.',
      ],
      recordText:
          'Use the timer to record your longest clean hold, in seconds, on '
          'your stronger arm.',
      commonMistakes: [
        'Letting the elbow drift open past 90 degrees and carrying on counting.',
        'Swinging or kicking to defend the position.',
        'Sinking into a passive shoulder hang at the top of the pull.',
      ],
      safetyNote: warmUpNote,
      evidenceNote: 'Baláš 2011: r=0.76 (men), r=0.80 (women).',
      evidenceStrength: EvidenceStrength.moderate,
      maleNormativeRange: NormativeRange(worst: 0, best: 20),
      femaleNormativeRange: NormativeRange(worst: 0, best: 15),
    ),
    MetricId.powerEndurance: const MetricDef(
      id: MetricId.powerEndurance,
      name: 'Power-endurance (board max moves)',
      shortName: 'Power-endurance',
      group: MetricGroup.pullPower,
      bucket: MetricBucket.trainablePhysical,
      weight: 0,
      unit: 'moves',
      hasGradeTable: false,
      summary:
          'How long you keep pulling hard once you are pumped. Measured on a '
          'board rather than a hangboard, so it tests the whole chain — '
          'finger endurance covers the fingers on their own.',
      equipment:
          'A benchmark board (MoonBoard, Kilter or Tension) and a set problem '
          '2-3 grades below your limit that you can return to every retest.',
      steps: [
        'Warm up as you would for a hard session.',
        'Choose a benchmark problem 2-3 grades below your limit and write it '
            'down — you will need the exact same problem next time.',
        'Climb it on a loop: top out, come down, start again, no rest between '
            'laps.',
        'Keep going until you fall. Count every hand move you completed across '
            'all laps.',
        'Retest on the identical problem, or the history means nothing.',
      ],
      recordText:
          'Enter the total number of hand moves completed before falling.',
      commonMistakes: [
        'Changing the benchmark problem between tests, which makes your '
            'progress line meaningless.',
        'Shaking out on jugs mid-loop — this is a continuous test.',
        'Counting foot moves as well as hand moves.',
      ],
      safetyNote: warmUpNote,
      evidenceNote:
          'Weak predictor for bouldering specifically (Lattice R=0.007) — kept for weakness profiling, not grade estimation.',
      evidenceStrength: EvidenceStrength.informedEstimate,
      maleNormativeRange: NormativeRange(worst: 10, best: 80),
      femaleNormativeRange: NormativeRange(worst: 10, best: 80),
    ),
    MetricId.minEdge: const MetricDef(
      id: MetricId.minEdge,
      name: 'Minimum edge (bodyweight hang)',
      shortName: 'Min edge',
      group: MetricGroup.fingers,
      bucket: MetricBucket.trainablePhysical,
      weight: 3,
      unit: 'mm',
      hasGradeTable: false,
      summary:
          'The smallest edge you can hang at bodyweight for 7 seconds. Max '
          'finger strength asks how much load a 20 mm edge takes; this asks '
          'how little edge you need. The two come apart often enough to be '
          'worth knowing separately.',
      equipment:
          'A hangboard with a range of edge depths, ideally 6-20 mm. No added '
          'weight and no assistance.',
      steps: [
        'Record your 20 mm max finger strength first and warm up on the 20 mm '
            'edge — this test reads against that one.',
        'Start on an edge you know you can hold. Hang at bodyweight, both '
            'hands, strict half-crimp, arms straight.',
        'Hold 7 seconds. Clean? Rest 3 minutes and move down to the next '
            'smaller edge.',
        'Your result is the smallest edge you held for a clean 7 seconds.',
        'Three or four edges is enough for one session. Small edges load the '
            'pulleys hard — stop at the first twinge rather than bracketing '
            'exactly.',
      ],
      recordText:
          'Enter the smallest edge you held cleanly for 7 seconds at '
          'bodyweight. Smaller is stronger.',
      commonMistakes: [
        'Adding or taking off weight. This one is bodyweight only — load is '
            'what the max finger strength test is for.',
        'Letting the half-crimp roll into a full crimp as the edge shrinks.',
        'Counting an edge you held for three or four seconds. The full 7 '
            'seconds is what makes the number comparable between sessions.',
      ],
      safetyNote:
          '$warmUpNote Small edges concentrate load on the pulleys — drop one edge at a time and stop at the first twinge.',
      evidenceNote:
          'Small-edge capacity tracks bouldering grade closely (Lattice min-edge protocol). Scored as a companion to the 20 mm max rather than a second anchor.',
      evidenceStrength: EvidenceStrength.informedEstimate,
      maleNormativeRange: NormativeRange(worst: 20, best: 6),
      femaleNormativeRange: NormativeRange(worst: 20, best: 7),
    ),
    MetricId.core: const MetricDef(
      id: MetricId.core,
      name: 'Core strength',
      shortName: 'Core',
      group: MetricGroup.core,
      bucket: MetricBucket.trainablePhysical,
      weight: 5,
      unit: 'level (0-9)',
      hasGradeTable: false,
      summary:
          'Body tension, scored on the front-lever ladder. This is what keeps '
          'your feet on the wall when the angle kicks back.',
      equipment: 'A pull-up bar or rings.',
      steps: [
        'Warm up the shoulders and midsection.',
        'Work up the ladder to the hardest position you can hold with a flat '
            'back and locked-out arms.',
        'A position only counts once you have held it for 5 seconds or more.',
        'Ladder: 0 cannot hold a tuck · 3 advanced tuck · 5 one-leg · 7 full '
            'front lever · 9 full front lever for 20 s or more.',
        'No access to a bar? Use an L-sit or hanging leg raise and estimate '
            'the equivalent level.',
      ],
      recordText:
          'Pick the highest level you held cleanly for at least 5 seconds.',
      commonMistakes: [
        'Letting the hips sag or the lower back arch — the body line has to '
            'stay flat.',
        'Bending the arms to take the position, which changes the lever.',
        'Counting a position you touched but never actually held for 5 '
            'seconds.',
      ],
      safetyNote: warmUpNote,
      evidenceNote:
          'Weak-to-moderate, inconsistent evidence across studies — profiling metric.',
      evidenceStrength: EvidenceStrength.informedEstimate,
      maleNormativeRange: NormativeRange(worst: 0, best: 9),
      femaleNormativeRange: NormativeRange(worst: 0, best: 9),
    ),
    MetricId.hipAbduction: const MetricDef(
      id: MetricId.hipAbduction,
      name: 'Hip abduction mobility',
      shortName: 'Hip abduction',
      group: MetricGroup.mobility,
      bucket: MetricBucket.fixedAnthropometric,
      weight: 3,
      unit: '% of height',
      hasGradeTable: false,
      summary:
          'How wide you can get your feet — the mobility behind drop-knees and '
          'wide stems. The strongest mobility signal for climbing.',
      equipment:
          'A wall to steady yourself and a tape measure. A partner '
          'makes the measurement much easier.',
      steps: [
        'Warm the hips and adductors with dynamic leg swings. Do not test '
            'cold.',
        'Stand facing a wall with your hands on it for balance.',
        'Slide the feet apart as wide as you can hold without pain.',
        'Measure the vertical distance from your pubic symphysis — the bony '
            'point at the front of the pelvis — down to the floor.',
        'Come out of the position slowly.',
      ],
      recordText:
          'Enter the pubic-symphysis-to-floor distance in cm. The app converts '
          'it to a percentage of your height, where lower is better.',
      commonMistakes: [
        'Bouncing into the position instead of easing in.',
        'Rolling the feet or tipping the pelvis forward to fake extra width.',
        'Testing cold, which both lowers the score and risks a groin strain.',
      ],
      safetyNote:
          'Stretch into position gradually — do not bounce or force a static stretch cold.',
      evidenceNote:
          'Strongest mobility signal (Draga et al.: straddle stand r=-0.48).',
      evidenceStrength: EvidenceStrength.informedEstimate,
      maleNormativeRange: NormativeRange(worst: 40, best: 0),
      femaleNormativeRange: NormativeRange(worst: 40, best: 0),
    ),
    MetricId.hipFlexion: const MetricDef(
      id: MetricId.hipFlexion,
      name: 'Hip flexion / high-step',
      shortName: 'Hip flexion',
      group: MetricGroup.mobility,
      bucket: MetricBucket.fixedAnthropometric,
      weight: 2,
      unit: '% of leg length',
      hasGradeTable: false,
      summary:
          'Your maximum high-step: the active hip range that decides whether '
          'you can actually stand up on that foothold by your hip.',
      equipment: 'A wall and a tape measure.',
      steps: [
        'Warm the hip with dynamic leg swings in both directions.',
        'Stand side-on to a wall, about a hand-width away, one hand on it for '
            'balance.',
        'Raise the leg nearest the wall as high as you can — actively, without '
            'helping it up with your hands.',
        'Keep the torso upright. Leaning away from the leg does not count.',
        'Measure the height of the sole of your foot off the floor, then your '
            'leg length from hip joint to floor.',
      ],
      recordText:
          'Enter foot height and leg length. Recorded as a percentage of leg '
          'length.',
      commonMistakes: [
        'Leaning the torso away, which buys height you cannot use on the wall.',
        'Pulling the leg up with your hands — this is an active range test.',
        'Measuring leg length from the waist rather than the hip joint.',
      ],
      safetyNote:
          'Warm the hip up with dynamic swings before testing max range.',
      evidenceNote:
          'Climbing-specific hip flexion moderately correlated with ability.',
      evidenceStrength: EvidenceStrength.informedEstimate,
      maleNormativeRange: NormativeRange(worst: 40, best: 110),
      femaleNormativeRange: NormativeRange(worst: 40, best: 110),
    ),
    MetricId.bodyComposition: const MetricDef(
      id: MetricId.bodyComposition,
      name: 'Body composition',
      shortName: 'Body fat %',
      group: MetricGroup.body,
      bucket: MetricBucket.bodyComposition,
      weight: 6,
      unit: '% body fat',
      hasGradeTable: false,
      summary:
          'Body fat percentage. It matters because every strength metric here '
          'is relative to bodyweight — and it is the one number in this app '
          'that is easy to take too far.',
      equipment:
          'Skinfold calipers or a bioimpedance scale. Failing both, a tape '
          'measure for a rough waist estimate.',
      steps: [
        'Measure first thing in the morning, before eating or drinking, so '
            'readings stay comparable.',
        'With calipers: use the same sites every time and average three '
            'readings per site.',
        'With a bioimpedance scale: same time of day, same hydration state, '
            'every time.',
        'With neither: estimate from waist circumference and a comparison '
            'photo, and treat the result as rough.',
        'Retest no more than every 4 weeks. Day-to-day noise is bigger than '
            'real change.',
      ],
      recordText: 'Enter your body fat percentage.',
      commonMistakes: [
        'Chasing a lower number. Under-fuelling costs more strength than the '
            'weight saves, and the injury risk is real.',
        'Comparing readings taken with different methods or at different times '
            'of day.',
        'Retesting weekly and reading measurement noise as progress.',
      ],
      safetyNote:
          'No physical exertion required. Be careful with this one: pursuing a low body-fat number is linked to RED-S, hormonal disruption and stress fractures in climbers. If you find yourself restricting food to move this number, speak to a doctor or a sports dietitian.',
      evidenceNote:
          'r≈-0.42 to -0.49; optimal ranges ~6-12% (men), ~10-18% (women) (Hörst).',
      evidenceStrength: EvidenceStrength.moderate,
      maleNormativeRange: NormativeRange(worst: 25, best: 6),
      femaleNormativeRange: NormativeRange(worst: 32, best: 10),
    ),
    MetricId.apeIndex: const MetricDef(
      id: MetricId.apeIndex,
      name: 'Ape index',
      shortName: 'Ape index',
      group: MetricGroup.body,
      bucket: MetricBucket.fixedAnthropometric,
      weight: 2,
      unit: 'cm (span - height)',
      hasGradeTable: false,
      summary:
          'Arm span minus height. Worth roughly 0.14 V-grades per inch — real, '
          'small, and nothing you can train.',
      equipment:
          'Nothing. Computed from the arm span and height in your '
          'profile.',
      steps: [
        'Measured once during onboarding: stand with your arms out horizontal '
            'and measure fingertip to fingertip, then subtract your height.',
        'Edit your profile if either measurement needs correcting.',
      ],
      recordText: 'Computed automatically from your profile.',
      commonMistakes: [
        'Measuring arm span with the shoulders shrugged or the elbows soft.',
        'Reading much into the result — this is among the weakest signals in '
            'the app.',
      ],
      safetyNote: 'No physical exertion required for this test.',
      evidenceNote:
          '~0.14 V-grades per inch (Ben Chan dataset, n≈669) — small, fixed trait.',
      evidenceStrength: EvidenceStrength.informedEstimate,
      maleNormativeRange: NormativeRange(worst: -10, best: 15),
      femaleNormativeRange: NormativeRange(worst: -10, best: 15),
    ),
    MetricId.pullReps: const MetricDef(
      id: MetricId.pullReps,
      name: 'Bodyweight pull reps',
      shortName: 'Pull-up reps',
      group: MetricGroup.pullPower,
      bucket: MetricBucket.trainablePhysical,
      weight: 1,
      unit: 'reps',
      hasGradeTable: false,
      summary:
          'Max strict pull-ups. Deliberately low-weighted: rep count barely '
          'predicts bouldering grade. It is here to profile your pulling '
          'endurance against your pulling max, not to move your estimate.',
      equipment: 'A pull-up bar.',
      steps: [
        'Warm up with two easy sets.',
        'Take a pronated grip, hands about shoulder-width.',
        'From a dead hang with near-straight arms, pull until your chin clears '
            'the bar.',
        'Lower under control back to near-straight arms. That is one rep.',
        'Continue to failure. Stop counting the moment a rep needs a kip.',
      ],
      recordText: 'Enter the number of strict reps.',
      commonMistakes: [
        'Kipping the last few reps and counting them anyway.',
        'Half reps that never clear the bar, or never return to straight arms.',
        'Expecting this to lift your grade estimate — it carries the lowest '
            'weight in the app by design.',
      ],
      safetyNote: warmUpNote,
      evidenceNote:
          'Weak (no-to-middle correlation) — profiling only; max pulling FORCE (metric #2) is what matters.',
      evidenceStrength: EvidenceStrength.informedEstimate,
      maleNormativeRange: NormativeRange(worst: 0, best: 30),
      femaleNormativeRange: NormativeRange(worst: 0, best: 20),
    ),
    MetricId.experience: const MetricDef(
      id: MetricId.experience,
      name: 'Experience / mileage',
      shortName: 'Experience',
      group: MetricGroup.experience,
      bucket: MetricBucket.experience,
      weight: 14,
      unit: 'index (0-100)',
      hasGradeTable: false,
      summary:
          'Years climbing, sessions per week and outdoor mileage, combined '
          'into one index. After finger strength this is the strongest single '
          'predictor in the app.',
      equipment: 'Nothing. Three questions.',
      steps: [
        'Total years climbing, counting from when you started — not counting '
            'long breaks as active years.',
        'Your honest average sessions per week over the last year, not your '
            'best training block.',
        'Years spent climbing outdoors specifically. Outdoor mileage carries '
            'more weight here than gym time.',
      ],
      recordText:
          'Answer the three questions; the app combines them into a 0-100 '
          'index.',
      commonMistakes: [
        'Counting a year out with an injury as a year of climbing.',
        'Reporting a peak training block instead of a realistic average.',
      ],
      safetyNote: 'No physical exertion required for this test.',
      evidenceNote:
          'Among the strongest single variables (R²≈0.16); explained 42.7% of onsight and 49.5% of redpoint variance in a youth study.',
      evidenceStrength: EvidenceStrength.informedEstimate,
      maleNormativeRange: NormativeRange(worst: 0, best: 100),
      femaleNormativeRange: NormativeRange(worst: 0, best: 100),
    ),
  };

  static List<MetricDef> get orderedForHub => [
    all[MetricId.fingerStrength]!,
    all[MetricId.minEdge]!,
    all[MetricId.pullingStrength]!,
    all[MetricId.rfdContact]!,
    all[MetricId.explosivePower]!,
    all[MetricId.lockOff]!,
    all[MetricId.powerEndurance]!,
    all[MetricId.pullReps]!,
    all[MetricId.core]!,
    all[MetricId.hipAbduction]!,
    all[MetricId.hipFlexion]!,
    all[MetricId.bodyComposition]!,
    all[MetricId.apeIndex]!,
    all[MetricId.experience]!,
  ];
}
