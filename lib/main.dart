import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/consent_screen.dart';
import 'state/ekyc_controller.dart';
import 'theme/brand.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const EKycDemoApp());
}

class EKycDemoApp extends StatefulWidget {
  const EKycDemoApp({super.key});

  @override
  State<EKycDemoApp> createState() => _EKycDemoAppState();
}

class _EKycDemoAppState extends State<EKycDemoApp> {
  final EKycController _controller = EKycController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EKycScope(
      controller: _controller,
      child: MaterialApp(
        title: 'eKYC Demo',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const ConsentScreen(),
      ),
    );
  }
}
