
import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

class GestureControls extends StatefulWidget {
  final Widget child;
  final Duration position;
  final Duration duration;
  final double volume;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onVolume;

  const GestureControls({
    super.key,
    required this.child,
    required this.position,
    required this.duration,
    required this.volume,
    required this.onSeek,
    required this.onVolume,
  });

  @override
  State<GestureControls> createState() => _GestureControlsState();
}

class _GestureControlsState extends State<GestureControls> {
  String? action;

  double startX = 0;
  double startY = 0;
  double startVolume = 100;
  double startBrightness = 0.5;

  Duration startPosition = Duration.zero;
  Duration previewPosition = Duration.zero;

  double previewValue = 0;

  bool brightnessReady = false;
  bool readingBrightness = false;
  bool brightnessFailed = false;

  void startGesture(DragStartDetails details) {
    startX = details.localPosition.dx;
    startY = details.localPosition.dy;

    startPosition = widget.position;
    previewPosition = widget.position;
    startVolume = widget.volume;

    action = null;
    brightnessReady = false;
    readingBrightness = false;
    brightnessFailed = false;
    previewValue = 0;
  }

  void updateGesture(
    DragUpdateDetails details,
    BoxConstraints constraints,
  ) {
    if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
      return;
    }

    final dx = details.localPosition.dx - startX;
    final dy = details.localPosition.dy - startY;

    if (action == null && (dx.abs() > 8 || dy.abs() > 8)) {
      if (dx.abs() > dy.abs()) {
        action = 'seek';
      } else if (startX < constraints.maxWidth / 2) {
        action = 'brightness';
        readingBrightness = true;
        _readBrightness();
      } else {
        action = 'volume';
      }
    }

    if (action == null) return;

    if (action == 'seek') {
      final totalMilliseconds = widget.duration.inMilliseconds;

      if (totalMilliseconds <= 0) return;

      final seconds = dx / constraints.maxWidth * 120;

      final target = startPosition +
          Duration(milliseconds: (seconds * 1000).round());

      final safeMilliseconds = target.inMilliseconds.clamp(
        0,
        totalMilliseconds,
      );

      previewPosition = Duration(milliseconds: safeMilliseconds);
      previewValue = seconds;
    } else if (action == 'volume') {
      final next = (startVolume -
              dy / constraints.maxHeight * 100)
          .clamp(0.0, 100.0)
          .toDouble();

      previewValue = next;
      widget.onVolume(next);
    } else if (action == 'brightness') {
      if (!brightnessReady) {
        if (mounted) setState(() {});
        return;
      }

      final next = (startBrightness -
              dy / constraints.maxHeight)
          .clamp(0.0, 1.0)
          .toDouble();

      previewValue = next * 100;
      _setBrightness(next);
    }

    if (mounted) setState(() {});
  }

  Future<void> _readBrightness() async {
    try {
      final brightness =
          await ScreenBrightness.instance.application;

      if (!mounted || action != 'brightness') return;

      startBrightness = brightness.clamp(0.0, 1.0).toDouble();
      brightnessReady = true;
      readingBrightness = false;

      setState(() {});
    } catch (_) {
      if (!mounted) return;

      brightnessFailed = true;
      brightnessReady = false;
      readingBrightness = false;

      setState(() {});
    }
  }

  Future<void> _setBrightness(double brightness) async {
    try {
      await ScreenBrightness.instance
          .setApplicationScreenBrightness(brightness);
    } catch (_) {
      if (!mounted) return;

      brightnessFailed = true;
      setState(() {});
    }
  }

  void endGesture(DragEndDetails details) {
    if (action == 'seek' &&
        widget.duration > Duration.zero) {
      widget.onSeek(previewPosition);
    }

    if (!mounted) return;

    setState(() {
      action = null;
      readingBrightness = false;
    });
  }

  void cancelGesture() {
    if (!mounted) return;

    setState(() {
      action = null;
      readingBrightness = false;
    });
  }

  String formatTime(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;

    String two(int number) =>
        number.toString().padLeft(2, '0');

    if (safe.inHours > 0) {
      return '${two(safe.inHours)}:'
          '${two(safe.inMinutes.remainder(60))}:'
          '${two(safe.inSeconds.remainder(60))}';
    }

    return '${two(safe.inMinutes)}:'
        '${two(safe.inSeconds.remainder(60))}';
  }

  String get actionText {
    if (action == 'seek') {
      final seconds = previewValue.abs().toStringAsFixed(1);

      return previewValue >= 0
          ? '+$seconds ثانية'
          : '-$seconds ثانية';
    }

    if (action == 'volume') {
      return 'الصوت ${previewValue.toStringAsFixed(0)}%';
    }

    if (readingBrightness) {
      return 'جارٍ قراءة السطوع...';
    }

    if (brightnessFailed) {
      return 'تعذر التحكم بالسطوع';
    }

    if (!brightnessReady) {
      return 'جارٍ تجهيز السطوع...';
    }

    return 'السطوع ${previewValue.toStringAsFixed(0)}%';
  }

  IconData get actionIcon {
    if (action == 'seek') return Icons.swap_horiz;
    if (action == 'volume') return Icons.volume_up;
    return Icons.brightness_6;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: startGesture,
          onPanUpdate: (details) {
            updateGesture(details, constraints);
          },
          onPanEnd: endGesture,
          onPanCancel: cancelGesture,
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,

              if (action != null)
                IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.84),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE0A0AA)
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            actionIcon,
                            color: const Color(0xFFE0A0AA),
                            size: 34,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            actionText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (action == 'seek') ...[
                            const SizedBox(height: 8),
                            Text(
                              '${formatTime(previewPosition)} / ${formatTime(widget.duration)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
