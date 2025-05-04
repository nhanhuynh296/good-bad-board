import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

final columnNames = RegExp(r'^(?:N|n)ame$');

Future<Iterable<String>> importFromCsv() async {
  final pickerResult = await FilePicker.platform.pickFiles(
    dialogTitle: 'Select import data file',
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );
  if (pickerResult == null || pickerResult.files.isEmpty) {
    return const Iterable.empty();
  }

  final content = File(pickerResult.files.first.path!).openRead();
  const converter = CsvToListConverter(eol: '\n');

  List<List<dynamic>> rowsAsListOfValues =
      await content.transform(utf8.decoder).transform(converter).toList();
  final headers = rowsAsListOfValues.removeAt(0);
  final nameIndex = headers.indexWhere(
    (header) => columnNames.hasMatch(header),
  );
  final parsedName =
      rowsAsListOfValues.map((row) => row[nameIndex].toString()).toSet();
  return parsedName;
}
