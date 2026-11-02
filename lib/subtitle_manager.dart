
import 'dart:io';

import 'package:media_kit/media_kit.dart';

class SubtitleManager {
  final Player player;

  SubtitleManager(this.player);

  static const List<String> supportedExtensions = [
    'srt',
    'ass',
    'ssa',
    'vtt',
  ];

  Future<void> load(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      throw Exception('ملف الترجمة غير موجود.');
    }

    final extension = path.split('.').last.toLowerCase();

    if (!supportedExtensions.contains(extension)) {
      throw Exception('صيغة ملف الترجمة غير مدعومة.');
    }

    final subtitleUri = Uri.file(file.absolute.path).toString();

    await player.setSubtitleTrack(
      SubtitleTrack.uri(
        subtitleUri,
        title: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'External Subtitle',
      ),
    );
  }

  Future<void> disable() async {
    await player.setSubtitleTrack(
      SubtitleTrack.no(),
    );
  }

  Future<void> automatic() async {
    await player.setSubtitleTrack(
      SubtitleTrack.auto(),
    );
  }

  Future<void> selectEmbedded(int index) async {
    final tracks = player.state.tracks.subtitle;

    if (index < 0 || index >= tracks.length) {
      throw Exception('مسار الترجمة غير موجود.');
    }

    await player.setSubtitleTrack(tracks[index]);
  }

  List<SubtitleTrack> get availableSubtitles {
    return player.state.tracks.subtitle;
  }

  Future<void> loadAudio(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      throw Exception('ملف الصوت غير موجود.');
    }

    await player.setAudioTrack(
      AudioTrack.uri(
        Uri.file(file.absolute.path).toString(),
        title: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'External Audio',
      ),
    );
  }

  Future<void> selectAudio(int index) async {
    final tracks = player.state.tracks.audio;

    if (index < 0 || index >= tracks.length) {
      throw Exception('مسار الصوت غير موجود.');
    }

    await player.setAudioTrack(tracks[index]);
  }

  List<AudioTrack> get availableAudioTracks {
    return player.state.tracks.audio;
  }
}
