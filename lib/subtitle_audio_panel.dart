
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_kit/media_kit.dart';

import 'subtitle_manager.dart';

Future<void> showSubtitleAudioPanel(
  BuildContext context,
  Player player,
) async {
  final manager = SubtitleManager(player);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1B1D22),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(22),
      ),
    ),
    builder: (sheetContext) {
      // تبقى القيم محفوظة بين تحديثات StatefulBuilder.
      bool busy = false;
      String? message;

      return StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> runAction(
            Future<void> Function() action, {
            String? successMessage,
          }) async {
            if (busy || !sheetContext.mounted) return;

            setSheetState(() {
              busy = true;
              message = null;
            });

            try {
              await action();

              if (!sheetContext.mounted) return;

              setSheetState(() {
                message = successMessage ?? 'تم تنفيذ العملية بنجاح.';
              });
            } catch (error) {
              if (!sheetContext.mounted) return;

              setSheetState(() {
                message = 'تعذر تنفيذ العملية: $error';
              });
            } finally {
              if (sheetContext.mounted) {
                setSheetState(() {
                  busy = false;
                });
              }
            }
          }

          Future<void> pickSubtitle() async {
            if (busy) return;

            try {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['srt', 'ass', 'ssa', 'vtt'],
              );

              if (!sheetContext.mounted ||
                  result == null ||
                  result.files.isEmpty) {
                return;
              }

              final path = result.files.single.path;

              if (path == null || path.trim().isEmpty) {
                setSheetState(() {
                  message = 'تعذر الوصول إلى ملف الترجمة.';
                });
                return;
              }

              await runAction(
                () => manager.load(path),
                successMessage: 'تم تحميل ملف الترجمة.',
              );
            } catch (error) {
              if (!sheetContext.mounted) return;

              setSheetState(() {
                message = 'تعذر اختيار ملف الترجمة: $error';
              });
            }
          }

          Future<void> pickAudio() async {
            if (busy) return;

            try {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.audio,
              );

              if (!sheetContext.mounted ||
                  result == null ||
                  result.files.isEmpty) {
                return;
              }

              final path = result.files.single.path;

              if (path == null || path.trim().isEmpty) {
                setSheetState(() {
                  message = 'تعذر الوصول إلى ملف الصوت.';
                });
                return;
              }

              await runAction(
                () => manager.loadAudio(path),
                successMessage: 'تم تحميل ملف الصوت الخارجي.',
              );
            } catch (error) {
              if (!sheetContext.mounted) return;

              setSheetState(() {
                message = 'تعذر اختيار ملف الصوت: $error';
              });
            }
          }

          final subtitleTracks = manager.availableSubtitles;
          final audioTracks = manager.availableAudioTracks;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'الترجمة والصوت',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'إعدادات الترجمة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE3A1AA),
                      ),
                    ),

                    const SizedBox(height: 8),

                    ListTile(
                      leading: const Icon(Icons.auto_awesome),
                      title: const Text('الترجمة التلقائية'),
                      enabled: !busy,
                      onTap: () => runAction(
                        manager.automatic,
                        successMessage: 'تم تفعيل الترجمة التلقائية.',
                      ),
                    ),

                    ListTile(
                      leading: const Icon(Icons.subtitles_off),
                      title: const Text('إيقاف الترجمة'),
                      enabled: !busy,
                      onTap: () => runAction(
                        manager.disable,
                        successMessage: 'تم إيقاف الترجمة.',
                      ),
                    ),

                    ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: const Text('تحميل ترجمة خارجية'),
                      enabled: !busy,
                      onTap: pickSubtitle,
                    ),

                    const Divider(color: Colors.white12),

                    const Text(
                      'الترجمات المدمجة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (subtitleTracks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'لا توجد مسارات ترجمة مدمجة.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      ...List.generate(subtitleTracks.length, (index) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.closed_caption),
                          title: Text('مسار الترجمة ${index + 1}'),
                          enabled: !busy,
                          onTap: () => runAction(
                            () => manager.selectEmbedded(index),
                            successMessage:
                                'تم اختيار مسار الترجمة ${index + 1}.',
                          ),
                        );
                      }),

                    const Divider(color: Colors.white12),

                    const Text(
                      'إعدادات الصوت',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE3A1AA),
                      ),
                    ),

                    const SizedBox(height: 8),

                    ListTile(
                      leading: const Icon(Icons.audio_file),
                      title: const Text('تحميل ملف صوت خارجي'),
                      enabled: !busy,
                      onTap: pickAudio,
                    ),

                    const Divider(color: Colors.white12),

                    const Text(
                      'المسارات الصوتية المدمجة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    if (audioTracks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'لا توجد مسارات صوتية مدمجة.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    else
                      ...List.generate(audioTracks.length, (index) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.music_note),
                          title: Text('المسار الصوتي ${index + 1}'),
                          enabled: !busy,
                          onTap: () => runAction(
                            () => manager.selectAudio(index),
                            successMessage:
                                'تم اختيار المسار الصوتي ${index + 1}.',
                          ),
                        );
                      }),

                    if (busy) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],

                    if (message != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        message!,
                        style: TextStyle(
                          color: message!.startsWith('تعذر')
                              ? Colors.redAccent
                              : Colors.greenAccent,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => Navigator.pop(sheetContext),
                        child: const Text('إغلاق'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
