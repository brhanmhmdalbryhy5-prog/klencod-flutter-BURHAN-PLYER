
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_kit/media_kit.dart';

import 'subtitle_manager.dart';

Future<void> showSubtitleAudioPanel(
  BuildContext context,
  Player player,
) async {
  final manager = SubtitleManager(player);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1B1D22),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'إعدادات الترجمة والصوت',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'الترجمة',
                  style: TextStyle(
                    color: Color(0xFFE0A0AA),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.add_circle_outline,
                      color: Colors.white),
                  title: const Text('تحميل ترجمة خارجية',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['srt', 'ass', 'ssa', 'vtt'],
                    );

                    if (result == null ||
                        result.files.single.path == null) return;

                    try {
                      await manager.load(result.files.single.path!);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تعذر تحميل الترجمة: $e')),
                        );
                      }
                    }
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.subtitles,
                      color: Colors.white),
                  title: const Text('الترجمة التلقائية',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    await manager.automatic();
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.subtitles_off,
                      color: Colors.white),
                  title: const Text('إيقاف الترجمة',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    await manager.disable();
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                ),

                const Divider(color: Colors.white24),

                const Text(
                  'مسارات الترجمة المدمجة',
                  style: TextStyle(
                    color: Color(0xFFE0A0AA),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (manager.availableSubtitles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'لا توجد ترجمات مدمجة.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),

                ...List.generate(
                  manager.availableSubtitles.length,
                  (index) => ListTile(
                    leading: const Icon(Icons.closed_caption,
                        color: Colors.white),
                    title: Text(
                      'مسار الترجمة ${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      await manager.selectEmbedded(index);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                  ),
                ),

                const Divider(color: Colors.white24),

                const Text(
                  'الصوت',
                  style: TextStyle(
                    color: Color(0xFFE0A0AA),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.audio_file,
                      color: Colors.white),
                  title: const Text('تحميل ملف صوت خارجي',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.audio,
                    );

                    if (result == null ||
                        result.files.single.path == null) return;

                    try {
                      await manager.loadAudio(result.files.single.path!);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تعذر تحميل الصوت: $e')),
                        );
                      }
                    }
                  },
                ),

                if (manager.availableAudioTracks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'لا توجد مسارات صوت إضافية.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),

                ...List.generate(
                  manager.availableAudioTracks.length,
                  (index) => ListTile(
                    leading: const Icon(Icons.volume_up,
                        color: Colors.white),
                    title: Text(
                      'مسار الصوت ${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      await manager.selectAudio(index);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
