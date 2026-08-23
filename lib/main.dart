import 'package:flutter/material.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NTI UI Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFffffff)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFffffff),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return SafeArea(
          top: false,
          bottom: true,
          child: child!,
        );
      },
      home: const Home(),
    );
  }
}