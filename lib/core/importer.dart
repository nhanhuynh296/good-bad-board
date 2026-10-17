import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:good_bad_board/model/player.dart';

final firstNameColumn = RegExp(r'first\s*name', caseSensitive: false);
final lastNameColumn = RegExp(r'last\s*name', caseSensitive: false);
final gradeColumn = RegExp(r'grade', caseSensitive: false);

class NameRecord {
  final String firstName;
  final String lastName;
  final Elo? elo;

  String name() => '$firstName $lastName';

  NameRecord({required this.firstName, required this.lastName, this.elo});
}

/// [dialogTitle] is the (localised) title for the file picker.
Future<Iterable<NameRecord>> importFromCsv({
  required String dialogTitle,
}) async {
  final pickerResult = await FilePicker.platform.pickFiles(
    dialogTitle: dialogTitle,
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );
  if (pickerResult == null || pickerResult.files.isEmpty) {
    return const Iterable.empty();
  }

  final content = File(pickerResult.files.first.path!).openRead();
  const converter = CsvToListConverter();

  List<List<dynamic>> rowsAsListOfValues = await content
      .transform(utf8.decoder)
      .transform(converter)
      .toList();
  final headers = rowsAsListOfValues.removeAt(0);
  final firstNameColumnIndex = headers.indexWhere(
    (header) => firstNameColumn.hasMatch(header),
  );
  final lastNameColumnIndex = headers.indexWhere(
    (header) => lastNameColumn.hasMatch(header),
  );
  final gradeColumnIndex = headers.indexWhere(
    (header) => gradeColumn.hasMatch(header),
  );
  assert(
    !lastNameColumnIndex.isNegative && !firstNameColumnIndex.isNegative,
    "Can not find first name and last name column",
  );

  final parsedName = rowsAsListOfValues.map((row) {
    return NameRecord(
      firstName: row[firstNameColumnIndex],
      lastName: row[lastNameColumnIndex],
      elo: gradeColumnIndex.isNegative
          ? null
          : Elo.values.firstWhereOrNull(
              (elo) =>
                  elo.name == row[gradeColumnIndex].toString().toLowerCase(),
            ),
    );
  }).toSet();
  return parsedName;
}
