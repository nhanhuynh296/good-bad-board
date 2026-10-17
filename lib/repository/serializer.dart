import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class Serializer {
  Serializer._();

  static final Serializer instance = Serializer._();

  /// [dialogTitle] is the (localised) title for the file picker.
  Future<File?> pickJsonFile({required String dialogTitle}) async {
    final downloadDir = await getDownloadsDirectory();
    final pickerResult = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      initialDirectory: downloadDir?.path,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return (pickerResult?.files.firstOrNull?.path != null)
        ? File(pickerResult!.files.firstOrNull!.path!)
        : null;
  }
}
