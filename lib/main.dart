import 'package:flutter/material.dart';
import 'package:fyp_passenger/pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Real Time Passenger Management',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 56,
            ),
          ),
          centerTitle: true,
          toolbarHeight: 100,
          backgroundColor: const Color(0xfff4f3ee),
          foregroundColor: Colors.blue[900],
        ),
        body: const HomePage(),
      ),
    );
  }
}
