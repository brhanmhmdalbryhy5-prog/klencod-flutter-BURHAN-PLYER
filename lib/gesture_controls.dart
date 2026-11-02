
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
  double value = 0;

  double startX = 0;
  double startY = 0;
  double startVolume = 100;
  double startBrightness = 0.5;

  Duration startPosition = Duration.zero;
  Duration previewPosition = Duration.zero;

  bool brightnessReady = false;
  bool readingBrightness = false;

  Future<void> startGesture(DragStartDetails details) async {
    startX = details.localPosition.dx;
    startY = details.localPosition.dy;

    startPosition = widget.position;
    previewPosition = widget.position;
    startVolume = widget.volume;

    action = null;
    brightnessReady = false;
    readingBrightness = false;
    value = 0;
  }

  Future<void> updateGesture(
    DragUpdateDetails details,
    BoxConstraints constraints,
  ) async {
    if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
      return;
    }

    final dx = details.localPosition.dx - startX;
    final dy = details.localPosition.dy - startY;

    if (action == null && (dx.abs() > 8 || dy.abs() > 8)) {
      if (dx.abs() > dy.abs()) {
        action = 'seek';
      } else {
        action = startX < constraints.maxWidth / 2
            ? 'brightness'
            : 'volume';

        if (action == 'brightness') {
          readingBrightness = true;
          _readBrightness();
        }
      }

      if (mounted) setState(() {});
    }

    if (action == 'seek') {
      final seconds = dx / constraints.maxWidth * 120;

      final target = startPosition +
          Duration(milliseconds: (seconds * 1000).round());

      final maxDuration = widget.duration.inMilliseconds;

      final safeMilliseconds = target.inMilliseconds.clamp(
        0,
        maxDuration > 0 ? maxDuration : 0,
      );

      previewPosition = Duration(
        milliseconds: safeMilliseconds,
      );

      value = seconds;
    } else if (action == 'volume') {
      final next = (startVolume -
              dy / constraints.maxHeight * 100)
          .clamp(0.0, 100.0)
          .toDouble();

      value = next;
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

      value = next * 100;

      try {
        await ScreenBrightness.instance
            .setApplicationScreenBrightness(next);
      } catch (_) {}
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

      setState(() {});
    } catch (_) {
      if (!mounted) return;

      brightnessReady = false;
      setState(() {});
    } finally {
      readingBrightness = false;
    }
  }

  void endGesture(DragEndDetails details) {
    if (action == 'seek') {
      widget.onSeek(previewPosition);
    }

    if (mounted) {
      setState(() {
        action = null;
      });
    }
  }

  void cancelGesture() {
    if (mounted) {
      setState(() {
        action = null;
      });
    }
  }

  String get actionText {
    if (action == 'seek') {
      final seconds = value.abs().toStringAsFixed(1);
      return value >= 0
          ? '+$seconds ثانية'
          : '-$seconds ثانية';
    }

    if (action == 'volume') {
      return 'الصوت ${value.toStringAsFixed(0)}%';
    }

    if (readingBrightness) {
      return 'جارٍ قراءة السطوع...';
    }

    if (!brightnessReady) {
      return 'تعذر قراءة السطوع';
    }

    return 'السطوع ${value.toStringAsFixed(0)}%';
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
                        color: Colors.black.withValues(alpha: 0.82),
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
}
