import 'dart:io';
import 'package:flutter/material.dart';

/// On native, use Image.file with dart:io.File
Widget platformFileImage(String path, {double? height, BoxFit? fit}) {
  return Image.file(File(path), height: height, fit: fit ?? BoxFit.contain);
}
