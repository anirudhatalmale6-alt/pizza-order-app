// Stub for web - provides no-op implementations
import 'dart:typed_data';

class File {
  final String path;
  File(this.path);
  bool existsSync() => false;
  Future<File> copy(String newPath) async => File(newPath);
  Future<Uint8List> readAsBytes() async => Uint8List(0);
}

void exitApp() {
  // no-op on web
}

Future<String> getTemporaryCachePath() async => '';
Future<String> getAppDocumentsPath() async => '';
