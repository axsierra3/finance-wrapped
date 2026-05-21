import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

class BalanceSheetCsv {

  static Future<List<List<dynamic>>> readBalanceSheetCsv() async {

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) {
      throw Exception("CSV file not selected");
    }

    final csvText = utf8.decode(result.files.single.bytes!);

    final rows = const CsvToListConverter(
      eol: '\n',
      fieldDelimiter: ',',
    ).convert(csvText);

    return rows;
  }
}

