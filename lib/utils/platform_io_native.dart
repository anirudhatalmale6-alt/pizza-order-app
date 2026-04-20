// Native (mobile/desktop) implementations using dart:io
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';

export 'dart:io' show File;

void exitApp() {
  io.exit(0);
}

Future<String> getTemporaryCachePath() async {
  final dir = await getTemporaryDirectory();
  return dir.path;
}

Future<String> getAppDocumentsPath() async {
  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
}
