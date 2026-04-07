import 'package:flutter/material.dart';

import 'features/auth/presentation/splash_page.dart';

void main() {
  runApp(const AdminFlutterApp());
}

class AdminFlutterApp extends StatelessWidget {
  const AdminFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Booking Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}
