
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoEngine {
  late final Player player;
  late final VideoController controller;

  final bool hwPlus;

  bool _disposed = false;

  VideoEngine({this.hwPlus = false}) {
    player = Player(
      configuration: const PlayerConfiguration(
        title: 'Burhan Plyer',
        pitch: true,
        bufferSize: 32 * 1024 * 1024,
      ),
    );

    controller = VideoController(
      player,
      configuration: VideoControllerConfiguration(
        enableHardwareAcceleration: true,
        hwdec: hwPlus ? 'mediacodec' : 'mediacodec-copy',
      ),
    );
  }

  void _checkAvailable() {
    if (_disposed) {
      throw StateError('محرك الفيديو مغلق بالفعل.');
    }
  }

  Future<void> open(String path) async {
    _checkAvailable();
    if (path.trim().isEmpty) {
      throw ArgumentError('مسار الفيديو فارغ.');
    }

    await player.open(Media(path));
  }

  Future<void> play() async {
    _checkAvailable();
    await player.play();
  }

  Future<void> pause() async {
    _checkAvailable();
    await player.pause();
  }

  Future<void> playPause() async {
    _checkAvailable();
    await player.playOrPause();
  }

  Future<void> seek(Duration position) async {
    _checkAvailable();

    final safePosition = position.isNegative
        ? Duration.zero
        : position;

    await player.seek(safePosition);
  }

  Future<void> setVolume(double value) async {
    _checkAvailable();

    final safeVolume = value.clamp(0.0, 100.0).toDouble();
    await player.setVolume(safeVolume);
  }

  Future<void> setSpeed(double value) async {
    _checkAvailable();

    final safeSpeed = value.clamp(0.25, 3.0).toDouble();
    await player.setRate(safeSpeed);
  }

  Future<void> setRepeat(bool enabled) async {
    _checkAvailable();

    await player.setPlaylistMode(
      enabled ? PlaylistMode.single : PlaylistMode.none,
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;

    _disposed = true;
    await player.dispose();
  }
}
