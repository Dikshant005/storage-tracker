import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const StorageMeterApp());

class StorageMeterApp extends StatelessWidget {
  const StorageMeterApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Storage Tracker',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

enum _FileType { image, video, audio, docs }

class _HomePageState extends State<HomePage> {
  final categories = <String, _Bucket>{};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadWithPermission();
  }

  /* ---------- runtime permission ---------- */
  Future<void> _loadWithPermission() async {
    final granted = await _requestPermissions();
    if (granted) {
      await _scan();
    } else {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
    }
  }

  Future<bool> _requestPermissions() async {
    final status = await [
      Permission.storage,
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();
    return status.values.any((p) => p.isGranted);
  }
  /* ---------------------------------------- */

  Future<void> _scan() async {
    print('🔍 scan started');
    final images = await _mediaBucket(
        type: _FileType.image,
        ext: {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'});
    print('📷 Images: ${images.count} files / ${images.bytes} bytes');

    final videos = await _mediaBucket(
        type: _FileType.video,
        ext: {'mp4', 'mkv', 'webm', 'avi', 'mov', '3gp'});
    print('🎥 Videos: ${videos.count} files / ${videos.bytes} bytes');

    final audio = await _mediaBucket(
        type: _FileType.audio,
        ext: {'mp3', 'wav', 'ogg', 'm4a', 'flac', 'aac'});
    print('🎵 Audio: ${audio.count} files / ${audio.bytes} bytes');

    final docs = await _mediaBucket(
        type: _FileType.docs,
        ext: {'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'rtf'});
    print('📄 Docs: ${docs.count} files / ${docs.bytes} bytes');

    final other = await _otherBucket(images, videos, audio, docs);
    print('📦 Other: ${other.count} files / ${other.bytes} bytes');

    print('✅ scan finished');
    setState(() {
      categories
        ..['Images'] = images
        ..['Videos'] = videos
        ..['Audio'] = audio
        ..['Documents'] = docs
        ..['Other'] = other;
      loading = false;
    });
  }

  /* ---------- safe recursive walker ---------- */
  Stream<File> _walk(Directory dir) async* {
    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      if (entity is File) {
        yield entity;
      } else if (entity is Directory) {
        final name = entity.path.split(Platform.pathSeparator).last;
        if (name == 'data' || name == 'obb') continue; // skip protected
        yield* _walk(entity); // recurse
      }
    }
  }
  /* ------------------------------------------- */

  Future<_Bucket> _mediaBucket({
    required _FileType type,
    required Set<String> ext,
  }) async {
    int count = 0;
    int bytes = 0;
    final bucket = _Bucket(count: 0, bytes: 0);
    final dir = Directory('/storage/emulated/0');
    await for (final file in _walk(dir)) {
      final e = file.path.toLowerCase();
      if (!ext.any((x) => e.endsWith('.$x'))) continue;
      try {
        final stat = file.statSync();
        bytes += stat.size;
        count++;
        bucket._files.add(file.path);
      } catch (_) {}
    }
    return _Bucket(count: count, bytes: bytes).._files.addAll(bucket._files);
  }

  Future<_Bucket> _otherBucket(
      _Bucket i, _Bucket v, _Bucket a, _Bucket d) async {
    final scannedPaths = <String>{}
      ..addAll(i._files)
      ..addAll(v._files)
      ..addAll(a._files)
      ..addAll(d._files);

    int count = 0, bytes = 0;
    final root = Directory('/storage/emulated/0');
    await for (final file in _walk(root)) {
      if (scannedPaths.contains(file.path)) continue;
      try {
        bytes += file.statSync().size;
        count++;
      } catch (_) {}
    }
    return _Bucket(count: count, bytes: bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Storage usage')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final key = categories.keys.elementAt(i);
                final b = categories[key]!;
                return ListTile(
                  leading: Icon(_icon(key)),
                  title: Text(key),
                  subtitle: Text('${b.count} files'),
                  trailing: Text(_pretty(b.bytes),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => loading = true);
          _scan();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  IconData _icon(String k) {
    switch (k) {
      case 'Images':
        return Icons.image;
      case 'Videos':
        return Icons.videocam;
      case 'Audio':
        return Icons.audiotrack;
      case 'Documents':
        return Icons.description;
      default:
        return Icons.folder;
    }
  }

  String _pretty(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024)
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
}

class _Bucket {
  final int count;
  final int bytes;
  final Set<String> _files = {};
  _Bucket({required this.count, required this.bytes});
}