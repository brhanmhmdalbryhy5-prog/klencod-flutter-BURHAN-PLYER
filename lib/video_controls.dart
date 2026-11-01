
import 'package:flutter/material.dart';

class VideoControls extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final bool playing;
  final bool repeat;
  final VoidCallback onPlayPause;
  final VoidCallback onRepeat;
  final VoidCallback onRotate;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onOpenFile;
  final VoidCallback onSubtitle;
  final VoidCallback onMode;

  const VideoControls({
    super.key,
    required this.position,
    required this.duration,
    required this.playing,
    required this.repeat,
    required this.onPlayPause,
    required this.onRepeat,
    required this.onRotate,
    required this.onSeek,
    required this.onOpenFile,
    required this.onSubtitle,
    required this.onMode,
  });

  String formatTime(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds.toDouble();
    final current = position.inMilliseconds.toDouble();

    return Container(
      color: const Color(0xFF171719),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: total <= 0 ? 0 : current.clamp(0, total),
            max: total <= 0 ? 1 : total,
            onChanged: total <= 0
                ? null
                : (v) => onSeek(
                      Duration(milliseconds: v.round()),
                    ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatTime(position)),
              Text(formatTime(duration)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: onOpenFile,
                icon: const Icon(Icons.folder_open),
                tooltip: 'فتح فيديو',
              ),
              IconButton(
                onPressed: onRotate,
                icon: const Icon(Icons.screen_rotation),
                tooltip: 'تدوير',
              ),
              IconButton(
                onPressed: onRepeat,
                icon: Icon(
                  Icons.repeat,
                  color: repeat ? Colors.redAccent : Colors.white,
                ),
                tooltip: 'تكرار',
              ),
              IconButton(
                onPressed: onPlayPause,
                iconSize: 42,
                icon: Icon(
                  playing ? Icons.pause_circle : Icons.play_circle,
                  color: const Color(0xFFE0A0AA),
                ),
              ),
              IconButton(
                onPressed: onSubtitle,
                icon: const Icon(Icons.subtitles),
                tooltip: 'الترجمة',
              ),
              IconButton(
                onPressed: onMode,
                icon: const Icon(Icons.memory),
                tooltip: 'وضع الترميز',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
