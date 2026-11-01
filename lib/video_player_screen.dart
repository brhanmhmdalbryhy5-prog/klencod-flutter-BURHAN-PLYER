
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'video_engine.dart';
import 'video_controls.dart';
import 'gesture_controls.dart';
import 'subtitle_manager.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoEngine engine;

  String? currentPath;
  bool hwPlus = false;
  bool repeat = false;
  bool fullscreen = false;
  double volume = 100;

  @override
  void initState() {
    super.initState();
    engine = VideoEngine();
  }

  Future<void> openVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result == null || result.files.single.path == null) return;

    currentPath = result.files.single.path!;

    await engine.open(currentPath!);
    await WakelockPlus.enable();

    if (mounted) setState(() {});
  }

  Future<void> openSubtitle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'ass', 'ssa', 'vtt'],
    );

    if (result == null || result.files.single.path == null) return;

    try {
      await SubtitleManager(engine.player).load(
        result.files.single.path!,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل الترجمة: $e')),
      );
    }
  }

  Future<void> changeMode() async {
    if (currentPath == null) {
      setState(() => hwPlus = !hwPlus);
      return;
    }

    final oldPosition = engine.player.state.position;
    final path = currentPath!;

    final newMode = !hwPlus;

    await engine.dispose();

    engine = VideoEngine(hwPlus: newMode);
    hwPlus = newMode;

    await engine.open(path);
    await engine.seek(oldPosition);

    if (mounted) setState(() {});
  }

  Future<void> toggleRepeat() async {
    repeat = !repeat;
    await engine.setRepeat(repeat);
    if (mounted) setState(() {});
  }

  Future<void> rotate() async {
    fullscreen = !fullscreen;

    await SystemChrome.setPreferredOrientations(
      fullscreen
          ? [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : [
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ],
    );

    if (mounted) setState(() {});
  }

  String fileName(String? path) {
    if (path == null) return 'Burhan Plyer';
    return path.split('/').last;
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp],
    );
    engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101114),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.play_circle_fill,
                    color: Color(0xFFE0A0AA),
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fileName(currentPath),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: changeMode,
                    child: Text(
                      hwPlus ? 'HW+' : 'HW',
                      style: const TextStyle(
                        color: Color(0xFFE0A0AA),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                color: Colors.black,
                width: double.infinity,
                child: currentPath == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.video_library_outlined,
                              color: Colors.white54,
                              size: 75,
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'Burhan Plyer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: openVideo,
                              icon: const Icon(Icons.folder_open),
                              label: const Text('اختر فيديو'),
                            ),
                          ],
                        ),
                      )
                    : StreamBuilder<Duration>(
                        stream: engine.player.stream.position,
                        builder: (context, snapshot) {
                          final position =
                              snapshot.data ?? Duration.zero;

                          return StreamBuilder<Duration>(
                            stream: engine.player.stream.duration,
                            builder: (context, durationSnapshot) {
                              final duration =
                                  durationSnapshot.data ?? Duration.zero;

                              return GestureControls(
                                position: position,
                                duration: duration,
                                volume: volume,
                                onSeek: (value) {
                                  engine.seek(value);
                                },
                                onVolume: (value) {
                                  volume = value;
                                  engine.setVolume(value);
                                },
                                child: Video(
                                  controller: engine.controller,
                                  controls: NoVideoControls,
                                  subtitleViewConfiguration:
                                      const SubtitleViewConfiguration(
                                    style: TextStyle(
                                      fontSize: 22,
                                      color: Colors.white,
                                      backgroundColor: Color(0xAA000000),
                                    ),
                                    textAlign: TextAlign.center,
                                    padding: EdgeInsets.all(20),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ),

            StreamBuilder<bool>(
              stream: engine.player.stream.playing,
              builder: (context, snapshot) {
                final playing = snapshot.data ?? false;

                return StreamBuilder<Duration>(
                  stream: engine.player.stream.position,
                  builder: (context, positionSnapshot) {
                    return StreamBuilder<Duration>(
                      stream: engine.player.stream.duration,
                      builder: (context, durationSnapshot) {
                        return VideoControls(
                          position: positionSnapshot.data ?? Duration.zero,
                          duration: durationSnapshot.data ?? Duration.zero,
                          playing: playing,
                          repeat: repeat,
                          onPlayPause: () => engine.playPause(),
                          onRepeat: toggleRepeat,
                          onRotate: rotate,
                          onSeek: engine.seek,
                          onOpenFile: openVideo,
                          onSubtitle: openSubtitle,
                          onMode: changeMode,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
