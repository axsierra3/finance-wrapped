import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_finances_wrapped/Transactions/TransactionSheet.dart';
import 'package:csv/csv.dart';

void main() {
  group('TransactionSheet parsing tests', () {
    test('Parses CSV into transactions correctly', () {
      const csvData = '''
AccountNumber,Date,Description,Category,Note,Amount
176542,04-01-2026,Starbucks,Food,Coffee,6.30
123456,04-01-2026,Shell,Transport,Gas,42.30
122357,03-31-2026,Netflix,Entertainment,Subscription,15.99
''';

      final rows = const CsvToListConverter(
        eol: '\n',
        fieldDelimiter: ',',
      ).convert(csvData);

      final sheet = TransactionSheet(rows);

      expect(sheet.transactions.length, 3);

      expect(sheet.transactions.elementAt(0).date, "04-01-2026");
      expect(sheet.transactions.elementAt(0).description, "Starbucks");
      expect(sheet.transactions.elementAt(0).category, "Food");
      expect(sheet.transactions.elementAt(0).note, "Coffee");
      expect(sheet.transactions.elementAt(0).amount, "6.3");

      expect(sheet.transactions.elementAt(1).date, "04-01-2026");
      expect(sheet.transactions.elementAt(1).description, "Shell");
      expect(sheet.transactions.elementAt(1).category, "Transport");
      expect(sheet.transactions.elementAt(1).note, "Gas");
      expect(sheet.transactions.elementAt(1).amount, "42.3");

      expect(sheet.transactions.elementAt(2).date, "03-31-2026");
      expect(sheet.transactions.elementAt(2).description, "Netflix");
      expect(sheet.transactions.elementAt(2).category, "Entertainment");
      expect(sheet.transactions.elementAt(2).note, "Subscription");
      expect(sheet.transactions.elementAt(2).amount, "15.99");
    });
  });
}