
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
  static const int pageSize = 80;

  bool loading = true;
  bool loadingMore = false;
  bool hasMore = false;
  bool openingVideo = false;

  String? error;

  List<AssetPathEntity> folders = [];
  final Map<String, int> folderCounts = {};

  AssetPathEntity? selectedFolder;
  List<AssetEntity> videos = [];

  int totalVideos = 0;
  int currentPage = 0;

  int _folderRequestId = 0;
  int _moreRequestId = 0;

  @override
  void initState() {
    super.initState();
    loadFolders();
  }

  Future<void> loadFolders() async {
    final requestId = ++_folderRequestId;

    if (!mounted) return;

    setState(() {
      loading = true;
      loadingMore = false;
      error = null;
      selectedFolder = null;
      videos = [];
      hasMore = false;
      totalVideos = 0;
      currentPage = 0;
    });

    try {
      final permission = await PhotoManager.requestPermissionExtend();

      if (!mounted || requestId != _folderRequestId) return;

      if (!permission.hasAccess) {
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
      final counts = <String, int>{};

      for (final path in paths) {
        if (!mounted || requestId != _folderRequestId) return;

        final count = await path.assetCountAsync;

        if (count > 0) {
          validFolders.add(path);
          counts[path.id] = count;
        }
      }

      if (!mounted || requestId != _folderRequestId) return;

      setState(() {
        folders = validFolders;

        folderCounts
          ..clear()
          ..addAll(counts);

        loading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _folderRequestId) return;

      setState(() {
        loading = false;
        error = 'تعذر قراءة مكتبة الفيديوهات: $e';
      });
    }
  }

  Future<void> openFolder(AssetPathEntity folder) async {
    final requestId = ++_folderRequestId;

    if (!mounted) return;

    setState(() {
      selectedFolder = folder;
      loading = true;
      loadingMore = false;
      videos = [];
      error = null;
      currentPage = 0;
      totalVideos = folderCounts[folder.id] ?? 0;
      hasMore = false;
    });

    try {
      final result = await folder.getAssetListPaged(
        page: 0,
        size: pageSize,
      );

      if (!mounted || requestId != _folderRequestId) return;

      setState(() {
        videos = result;
        currentPage = 0;
        hasMore = result.length < totalVideos && result.isNotEmpty;
        loading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _folderRequestId) return;

      setState(() {
        loading = false;
        error = 'تعذر فتح هذا المجلد: $e';
      });
    }
  }

  Future<void> loadMoreVideos() async {
    final folder = selectedFolder;

    if (folder == null || loadingMore || loading || !hasMore) {
      return;
    }

    final requestId = ++_moreRequestId;
    final folderId = folder.id;
    final nextPage = currentPage + 1;

    setState(() {
      loadingMore = true;
    });

    try {
      final result = await folder.getAssetListPaged(
        page: nextPage,
        size: pageSize,
      );

      if (!mounted ||
          requestId != _moreRequestId ||
          selectedFolder?.id != folderId) {
        return;
      }

      setState(() {
        videos.addAll(result);
        currentPage = nextPage;
        hasMore = result.isNotEmpty && videos.length < totalVideos;
        loadingMore = false;
      });
    } catch (e) {
      if (!mounted ||
          requestId != _moreRequestId ||
          selectedFolder?.id != folderId) {
        return;
      }

      setState(() {
        loadingMore = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تحميل بقية الفيديوهات: $e'),
        ),
      );
    }
  }

  Future<void> refreshCurrent() async {
    if (selectedFolder == null) {
      await loadFolders();
    } else {
      final folder = selectedFolder!;
      await openFolder(folder);
    }
  }

  Future<void> playVideo(AssetEntity video) async {
    if (openingVideo) return;

    setState(() {
      openingVideo = true;
    });

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
        SnackBar(
          content: Text('تعذر فتح الفيديو: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          openingVideo = false;
        });
      }
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
    final count = folderCounts[folder.id] ?? 0;

    return Card(
      color: const Color(0xFF1B1D22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: loading ? null : () => openFolder(folder),
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
  }

  Widget buildVideoCard(AssetEntity video) {
    return InkWell(
      onTap: openingVideo ? null : () => playVideo(video),
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
                          width: double.infinity,
                          errorBuilder: (_, __, ___) {
                            return _thumbnailPlaceholder();
                          },
                        );
                      }

                      return _thumbnailPlaceholder();
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

  Widget _thumbnailPlaceholder() {
    return Container(
      color: const Color(0xFF292B31),
      child: const Center(
        child: Icon(
          Icons.video_file,
          color: Colors.white38,
          size: 42,
        ),
      ),
    );
  }

  Widget buildPermissionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_off_outlined,
              color: Color(0xFFE0A0AA),
              size: 45,
            ),
            const SizedBox(height: 12),
            Text(
              error ?? 'حدث خطأ غير معروف.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () async {
                await PhotoManager.openSetting();
                if (mounted) await loadFolders();
              },
              icon: const Icon(Icons.settings),
              label: const Text('فتح إعدادات الأذونات'),
            ),
            TextButton(
              onPressed: loadFolders,
              child: const Text('إعادة المحاولة'),
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
      return buildPermissionError();
    }

    if (selectedFolder == null) {
      if (folders.isEmpty) {
        return RefreshIndicator(
          onRefresh: loadFolders,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 180),
              Center(
                child: Text(
                  'لم يتم العثور على مجلدات تحتوي على فيديوهات.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: loadFolders,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: folders.length,
          itemBuilder: (context, index) {
            return buildFolderCard(folders[index]);
          },
        ),
      );
    }

    if (videos.isEmpty) {
      return RefreshIndicator(
        onRefresh: refreshCurrent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(
              child: Text(
                'لا توجد فيديوهات في هذا المجلد.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshCurrent,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
          childAspectRatio: 1.18,
        ),
        itemCount: videos.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < videos.length) {
            return buildVideoCard(videos[index]);
          }

          return InkWell(
            onTap: loadingMore ? null : loadMoreVideos,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1B1D22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: loadingMore
                    ? const CircularProgressIndicator(
                        color: Color(0xFFE0A0AA),
                      )
                    : const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.expand_more,
                            color: Color(0xFFE0A0AA),
                            size: 35,
                          ),
                          SizedBox(height: 5),
                          Text(
                            'تحميل المزيد',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: selectedFolder == null
            ? const Icon(
                Icons.play_circle_fill,
                color: Color(0xFFE0A0AA),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ++_folderRequestId;
                  ++_moreRequestId;

                  setState(() {
                    selectedFolder = null;
                    videos = [];
                    error = null;
                    loading = false;
                    loadingMore = false;
                    hasMore = false;
                  });
                },
              ),
        actions: [
          IconButton(
            onPressed: refreshCurrent,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Stack(
        children: [
          buildBody(),
          if (openingVideo)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55000000),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFE0A0AA),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
