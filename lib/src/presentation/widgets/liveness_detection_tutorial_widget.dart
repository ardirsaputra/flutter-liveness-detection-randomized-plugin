import 'package:flutter/material.dart'; // Tambahkan import yang hilang
import 'package:flutter_liveness_detection_randomized_plugin/index.dart';

class LivenessDetectionTutorialScreen extends StatefulWidget {
  final VoidCallback onStartTap;
  final bool isDarkMode;
  final int? duration;

  const LivenessDetectionTutorialScreen({
    super.key,
    required this.onStartTap,
    this.isDarkMode = false,
    required this.duration,
  });

  @override
  State<LivenessDetectionTutorialScreen> createState() => _LivenessDetectionTutorialScreenState();
}

class _LivenessDetectionTutorialScreenState extends State<LivenessDetectionTutorialScreen> {
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMounted) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            const SizedBox(height: 16),
            Text(
              'Liveness Detection - Tutorial',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            _buildInstructionContainer(context),
            const SizedBox(height: 24),
            _buildStartButton(),
            const SizedBox(height: 10),
            const Spacer(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionContainer(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: widget.isDarkMode ? Colors.black87 : Colors.white,
        boxShadow: !widget.isDarkMode
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          _buildListTile(
            number: '1',
            title: 'Sufficient Lighting',
            subtitle: 'Make sure you are in an area that has sufficient lighting and that your ears are not covered by anything',
          ),
          _buildListTile(
            number: '2',
            title: 'Straight Ahead View',
            subtitle: 'Hold the phone at eye level and look straight at the camera',
          ),
          _buildListTile(
            number: '3',
            title: 'Time Limit Verification',
            subtitle: 'The time limit given for the liveness detection system verification process is ${widget.duration ?? 45} seconds',
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Text(
        number,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: widget.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.isDarkMode ? Colors.black87 : Colors.white,
        foregroundColor: widget.isDarkMode ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: const Icon(Icons.camera_alt_outlined),
      onPressed: _isMounted ? () => widget.onStartTap() : null,
      label: const Text('Start the Liveness Detection System'),
    );
  }

  Widget _buildFooter() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: Colors.grey,
          size: 15,
        ),
        SizedBox(width: 10),
        Text(
          'Package Version: 1.0.4',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
