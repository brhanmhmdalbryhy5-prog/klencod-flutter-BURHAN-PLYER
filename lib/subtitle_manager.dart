
import 'package:media_kit/media_kit.dart';

class SubtitleManager {
  final Player player;

  SubtitleManager(this.player);

  Future<void> load(String path) async {
    await player.setSubtitleTrack(
      SubtitleTrack.uri(path),
    );
  }

  Future<void> disable() async {
    await player.setSubtitleTrack(SubtitleTrack.no());
  }

  Future<void> automatic() async {
    await player.setSubtitleTrack(SubtitleTrack.auto());
  }

  Future<void> loadAudio(String path) async {
    await player.setAudioTrack(
      AudioTrack.uri(path),
    );
  }
}
