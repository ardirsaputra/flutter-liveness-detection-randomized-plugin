import 'package:flutter_liveness_detection_randomized_plugin/index.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomeView(),
  ));
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  List<String?> capturedImages = [];
  String? imgPath;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        children: [
          if (imgPath != null) ...[
            const Text(
              'Result Liveness Detection',
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 12,
            ),
            Align(
              child: SizedBox(
                height: 100,
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(imgPath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
          ],
          ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt_rounded),
              onPressed: () async {
<<<<<<< HEAD
                final String? response = await FlutterLivenessDetectionRandomizedPlugin.instance.livenessDetection(
                  showCurrentStep: true,
=======
                final String? response =
                    await FlutterLivenessDetectionRandomizedPlugin.instance
                        .livenessDetection(
>>>>>>> 5cab1b465aa5ef1dafc4812b4fb096e3ff365c17
                  context: context,
                  config: LivenessDetectionConfig(
                    durationLivenessVerify:
                        60, // default duration value is 45 second
                    showDurationUiText: true,
                    startWithInfoScreen: true,
                    useCustomizedLabel: true,
                    // provide an empty string if you want to pass the liveness challenge
                    customizedLabel: LivenessDetectionLabelModel(
                      blink: 'Berkedip',
                      lookDown: 'Tengok bawah',
                      lookLeft: 'Tengok kiri',
                      lookRight: 'Tengok kanan',
                      lookUp: 'Tengok atas',
                      smile: 'Senyum',
                    ),
                  ),
                  isEnableSnackBar: true,
                  shuffleListWithSmileLast: true,
                  isDarkMode: false,
                  showCurrentStep: true,
                );
                if (mounted) {
                  setState(() {
                    imgPath = response;
                  });
                }
              },
              label: const Text('Liveness Detection System')),
        ],
      )),
    );
  }
}
