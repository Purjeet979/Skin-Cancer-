import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DermaScanApp());
}

class DermaScanApp extends StatelessWidget {
  const DermaScanApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DermaScan AI Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0F172A),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        useMaterial3: true,
      ),
      home: const LandingScreen(),
    );
  }
}
