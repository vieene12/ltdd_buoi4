import 'package:flutter/material.dart';

import 'HomeScreen.dart';
import 'alarm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlarmService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng chuyển đổi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
