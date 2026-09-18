enum Sex { male, female }

enum GradeScale { v, font }

/// The 14 metrics from the spec.
enum MetricId {
  fingerStrength,
  pullingStrength,
  rfdContact,
  explosivePower,
  lockOff,
  powerEndurance,
  minEdge,
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
