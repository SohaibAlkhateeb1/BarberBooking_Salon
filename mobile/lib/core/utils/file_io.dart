import 'dart:io';
import 'dart:typed_data';
import 'file_stub.dart';

class FilePickerHelperImpl implements FilePickerHelper {
  @override
  Future<Uint8List> readAsBytes(String path) async {
    return await File(path).readAsBytes();
  }

  @override
  bool get isAvailable => true;
}

FilePickerHelper getFilePickerHelper() => FilePickerHelperImpl();
