// Copyright Luka Löhr 2026

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../utils/app_logger.dart';

/// Persistent key→string-blob cache backed by files in the app's documents
/// directory (which, unlike the temporary directory, is never purged by the OS).
///
/// Used to persist fetched data (weather JSON, news/events/schedule model lists)
/// so it survives process death and the app can show last-known data instantly
/// on a cold start instead of re-fetching everything over the network.
///
/// Writes are atomic (temp file + rename) so a crash mid-write can never leave a
/// half-written, unparseable cache file. All operations fail soft: any I/O error
/// is treated as a cache miss rather than propagating.
class DiskCache {
  DiskCache._();
  static final DiskCache instance = DiskCache._();

  Directory? _dir;

  Future<Directory> _cacheDir() async {
    final cached = _dir;
    if (cached != null) return cached;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/data_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dir = dir;
    return dir;
  }

  File _fileFor(Directory dir, String name) => File('${dir.path}/$name.json');

  /// Read the cached blob for [name], or null if absent/unreadable.
  Future<String?> read(String name) async {
    try {
      final file = _fileFor(await _cacheDir(), name);
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (e) {
      AppLogger.debug('Read failed for "$name": $e', module: 'DiskCache');
      return null;
    }
  }

  /// Atomically persist [content] under [name].
  Future<void> write(String name, String content) async {
    try {
      final dir = await _cacheDir();
      final tmp = File('${dir.path}/$name.json.tmp');
      await tmp.writeAsString(content, flush: true);
      await tmp.rename(_fileFor(dir, name).path);
    } catch (e) {
      AppLogger.debug('Write failed for "$name": $e', module: 'DiskCache');
    }
  }

  /// Delete the cached blob for [name] (no-op if absent).
  Future<void> delete(String name) async {
    try {
      final file = _fileFor(await _cacheDir(), name);
      if (await file.exists()) await file.delete();
    } catch (e) {
      AppLogger.debug('Delete failed for "$name": $e', module: 'DiskCache');
    }
  }
}
