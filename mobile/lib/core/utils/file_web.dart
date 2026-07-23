import 'dart:typed_data';
import 'file_stub.dart';

class FilePickerHelperWeb implements FilePickerHelper {
  @override
  Future<Uint8List> readAsBytes(String path) async {
    throw UnsupportedError('File path reading not available on web');
  }

  @override
  bool get isAvailable => false;
}

FilePickerHelper getFilePickerHelper() => FilePickerHelperWeb();
