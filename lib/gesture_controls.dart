
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
  double startValue = 0;
  double startX = 0;
  double startY = 0;
  Duration startPosition = Duration.zero;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            startX = details.localPosition.dx;
            startY = details.localPosition.dy;
            startPosition = widget.position;
            startValue = widget.volume;
            action = null;
          },
          onPanUpdate: (details) async {
            final dx = details.localPosition.dx - startX;
            final dy = details.localPosition.dy - startY;

            action ??= dx.abs() > dy.abs()
                ? 'seek'
                : (startX < constraints.maxWidth / 2
                    ? 'brightness'
                    : 'volume');

            if (action == 'seek') {
              final seconds = dx / constraints.maxWidth * 120;
              final target = startPosition +
                  Duration(milliseconds: (seconds * 1000).round());

              final safe = Duration(
                milliseconds: target.inMilliseconds.clamp(
                  0,
                  widget.duration.inMilliseconds > 0
                      ? widget.duration.inMilliseconds
                      : 0,
                ),
              );

              widget.onSeek(safe);
              value = seconds;
            } else if (action == 'volume') {
              final next = (startValue - dy / 2).clamp(0, 100).toDouble();
              widget.onVolume(next);
              value = next;
            } else if (action == 'brightness') {
              try {
                final current = await ScreenBrightness.instance.application;
                final next = (current - dy / constraints.maxHeight)
                    .clamp(0.0, 1.0);
                await ScreenBrightness.instance
                    .setApplicationScreenBrightness(next);
                value = next * 100;
              } catch (_) {}
            }

            if (mounted) setState(() {});
          },
          onPanEnd: (_) {
            if (mounted) {
              setState(() => action = null);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child,
              if (action != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          action == 'seek'
                              ? Icons.swap_horiz
                              : action == 'volume'
                                  ? Icons.volume_up
                                  : Icons.brightness_6,
                          color: Colors.white,
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action == 'seek'
                              ? '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)} ثانية'
                              : '${value.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
