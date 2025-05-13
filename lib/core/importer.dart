import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';

final firstNameColumn = RegExp(r'^first\s*name$', caseSensitive: false);
final lastNameColumn = RegExp(r'^last\s*name$', caseSensitive: false);

class NameRecord {
  final String firstName;
  final String lastName;

  String name() => '$firstName $lastName';

  NameRecord({required this.firstName, required this.lastName});
}

Future<Iterable<NameRecord>> importFromCsv() async {
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
  final firstNameColumnIndex = headers.indexWhere(
    (header) => firstNameColumn.hasMatch(header),
  );
  final lastNameColumnIndex = headers.indexWhere(
    (header) => lastNameColumn.hasMatch(header),
  );
  assert(
    !lastNameColumnIndex.isNegative && !firstNameColumnIndex.isNegative,
    "Can not find first name and last name column",
  );

  final parsedName =
      rowsAsListOfValues
          .map(
            (row) => NameRecord(
              firstName: row[firstNameColumnIndex],
              lastName: row[lastNameColumnIndex],
            ),
          )
          .toSet();
  return parsedName;
}
