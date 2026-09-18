/// The safety disclaimer the user must accept before the app can be used.
///
/// This app instructs people to load their fingers, shoulders and elbows to
/// maximum on small edges. Finger pulley and tendon injuries are the most
/// common serious injuries in climbing and are slow to heal, so acceptance is
/// an explicit, blocking action rather than fine print — see
/// [DisclaimerScreen].
///
/// Two drafting rules, both learned the hard way:
///
///  * The under-18 growth plate warning comes early and stands alone.
///    Epiphyseal fractures in young climbers' fingers are well documented,
///    are routinely missed at the time, and can deform the finger
///    permanently. It is the most serious harm this app can contribute to,
///    so it does not get buried in a clause about beginners.
///  * The liability section carves out what cannot lawfully be excluded
///    rather than claiming blanket immunity. A term excluding liability for
///    negligently caused personal injury is unenforceable across the EEA,
///    and an over-broad unfair term risks being struck out altogether
///    instead of read down — claiming less protects more.
///
/// Not drafted by a lawyer. See README before shipping.
class SafetyDisclaimer {
  SafetyDisclaimer._();

  /// Bump whenever the wording below changes in a way that alters what the
  /// user agreed to. Everyone is asked to accept again on next launch, so
  /// this is deliberately a judgement call, not an automatic version stamp.
  static const int version = 2;

  static const String title = 'Before you start';

  static const String intro =
      'Crux Check asks you to perform maximal-effort strength tests. These '
      'carry a genuine risk of injury. Please read all of this before you '
      'record anything.';

  static const List<(String, String)> sections = [
    (
      'Under 18? Stop here and talk to a doctor first',
      'The growth plates in the fingers do not finish closing until roughly '
          'age 16 to 19. Hard finger loading — small edges, crimping and '
          'campus board work above all — can fracture them. These fractures '
          'are easy to miss at the time, and they can deform the finger '
          'permanently. If you are still growing, do not perform maximal '
          'hangboard or campus testing on the strength of an app. Get '
          'guidance from a doctor and a coach who know your skeletal '
          'maturity.',
    ),
    (
      'This is not medical advice',
      'Crux Check is a training and self-assessment tool. It is not a medical '
          'device, and nothing in it is medical, physiotherapy or coaching '
          'advice. Speak to a doctor or physiotherapist before you start if '
          'any of this applies to you: a current or past finger pulley, '
          'tendon, elbow or shoulder injury; a heart or blood pressure '
          'condition, since these are maximal efforts and raise blood '
          'pressure sharply; joint hypermobility; pregnancy; or any other '
          'condition that maximal exertion might affect.',
    ),
    (
      'Maximal testing carries a real risk of injury',
      'Hanging at or above bodyweight on small edges loads the finger pulleys '
          'very hard. Pulley strains and ruptures, tendon injuries and '
          'shoulder injuries are all possible, and they can take months to '
          'heal. Warm up fully every time, add load gradually, and never '
          'push through pain.',
    ),
    (
      'If something pops, stop and get it seen',
      'A pop or click, or sudden sharp pain in a finger, usually means a '
          'pulley injury. End the session. Do not test the other hand to '
          'compare, and do not go back for one more attempt to check whether '
          'it still hurts. See a doctor or physiotherapist: pulley injuries '
          'that are treated late heal worse than those treated early.',
    ),
    (
      'Some of these tests are not for everyone',
      'The protocols assume you already climb regularly and are currently '
          'free of injury. Campus moves and small-edge hangs in particular '
          'are not appropriate if you are new to climbing, coming back from a '
          'layoff, or returning from an upper-body injury. Skipping a test is '
          'always a valid choice — the app works fine with some left blank.',
    ),
    (
      'The grade estimate is a statistical guess',
      'Your predicted grade comes from published benchmark data and '
          'approximate models, some of it calibrated on very few data points. '
          'It is an estimate of what your physical profile resembles. It is '
          'not a measurement of what you can climb, not a promise, and not a '
          'number worth chasing at the cost of your fingers.',
    ),
    (
      'Your responsibility, and the limits of ours',
      'You use this app and perform these tests at your own risk. You are '
          'responsible for checking your equipment, choosing loads you can '
          'control, and judging whether a given test is right for you on the '
          'day.\n\nNothing here limits any liability that cannot lawfully be '
          'limited — in many countries, including across the EEA, that '
          'includes death or personal injury caused by negligence, and it '
          'includes fraud. Subject to that, and to the fullest extent the law '
          'allows, the developer is not liable for injury, loss or damage '
          'arising out of your use of this app. Your statutory rights as a '
          'consumer are unaffected.',
    ),
  ];

  static const String acceptLabel =
      'I have read this, I understand the risks, and I accept them';
}
