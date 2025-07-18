import 'package:flutter_liveness_detection_randomized_plugin/index.dart';

List<LivenessDetectionStepItem> stepLiveness = [
  // LivenessDetectionStepItem(
  //   step: LivenessDetectionStep.blink,
  //   title: "Berkedip",
  // ),
  // LivenessDetectionStepItem(
  //   step: LivenessDetectionStep.lookUp,
  //   title: "Look UP",
  // ),
  // LivenessDetectionStepItem(
  //   step: LivenessDetectionStep.lookDown,
  //   title: "Look DOWN",
  // ),
  LivenessDetectionStepItem(
    step: LivenessDetectionStep.lookRight,
    title: "Tengok Kanan",
  ),
  LivenessDetectionStepItem(
    step: LivenessDetectionStep.lookLeft,
    title: "Tengok Kiri",
  ),
  LivenessDetectionStepItem(
    step: LivenessDetectionStep.smile,
    title: "Tersenyum",
  ),
];
