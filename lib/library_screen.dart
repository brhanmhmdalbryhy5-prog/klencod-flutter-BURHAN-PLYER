
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'video_player_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool loading = true;
  String? error;
  List<AssetPathEntity> folders = [];
  AssetPathEntity? selectedFolder;
  List<AssetEntity> videos = [];

  @override
  void initState() {
    super.initState();
    loadFolders();
  }

  Future<void> loadFolders() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final permission = await PhotoManager.requestPermissionExtend();

      if (!permission.isAuth && !permission.hasAccess) {
        setState(() {
          loading = false;
          error = 'نحتاج إلى إذن الوصول إلى فيديوهات الهاتف.';
        });
        return;
      }

      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        hasAll: false,
      );

      final validFolders = <AssetPathEntity>[];

      for (final path in paths) {
        final count = await path.assetCountAsync;
        if (count > 0) {
          validFolders.add(path);
        }
      }

      if (!mounted) return;

      setState(() {
        folders = validFolders;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'تعذر قراءة مكتبة الفيديوهات: $e';
      });
    }
  }

  Future<void> openFolder(AssetPathEntity folder) async {
    setState(() {
      selectedFolder = folder;
      loading = true;
      videos = [];
      error = null;
    });

    try {
      final result = await folder.getAssetListPaged(
        page: 0,
        size: 200,
      );

      if (!mounted) return;

      setState(() {
        videos = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'تعذر فتح هذا المجلد: $e';
      });
    }
  }

  Future<void> playVideo(AssetEntity video) async {
    try {
      final File? file = await video.file;

      if (file == null || !await file.exists()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر الوصول إلى ملف الفيديو.'),
          ),
        );
        return;
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(
            initialPath: file.path,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الفيديو: $e')),
      );
    }
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    String two(int value) => value.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${two(hours)}:${two(minutes)}:${two(seconds)}';
    }

    return '${two(minutes)}:${two(seconds)}';
  }

  Widget buildFolderCard(AssetPathEntity folder) {
    return FutureBuilder<int>(
      future: folder.assetCountAsync,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Card(
          color: const Color(0xFF1B1D22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openFolder(folder),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF39232A),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      color: Color(0xFFE0A0AA),
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$count فيديو',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_left,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildVideoCard(AssetEntity video) {
    return InkWell(
      onTap: () => playVideo(video),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1D22),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FutureBuilder<Uint8List?>(
                    future: video.thumbnailDataWithSize(
                      const ThumbnailSize(300, 180),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        );
                      }

                      return Container(
                        color: const Color(0xFF292B31),
                        child: const Icon(
                          Icons.video_file,
                          color: Colors.white38,
                          size: 42,
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 7,
                    right: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        formatDuration(video.videoDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white70,
                      size: 38,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Text(
                video.title ?? 'فيديو',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBody() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE0A0AA),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFFE0A0AA),
                size: 45,
              ),
              const SizedBox(height: 12),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: error!.contains('إذن')
                    ? () => PhotoManager.openSetting()
                    : loadFolders,
                child: Text(
                  error!.contains('إذن')
                      ? 'فتح إعدادات الأذونات'
                      : 'إعادة المحاولة',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (selectedFolder == null) {
      if (folders.isEmpty) {
        return const Center(
          child: Text(
            'لم يتم العثور على مجلدات تحتوي على فيديوهات.',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: loadFolders,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            return buildFolderCard(folders[index]);
          },
        ),
      );
    }

    if (videos.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد فيديوهات في هذا المجلد.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return buildVideoCard(videos[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101114),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17191E),
        foregroundColor: Colors.white,
        title: Text(
          selectedFolder?.name ?? 'Burhan Plyer',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: selectedFolder == null
            ? const Icon(
                Icons.play_circle_fill,
                color: Color(0xFFE0A0AA),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    selectedFolder = null;
                    videos = [];
                    error = null;
                  });
                },
              ),
        actions: [
          IconButton(
            onPressed: selectedFolder == null
                ? loadFolders
                : () => openFolder(selectedFolder!),
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: buildBody(),
    );
  }
}
