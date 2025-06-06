// Copyright Luka Löhr 2025

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';

class FileOpenerService {
  /// Opens a file using the appropriate method for the current platform
  static Future<void> openFile(String filePath) async {
    if (Platform.isMacOS) {
      // On macOS, use the system 'open' command
      final result = await Process.run('open', [filePath]);
      if (result.exitCode != 0) {
        throw Exception('Failed to open file: ${result.stderr}');
      }
    } else if (Platform.isIOS || Platform.isAndroid) {
      // On mobile platforms, use open_filex
      await OpenFilex.open(filePath);
    } else {
      // For other platforms, try using the system default application
      if (Platform.isWindows) {
        final result = await Process.run('start', [filePath], runInShell: true);
        if (result.exitCode != 0) {
          throw Exception('Failed to open file: ${result.stderr}');
        }
      } else if (Platform.isLinux) {
        final result = await Process.run('xdg-open', [filePath]);
        if (result.exitCode != 0) {
          throw Exception('Failed to open file: ${result.stderr}');
        }
      } else {
        throw UnsupportedError('File opening not supported on this platform');
      }
    }
  }
} 