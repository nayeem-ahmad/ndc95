import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'file_bytes_loader_stub.dart'
    if (dart.library.io) 'file_bytes_loader_io.dart';

Future<Uint8List?> loadFileBytes(PlatformFile file) async {
  if (file.bytes != null) {
    return file.bytes;
  }
  return await loadFileBytesImpl(file);
}
