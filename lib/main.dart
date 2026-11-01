
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'video_player_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  runApp(const BurhanPlyerApp());
}

class BurhanPlyerApp extends StatelessWidget {
  const BurhanPlyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Burhan Plyer',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101114),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9D2638),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const VideoPlayerScreen(),
    );
  }
}
