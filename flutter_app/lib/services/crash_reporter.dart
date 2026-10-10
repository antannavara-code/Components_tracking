import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// Lightweight, fully-offline crash logger.
///
/// Catches uncaught Flutter and asynchronous errors, writes a time-stamped
/// crash report to the app's documents directory, and exposes a callback for
/// the UI to surface a friendly error screen. No network is required, keeping
/// the app fully offline.
class CrashReporter {
  CrashReporter._();
  static final CrashReporter instance = CrashReporter._();

  /// Invoked with true when an uncaught error is recorded so the app can
  /// show a recovery screen instead of silently dying.
  VoidCallback? onFatalError;

  bool _hadError = false;
  bool get hadError => _hadError;
  String? _latestError;
  String? get latestError => _latestError;

  /// Install global error handlers. Returns a list of the crash report paths
  /// written so far (empty on a healthy run).
  Future<List<String>> install() async {
    final existing = await _readExistingReports();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _record(details.exceptionAsString(), details.stack?.toString());
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _record(error.toString(), stack.toString());
      return true;
    };

    return existing;
  }

  Future<String?> _reportDir() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final crashDir = Directory('${dir.path}/crash_reports');
      if (!await crashDir.exists()) {
        await crashDir.create(recursive: true);
      }
      return crashDir.path;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> _readExistingReports() async {
    final dirPath = await _reportDir();
    if (dirPath == null) return const [];
    try {
      final crashDir = Directory(dirPath);
      final files = crashDir.existsSync()
          ? crashDir.listSync().whereType<File>().toList()
          : <File>[];
      return files.map((f) => f.path).toList();
    } catch (_) {
      return const [];
    }
  }

  void _record(String error, String? stack) {
    _hadError = true;
    _latestError = error;
    debugPrint('CrashReporter: $error');
    _writeReport(error, stack);
    onFatalError?.call();
  }

  /// Public entry point for widgets/libraries to log a non-fatal error and a
  /// stack trace to the local crash report file.
  void record(String error, StackTrace stack) {
    _record(error, stack.toString());
  }

  Future<void> _writeReport(String error, String? stack) async {
    final dirPath = await _reportDir();
    if (dirPath == null) return;
    final now = DateTime.now();
    final stamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final file = File('$dirPath/crash_$stamp.log');
    try {
      await file.writeAsString(
          'Time: $now\n\n$error\n\n$stack\n', flush: true);
    } catch (_) {}
  }

  /// Delete all previously recorded crash reports. Returns number removed.
  Future<int> clearReports() async {
    final dirPath = await _reportDir();
    if (dirPath == null) return 0;
    var count = 0;
    try {
      final crashDir = Directory(dirPath);
      if (crashDir.existsSync()) {
        for (final f in crashDir.listSync().whereType<File>()) {
          f.deleteSync();
          count++;
        }
      }
    } catch (_) {}
    return count;
  }
}
