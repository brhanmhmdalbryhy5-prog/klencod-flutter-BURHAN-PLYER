
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
  final String? initialPath;

  const VideoPlayerScreen({
    super.key,
    this.initialPath,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoEngine engine;

  String? currentPath;
  bool hwPlus = false;
  bool repeat = false;
  bool fullscreen = false;
  bool opening = false;
  double volume = 100;

  @override
  void initState() {
    super.initState();
    engine = VideoEngine();

    if (widget.initialPath != null) {
      currentPath = widget.initialPath;
      opening = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        openInitialVideo();
      });
    }
  }

  Future<void> openInitialVideo() async {
    final path = widget.initialPath;
    if (path == null) return;

    try {
      await engine.open(path);
      await WakelockPlus.enable();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تشغيل الفيديو: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => opening = false);
      }
    }
  }

  Future<void> openVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;

    try {
      setState(() {
        currentPath = path;
        opening = true;
      });

      await engine.open(path);
      await WakelockPlus.enable();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الفيديو: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => opening = false);
      }
    }
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال ملف الترجمة للمشغل.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل الترجمة: $e')),
      );
    }
  }

  Future<void> changeMode() async {
    if (currentPath == null || opening) {
      if (currentPath == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('افتح فيديو أولاً.')),
        );
      }
      return;
    }

    final oldPosition = engine.player.state.position;
    final wasPlaying = engine.player.state.playing;
    final path = currentPath!;
    final newMode = !hwPlus;

    setState(() => opening = true);

    try {
      await engine.dispose();

      engine = VideoEngine(hwPlus: newMode);
      hwPlus = newMode;

      await engine.open(path);
      await engine.seek(oldPosition);

      if (wasPlaying) {
        await engine.player.play();
      }

      await engine.setVolume(volume);
      await engine.setRepeat(repeat);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تغيير وضع الترميز: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  Future<void> toggleRepeat() async {
    repeat = !repeat;
    await engine.setRepeat(repeat);

    if (mounted) setState(() {});
  }

  Future<void> rotate() async {
    fullscreen = !fullscreen;

    await SystemChrome.setEnabledSystemUIMode(
      fullscreen
          ? SystemUiMode.immersiveSticky
          : SystemUiMode.edgeToEdge,
    );

    await SystemChrome.setPreferredOrientations(
      fullscreen
          ? [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : [
              DeviceOrientation.portraitUp,
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
        top: !fullscreen,
        bottom: !fullscreen,
        child: Column(
          children: [
            if (!fullscreen)
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
                      onPressed: opening ? null : changeMode,
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
                        child: ElevatedButton.icon(
                          onPressed: openVideo,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('اختر فيديو'),
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          StreamBuilder<Duration>(
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
                                          backgroundColor:
                                              Color(0xAA000000),
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

                          if (opening)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFE0A0AA),
                                ),
                              ),
                            ),

                          if (fullscreen)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: IconButton(
                                onPressed: rotate,
                                icon: const Icon(
                                  Icons.fullscreen_exit,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),

            if (!fullscreen)
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
                            position:
                                positionSnapshot.data ?? Duration.zero,
                            duration:
                                durationSnapshot.data ?? Duration.zero,
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
