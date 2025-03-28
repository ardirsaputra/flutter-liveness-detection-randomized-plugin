// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_liveness_detection_randomized_plugin/index.dart';
import 'package:flutter_liveness_detection_randomized_plugin/src/core/constants/liveness_detection_step_constant.dart';
import 'package:flutter_liveness_detection_randomized_plugin/src/models/liveness_detection_label_model.dart';

List<CameraDescription> availableCams = [];

class LivenessDetectionView extends StatefulWidget {
  final LivenessDetectionConfig config;
  final bool isEnableSnackBar;
  final bool shuffleListWithSmileLast;
  final bool showCurrentStep;
  final bool isDarkMode;

  const LivenessDetectionView({
    super.key,
    required this.config,
    required this.isEnableSnackBar,
    this.isDarkMode = true,
    this.showCurrentStep = false,
    this.shuffleListWithSmileLast = true,
  });

  @override
  State<LivenessDetectionView> createState() => _LivenessDetectionScreenState();
}

class _LivenessDetectionScreenState extends State<LivenessDetectionView> {
  CameraController? _cameraController;
  int _cameraIndex = 0;
  bool _isBusy = false;
  bool _isTakingPicture = false;
  Timer? _timerToDetectFace;
  bool _isMounted = false;

  late bool _isInfoStepCompleted;
  bool _isProcessingStep = false;
  bool _faceDetectedState = false;

  late final List<LivenessDetectionStepItem> steps;
  final GlobalKey<LivenessDetectionStepOverlayWidgetState> _stepsKey = GlobalKey<LivenessDetectionStepOverlayWidgetState>();

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _preInitCallBack();
    steps = _initializeSteps();
    WidgetsBinding.instance.addPostFrameCallback((_) => _postFrameCallBack());
  }

  @override
  void dispose() {
    _isMounted = false;
    _timerToDetectFace?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  List<LivenessDetectionStepItem> _initializeSteps() {
    List<LivenessDetectionStepItem> stepList =
        widget.config.useCustomizedLabel && widget.config.customizedLabel != null ? customizedLivenessLabel(widget.config.customizedLabel!) : List.from(stepLiveness);
    shuffleListLivenessChallenge(list: stepList, isSmileLast: widget.shuffleListWithSmileLast);
    return stepList;
  }

  static void shuffleListLivenessChallenge({
    required List<LivenessDetectionStepItem> list,
    required bool isSmileLast,
  }) {
    if (isSmileLast) {
      int? blinkIndex = list.indexWhere((item) => item.step == LivenessDetectionStep.blink);
      int? smileIndex = list.indexWhere((item) => item.step == LivenessDetectionStep.smile);

      if (blinkIndex != -1 && smileIndex != -1) {
        LivenessDetectionStepItem blinkItem = list.removeAt(blinkIndex);
        LivenessDetectionStepItem smileItem = list.removeAt(smileIndex > blinkIndex ? smileIndex - 1 : smileIndex);
        list.shuffle();
        list.insert(list.length - 1, blinkItem);
        list.add(smileItem);
      } else {
        list.shuffle();
      }
    } else {
      list.shuffle();
    }
  }

  List<LivenessDetectionStepItem> customizedLivenessLabel(LivenessDetectionLabelModel label) {
    List<LivenessDetectionStepItem> customizedSteps = [];
    if (label.blink?.isNotEmpty ?? false) {
      customizedSteps.add(LivenessDetectionStepItem(step: LivenessDetectionStep.blink, title: label.blink ?? "Blink 2-3 Times"));
    }
    if (label.lookRight?.isNotEmpty ?? false) {
      customizedSteps.add(LivenessDetectionStepItem(step: LivenessDetectionStep.lookRight, title: label.lookRight ?? "Look Right"));
    }
    if (label.lookLeft?.isNotEmpty ?? false) {
      customizedSteps.add(LivenessDetectionStepItem(step: LivenessDetectionStep.lookLeft, title: label.lookLeft ?? "Look Left"));
    }
    if (label.lookUp?.isNotEmpty ?? false) {
      customizedSteps.add(LivenessDetectionStepItem(step: LivenessDetectionStep.lookUp, title: label.lookUp ?? "Look Up"));
    }
    if (label.lookDown?.isNotEmpty ?? false) {
      customizedSteps.add(LivenessDetectionStepItem(step: LivenessDetectionStep.lookDown, title: label.lookDown ?? "Look Down"));
    }
    if (label.smile?.isNotEmpty ?? false) {
      customizedSteps.add(LivenessDetectionStepItem(step: LivenessDetectionStep.smile, title: label.smile ?? "Smile"));
    }
    return customizedSteps;
  }

  void _preInitCallBack() {
    _isInfoStepCompleted = !widget.config.startWithInfoScreen;
  }

  Future<void> _postFrameCallBack() async {
    if (!_isMounted) return;
    try {
      availableCams = await availableCameras();
      _cameraIndex = availableCams.indexOf(
        availableCams.firstWhere(
          (element) => element.lensDirection == CameraLensDirection.front,
          orElse: () => availableCams.first,
        ),
      );
      if (!widget.config.startWithInfoScreen) {
        _startLiveFeed();
      }
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
    }
  }

  void _startLiveFeed() async {
    if (!_isMounted || _cameraController != null) return;
    try {
      final camera = availableCams[_cameraIndex];
      _cameraController = CameraController(camera, ResolutionPreset.high, enableAudio: false);
      await _cameraController?.initialize();
      if (!_isMounted) return;
      _cameraController?.startImageStream(_processCameraImage);
      _startFaceDetectionTimer();
      setState(() {});
    } catch (e) {
      debugPrint('Error starting live feed: $e');
    }
  }

  void _startFaceDetectionTimer() {
    _timerToDetectFace?.cancel();
    if (!_isMounted) return;
    _timerToDetectFace = Timer(
      Duration(seconds: widget.config.durationLivenessVerify ?? 45),
      () => _onDetectionCompleted(imgToReturn: null),
    );
  }

  Future<void> _processCameraImage(CameraImage cameraImage) async {
    if (!_isMounted || _isBusy) return;
    _isBusy = true;

    try {
      final inputImage = _convertCameraImage(cameraImage);
      if (inputImage != null) {
        await _processImage(inputImage);
      }
    } catch (e) {
      debugPrint('Error processing camera image: $e');
    } finally {
      _isBusy = false;
      if (_isMounted) setState(() {});
    }
  }

  InputImage? _convertCameraImage(CameraImage cameraImage) {
    final allBytes = WriteBuffer();
    for (final plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final imageSize = Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());
    final camera = availableCams[_cameraIndex];
    final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    final inputImageFormat = InputImageFormatValue.fromRawValue(cameraImage.format.raw);

    if (imageRotation == null || inputImageFormat == null) return null;

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: cameraImage.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(metadata: inputImageData, bytes: bytes);
  }

  Future<void> _processImage(InputImage inputImage) async {
    final faces = await MachineLearningKitHelper.instance.processInputImage(inputImage);
    if (!_isMounted) return;

    if (faces.isEmpty) {
      _resetSteps();
      setState(() => _faceDetectedState = false);
    } else {
      setState(() => _faceDetectedState = true);
      final currentIndex = _stepsKey.currentState?.currentIndex ?? 0;
      if (currentIndex < steps.length) {
        _detectFace(face: faces.first, step: steps[currentIndex].step);
      }
    }
  }

  void _detectFace({required Face face, required LivenessDetectionStep step}) async {
    if (_isProcessingStep || !_isMounted) return;

    switch (step) {
      case LivenessDetectionStep.blink:
        await _handlingBlinkStep(face: face, step: step);
        break;
      case LivenessDetectionStep.lookRight:
        await _handlingTurnRight(face: face, step: step);
        break;
      case LivenessDetectionStep.lookLeft:
        await _handlingTurnLeft(face: face, step: step);
        break;
      case LivenessDetectionStep.lookUp:
        await _handlingLookUp(face: face, step: step);
        break;
      case LivenessDetectionStep.lookDown:
        await _handlingLookDown(face: face, step: step);
        break;
      case LivenessDetectionStep.smile:
        await _handlingSmile(face: face, step: step);
        break;
    }
  }

  Future<void> _completeStep({required LivenessDetectionStep step}) async {
    if (!_isMounted) return;
    await _stepsKey.currentState?.nextPage();
    _stopProcessing();
  }

  void _takePicture() async {
    if (!_isMounted || _cameraController == null || _isTakingPicture) return;

    setState(() => _isTakingPicture = true);
    try {
      await _cameraController?.stopImageStream();
      final XFile? clickedImage = await _cameraController?.takePicture();
      if (clickedImage != null) {
        _onDetectionCompleted(imgToReturn: clickedImage);
      } else {
        _startLiveFeed();
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      _startLiveFeed();
    } finally {
      if (_isMounted) setState(() => _isTakingPicture = false);
    }
  }

  void _onDetectionCompleted({XFile? imgToReturn}) {
    if (!_isMounted) return;
    final String? imgPath = imgToReturn?.path;
    if (widget.isEnableSnackBar) {
      final snackBar = SnackBar(
        content: Text(imgToReturn == null ? 'Verification failed: Time limit exceeded (${widget.config.durationLivenessVerify ?? 45}s)' : 'Verification successful!'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    Navigator.of(context).pop(imgPath);
  }

  void _resetSteps() {
    if (!_isMounted) return;
    if (_stepsKey.currentState?.currentIndex != 0) {
      _stepsKey.currentState?.reset();
    }
  }

  void _startProcessing() => _isMounted ? setState(() => _isProcessingStep = true) : null;
  void _stopProcessing() => _isMounted ? setState(() => _isProcessingStep = false) : null;

  @override
  Widget build(BuildContext context) {
    if (!_isMounted) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        _isInfoStepCompleted
            ? _buildDetectionBody()
            : LivenessDetectionTutorialScreen(
                duration: widget.config.durationLivenessVerify ?? 45,
                isDarkMode: widget.isDarkMode,
                onStartTap: () {
                  if (_isMounted) {
                    setState(() => _isInfoStepCompleted = true);
                    _startLiveFeed();
                  }
                },
              ),
      ],
    );
  }

  Widget _buildDetectionBody() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _cameraController!.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;

    return Stack(
      children: [
        Container(
          height: size.height,
          width: size.width,
          color: widget.isDarkMode ? Colors.black : Colors.white,
        ),
        LivenessDetectionStepOverlayWidget(
          duration: widget.config.durationLivenessVerify,
          showDurationUiText: widget.config.showDurationUiText,
          isDarkMode: widget.isDarkMode,
          isFaceDetected: _faceDetectedState,
          camera: CameraPreview(_cameraController!),
          key: _stepsKey,
          steps: steps,
          showCurrentStep: widget.showCurrentStep,
          onCompleted: () => Future.delayed(const Duration(milliseconds: 500), _takePicture),
        ),
      ],
    );
  }

  Future<void> _handlingBlinkStep({required Face face, required LivenessDetectionStep step}) async {
    final blinkThreshold = FlutterLivenessDetectionRandomizedPlugin.instance.thresholdConfig.firstWhereOrNull((p0) => p0 is LivenessThresholdBlink) as LivenessThresholdBlink?;
    if ((face.leftEyeOpenProbability ?? 1.0) < (blinkThreshold?.leftEyeProbability ?? 0.25) && (face.rightEyeOpenProbability ?? 1.0) < (blinkThreshold?.rightEyeProbability ?? 0.25)) {
      _startProcessing();
      await _completeStep(step: step);
    }
  }

  Future<void> _handlingTurnRight({required Face face, required LivenessDetectionStep step}) async {
    final headTurnThreshold = FlutterLivenessDetectionRandomizedPlugin.instance.thresholdConfig.firstWhereOrNull((p0) => p0 is LivenessThresholdHead) as LivenessThresholdHead?;
    final threshold = headTurnThreshold?.rotationAngle ?? (Platform.isAndroid ? -30 : 30);
    if ((Platform.isAndroid && (face.headEulerAngleY ?? 0) < threshold) || (Platform.isIOS && (face.headEulerAngleY ?? 0) > threshold)) {
      _startProcessing();
      await _completeStep(step: step);
    }
  }

  Future<void> _handlingTurnLeft({required Face face, required LivenessDetectionStep step}) async {
    final headTurnThreshold = FlutterLivenessDetectionRandomizedPlugin.instance.thresholdConfig.firstWhereOrNull((p0) => p0 is LivenessThresholdHead) as LivenessThresholdHead?;
    final threshold = headTurnThreshold?.rotationAngle ?? (Platform.isAndroid ? 30 : -30);
    if ((Platform.isAndroid && (face.headEulerAngleY ?? 0) > threshold) || (Platform.isIOS && (face.headEulerAngleY ?? 0) < threshold)) {
      _startProcessing();
      await _completeStep(step: step);
    }
  }

  Future<void> _handlingLookUp({required Face face, required LivenessDetectionStep step}) async {
    final headTurnThreshold = FlutterLivenessDetectionRandomizedPlugin.instance.thresholdConfig.firstWhereOrNull((p0) => p0 is LivenessThresholdHead) as LivenessThresholdHead?;
    if ((face.headEulerAngleX ?? 0) > (headTurnThreshold?.rotationAngle ?? 20)) {
      _startProcessing();
      await _completeStep(step: step);
    }
  }

  Future<void> _handlingLookDown({required Face face, required LivenessDetectionStep step}) async {
    final headTurnThreshold = FlutterLivenessDetectionRandomizedPlugin.instance.thresholdConfig.firstWhereOrNull((p0) => p0 is LivenessThresholdHead) as LivenessThresholdHead?;
    if ((face.headEulerAngleX ?? 0) < (headTurnThreshold?.rotationAngle ?? -15)) {
      _startProcessing();
      await _completeStep(step: step);
    }
  }

  Future<void> _handlingSmile({required Face face, required LivenessDetectionStep step}) async {
    final smileThreshold = FlutterLivenessDetectionRandomizedPlugin.instance.thresholdConfig.firstWhereOrNull((p0) => p0 is LivenessThresholdSmile) as LivenessThresholdSmile?;
    if ((face.smilingProbability ?? 0) > (smileThreshold?.probability ?? 0.65)) {
      _startProcessing();
      await _completeStep(step: step);
    }
  }
}
