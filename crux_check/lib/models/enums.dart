enum Sex { male, female }

enum GradeScale { v, font }

/// The 15 metrics from the spec. [edgeTolerance] is a profiling-only
/// sub-metric that folds into the finger-strength card and carries no
/// independent weight in the composite (see MetricDef.weight == 0).
enum MetricId {
  fingerStrength,
  pullingStrength,
  rfdContact,
  explosivePower,
  lockOff,
  edgeTolerance,
  powerEndurance,
  fingerEndurance,
  core,
  hipAbduction,
  hipFlexion,
  bodyComposition,
  apeIndex,
  pullReps,
  experience,
}

enum MetricBucket {
  trainablePhysical,
  bodyComposition,
  fixedAnthropometric,
  experience,
}

enum EvidenceStrength { strong, moderate, informedEstimate }

enum MetricGroup { fingers, pullPower, core, mobility, body, experience }
