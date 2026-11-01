
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

  Future<void> playPause() => player.playOrPause();

  Future<void> seek(Duration position) => player.seek(position);

  Future<void> setVolume(double value) {
    return player.setVolume(value.clamp(0, 100).toDouble());
  }

  Future<void> setSpeed(double value) => player.setRate(value);

  Future<void> setRepeat(bool enabled) {
    return player.setPlaylistMode(
      enabled ? PlaylistMode.single : PlaylistMode.none,
    );
  }

  Future<void> dispose() async {
    await player.dispose();
  }
}
