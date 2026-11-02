
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoEngine {
  late final Player player;
  late final VideoController controller;

  final bool hwPlus;

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

  Future<void> open(String path) async {
    await player.open(Media(path));
  }

  Future<void> playPause() async {
    await player.playOrPause();
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  Future<void> setVolume(double value) async {
    final volume = value.clamp(0.0, 100.0).toDouble();
    await player.setVolume(volume);
  }

  Future<void> setSpeed(double value) async {
    final speed = value.clamp(0.25, 3.0).toDouble();
    await player.setRate(speed);
  }

  Future<void> setRepeat(bool enabled) async {
    await player.setPlaylistMode(
      enabled ? PlaylistMode.single : PlaylistMode.none,
    );
  }

  Future<void> dispose() async {
    await player.dispose();
  }
}
