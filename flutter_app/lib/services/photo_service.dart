import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoService {
  PhotoService._internal();
  static final PhotoService instance = PhotoService._internal();

  Future<Directory> _dir() async {
    final d = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(d.path, 'asset_photos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String?> savePhoto(String sourcePath, {required int assetId}) async {
    try {
      final dir = await _dir();
      final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
      final dest = p.join(dir.path, 'asset_${assetId}_${DateTime.now().millisecondsSinceEpoch}$ext');
      await File(sourcePath).copy(dest);
      return dest;
    } catch (_) {
      return null;
    }
  }

  Future<void> deletePhoto(String? path) async {
    if (path == null) return;
    try {
      final dir = await _dir();
      final f = File(path);
      if (await f.exists() && p.isWithin(dir.path, (await f.resolveSymbolicLinks()))) {
        await f.delete();
      }
    } catch (_) {}
  }
}
