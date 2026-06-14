import 'package:flutter/material.dart';
import 'screens/index_screen.dart';

void main() {
  runApp(const YogaApp());
}

class YogaApp extends StatelessWidget {
  const YogaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext WidgetContext) {
    return MaterialApp(
      title: 'Yoga Retail Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
      ),
      home: const IndexScreen(),
    );
  }
}