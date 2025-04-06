import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class Serializer {
  Serializer._();

  static final Serializer instance = Serializer._();

  Future<File?> pickJsonFile() async {
    final downloadDir = await getDownloadsDirectory();
    final pickerResult = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select saved data file',
      initialDirectory: downloadDir?.path,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return (pickerResult?.files.firstOrNull?.path != null)
        ? File(pickerResult!.files.firstOrNull!.path!)
        : null;
  }
}
