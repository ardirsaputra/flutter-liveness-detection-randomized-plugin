import 'dart:async';
import 'package:flutter/material.dart'; // Tambahkan import yang hilang
import 'package:flutter/cupertino.dart';
import 'package:flutter_liveness_detection_randomized_plugin/index.dart';
import 'package:flutter_liveness_detection_randomized_plugin/src/presentation/widgets/circular_progress_widget/circular_progress_widget.dart';
import 'package:lottie/lottie.dart';

class LivenessDetectionStepOverlayWidget extends StatefulWidget {
  final List<LivenessDetectionStepItem> steps;
  final VoidCallback onCompleted;
  final Widget camera;
  final bool isFaceDetected;
  final bool showCurrentStep;
  final bool isDarkMode;
  final bool showDurationUiText;
  final int? duration;

  const LivenessDetectionStepOverlayWidget({
    super.key,
    required this.steps,
    required this.onCompleted,
    required this.camera,
    required this.isFaceDetected,
    this.showCurrentStep = false,
    this.isDarkMode = true,
    this.showDurationUiText = false,
    this.duration,
  });

  @override
  State<LivenessDetectionStepOverlayWidget> createState() => LivenessDetectionStepOverlayWidgetState();
}

class LivenessDetectionStepOverlayWidgetState extends State<LivenessDetectionStepOverlayWidget> {
  int get currentIndex => _currentIndex;

  bool _isLoading = false;
  int _currentIndex = 0;
  double _currentStepIndicator = 0;
  late final PageController _pageController;
  late CircularProgressWidget _circularProgressWidget;
  Timer? _countdownTimer;
  int _remainingDuration = 0;
  bool _isMounted = false;

  static const double _indicatorMaxStep = 100;
  static const double _heightLine = 25;

  double _getStepIncrement(int stepLength) => stepLength > 0 ? 100 / stepLength : 0;

  String get stepCounter => "$_currentIndex/${widget.steps.length}";

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _initializeControllers();
    _initializeTimer();
  }

  void _initializeControllers() {
    _pageController = PageController(initialPage: 0);
    _circularProgressWidget = _buildCircularIndicator();
  }

  void _initializeTimer() {
    if (widget.duration != null && widget.showDurationUiText) {
      _remainingDuration = widget.duration!;
      _startCountdownTimer();
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel(); // Cancel any existing timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isMounted) {
        timer.cancel();
        return;
      }
      if (_remainingDuration > 0) {
        setState(() => _remainingDuration--);
      } else {
        timer.cancel();
      }
    });
  }

  CircularProgressWidget _buildCircularIndicator() {
    return CircularProgressWidget(
      unselectedColor: Colors.grey,
      selectedColor: Colors.green,
      heightLine: _heightLine,
      current: _currentStepIndicator,
      maxStep: _indicatorMaxStep,
      child: widget.camera,
    );
  }

  @override
  void dispose() {
    _isMounted = false;
    _countdownTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> nextPage() async {
    if (!_isMounted || _isLoading) return;

    try {
      if (_currentIndex + 1 <= widget.steps.length - 1) {
        await _handleNextStep();
      } else {
        await _handleCompletion();
      }
    } catch (e) {
      debugPrint('Error in nextPage: $e');
    }
  }

  Future<void> _handleNextStep() async {
    _showLoader();
    await Future.delayed(const Duration(milliseconds: 100));
    if (_isMounted) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 1),
        curve: Curves.easeIn,
      );
      await Future.delayed(const Duration(seconds: 1));
      _hideLoader();
      _updateState();
    }
  }

  Future<void> _handleCompletion() async {
    _updateState();
    await Future.delayed(const Duration(milliseconds: 500));
    if (_isMounted) {
      widget.onCompleted();
    }
  }

  void _updateState() {
    if (_isMounted) {
      setState(() {
        _currentIndex++;
        _currentStepIndicator += _getStepIncrement(widget.steps.length);
        _circularProgressWidget = _buildCircularIndicator();
      });
    }
  }

  void reset() {
    if (!_isMounted) return;
    _pageController.jumpToPage(0);
    setState(() {
      _currentIndex = 0;
      _currentStepIndicator = 0;
      _circularProgressWidget = _buildCircularIndicator();
      if (widget.duration != null && widget.showDurationUiText) {
        _remainingDuration = widget.duration!;
        _startCountdownTimer();
      }
    });
  }

  void _showLoader() => _isMounted ? setState(() => _isLoading = true) : null;
  void _hideLoader() => _isMounted ? setState(() => _isLoading = false) : null;

  @override
  Widget build(BuildContext context) {
    if (!_isMounted) return const SizedBox.shrink();

    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: Container(
        margin: const EdgeInsets.all(12),
        height: double.infinity,
        width: double.infinity,
        color: Colors.transparent,
        child: Stack(
          children: [
            _buildHeader(),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: () => _isMounted ? Navigator.maybePop(context) : null,
      child: widget.showCurrentStep
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Back', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
                Visibility(
                  visible: widget.showDurationUiText,
                  replacement: const SizedBox.shrink(),
                  child: Text(
                    _getRemainingTimeText(_remainingDuration),
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(stepCounter, style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
              ],
            )
          : Text(
              'Back',
              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
            ),
    );
  }

  Widget _buildBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCircularCamera(),
        const SizedBox(height: 16),
        _buildFaceDetectionStatus(),
        const SizedBox(height: 16),
        _buildStepPageView(),
        const SizedBox(height: 16),
        widget.isDarkMode ? _buildLoaderDarkMode() : _buildLoaderLightMode(),
      ],
    );
  }

  Widget _buildCircularCamera() {
    return SizedBox(
      height: 300,
      width: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1000),
        child: _circularProgressWidget,
      ),
    );
  }

  String _getRemainingTimeText(int duration) {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  Widget _buildFaceDetectionStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          child: widget.isDarkMode
              ? LottieBuilder.asset(
                  widget.isFaceDetected
                      ? 'packages/flutter_liveness_detection_randomized_plugin/src/core/assets/face-detected.json'
                      : 'packages/flutter_liveness_detection_randomized_plugin/src/core/assets/face-id-anim.json',
                  height: widget.isFaceDetected ? 32 : 22,
                  width: widget.isFaceDetected ? 32 : 22,
                )
              : ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    widget.isFaceDetected ? Colors.green : Colors.black,
                    BlendMode.modulate,
                  ),
                  child: LottieBuilder.asset(
                    widget.isFaceDetected
                        ? 'packages/flutter_liveness_detection_randomized_plugin/src/core/assets/face-detected.json'
                        : 'packages/flutter_liveness_detection_randomized_plugin/src/core/assets/face-id-anim.json',
                    height: widget.isFaceDetected ? 32 : 22,
                    width: widget.isFaceDetected ? 32 : 22,
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Text(
          widget.isFaceDetected ? 'User Face Found' : 'User Face Not Found...',
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
        ),
      ],
    );
  }

  Widget _buildStepPageView() {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 10,
      width: MediaQuery.of(context).size.width,
      child: AbsorbPointer(
        absorbing: true,
        child: PageView.builder(
          controller: _pageController,
          itemCount: widget.steps.length,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: _buildStepItem,
        ),
      ),
    );
  }

  Widget _buildStepItem(BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDarkMode ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 30),
        padding: const EdgeInsets.all(10),
        child: Text(
          widget.steps[index].title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoaderDarkMode() {
    return Center(
      child: CupertinoActivityIndicator(
        color: _isLoading ? Colors.white : Colors.transparent,
      ),
    );
  }

  Widget _buildLoaderLightMode() {
    return Center(
      child: CupertinoActivityIndicator(
        color: _isLoading ? Colors.black : Colors.transparent,
      ),
    );
  }
}