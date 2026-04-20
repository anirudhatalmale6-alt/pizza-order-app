import 'package:flutter/material.dart';

/// On web, file paths from XFile are blob URLs — use Image.network
Widget platformFileImage(String path, {double? height, BoxFit? fit}) {
  return Image.network(path, height: height, fit: fit ?? BoxFit.contain);
}
