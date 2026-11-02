
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
  final ValueChanged<double> onSpeed;

  final double speed;

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
    required this.onSpeed,
    required this.speed,
  });

  String formatTime(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');

    if (d.inHours > 0) {
      return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
    }

    return '${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}';
  }

  void skip(int seconds) {
    final target = position + Duration(seconds: seconds);
    final max = duration.inMilliseconds;

    final safe = Duration(
      milliseconds: target.inMilliseconds.clamp(
        0,
        max > 0 ? max : 0,
      ),
    );

    onSeek(safe);
  }

  @override
  Widget build(BuildContext context) {
    final total = duration.inMilliseconds.toDouble();
    final current = position.inMilliseconds.toDouble();

    return Container(
      width: double.infinity,
      color: const Color(0xFF17191E),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFE05268),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFFE0A0AA),
              overlayColor: const Color(0x33E05268),
              trackHeight: 3,
            ),
            child: Slider(
              value: total <= 0
                  ? 0
                  : current.clamp(0.0, total).toDouble(),
              max: total <= 0 ? 1 : total,
              onChanged: total <= 0
                  ? null
                  : (v) => onSeek(
                        Duration(milliseconds: v.round()),
                      ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatTime(position),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                formatTime(duration),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => skip(-10),
                icon: const Icon(Icons.replay_10),
                color: Colors.white,
                tooltip: 'تراجع 10 ثوانٍ',
              ),

              IconButton(
                onPressed: onPlayPause,
                iconSize: 48,
                icon: Icon(
                  playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: const Color(0xFFE0A0AA),
                ),
                tooltip: playing ? 'إيقاف مؤقت' : 'تشغيل',
              ),

              IconButton(
                onPressed: () => skip(10),
                icon: const Icon(Icons.forward_10),
                color: Colors.white,
                tooltip: 'تقديم 10 ثوانٍ',
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: onOpenFile,
                icon: const Icon(Icons.folder_open),
                color: Colors.white70,
                tooltip: 'فتح فيديو',
              ),

              IconButton(
                onPressed: onRotate,
                icon: const Icon(Icons.screen_rotation),
                color: Colors.white70,
                tooltip: 'ملء الشاشة',
              ),

              IconButton(
                onPressed: onRepeat,
                icon: Icon(
                  Icons.repeat,
                  color: repeat
                      ? const Color(0xFFE05268)
                      : Colors.white70,
                ),
                tooltip: 'تكرار',
              ),

              IconButton(
                onPressed: onSubtitle,
                icon: const Icon(Icons.subtitles),
                color: Colors.white70,
                tooltip: 'الترجمة والصوت',
              ),

              IconButton(
                onPressed: onMode,
                icon: const Icon(Icons.memory),
                color: Colors.white70,
                tooltip: 'وضع الترميز',
              ),

              PopupMenuButton<double>(
                initialValue: speed,
                tooltip: 'سرعة التشغيل',
                color: const Color(0xFF292B31),
                onSelected: onSpeed,
                itemBuilder: (context) => [
                  0.5,
                  0.75,
                  1.0,
                  1.25,
                  1.5,
                  1.75,
                  2.0,
                ].map((value) {
                  return PopupMenuItem<double>(
                    value: value,
                    child: Text(
                      '${value}x',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '${speed}x',
                    style: const TextStyle(
                      color: Color(0xFFE0A0AA),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
