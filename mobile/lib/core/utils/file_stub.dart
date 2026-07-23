import 'dart:typed_data';

abstract class FilePickerHelper {
  Future<Uint8List> readAsBytes(String path);
  bool get isAvailable;
}

FilePickerHelper getFilePickerHelper() => throw UnsupportedError('Cannot create FilePickerHelper');
