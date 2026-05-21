import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_finances_wrapped/Transactions/Transaction.dart';
import 'package:flutter_finances_wrapped/Transactions/TransactionSheet.dart';
import 'package:flutter_finances_wrapped/Transactions/DataAnalysis.dart';
import 'package:flutter_finances_wrapped/Transactions/SpendingCategory.dart';
import 'package:csv/csv.dart';

void main() {
  group('DataAnalysis tests', () {
    late TransactionSheet sheet;
    late DataAnalysis analysis;

    setUp(() {
      const csvData = '''
AccountNumber,Date,Description,Category,Note,Amount
100001,04-01-2026,Starbucks,Food,Coffee,6.30
100002,04-01-2026,Shell,Transport,Gas,42.30
100003,04-02-2026,Netflix,Entertainment,Subscription,15.99
100004,04-02-2026,Spotify,Entertainment,Subscription,9.99
100005,04-03-2026,Apartment,Rent,April,1200.00
''';

      final rows = const CsvToListConverter(
        eol: '\n',
        fieldDelimiter: ',',
      ).convert(csvData);

      sheet = TransactionSheet(rows);
      analysis = DataAnalysis(sheets: [sheet]);
      analysis.categorize();
    });

    test('categories are built correctly', () {
      expect(analysis.categories.length, 4);
      expect(analysis.getCategory('Food')?.totalSpending, 6.30);
      expect(analysis.getCategory('Transport')?.totalSpending, 42.30);
      expect(analysis.getCategory('Entertainment')?.totalSpending, 25.98);
      expect(analysis.getCategory('Rent')?.totalSpending, 1200.00);
    });

    test('total spending and transaction counts are correct', () {
      expect(analysis.getTotalSpending(), 1274.58);
      expect(analysis.getTotalTransactionCount(), 5);
    });

    test('top category is found correctly', () {
      final top = analysis.getTopCategory();
      expect(top?.name, 'Rent');
      expect(top?.totalSpending, 1200.00);
    });

    test('spending by day and biggest day are correct', () {
      final byDay = analysis.getSpendingByDay();
      expect(byDay['04-01-2026'], closeTo(48.60, 0.001));
      expect(byDay['04-02-2026'], closeTo(25.98, 0.001));
      expect(byDay['04-03-2026'], closeTo(1200.00, 0.001));
      expect(analysis.getBiggestSpendingDay(), '04-03-2026');
      expect(analysis.getBiggestSpendingDayAmount(), closeTo(1200.00, 0.001));
      expect(analysis.getBiggestSpendingDayVendors(), ['Apartment']);
    });

    test('badge-style helper methods return expected values', () {
      expect(analysis.isCoffeeAddict(), isFalse);
      expect(analysis.isHomebody(), isTrue);
      expect(analysis.isStreamer(), isTrue);
      expect(analysis.isFoodie(), isFalse);
    });

    test('getCategory returns null for unknown category', () {
      expect(analysis.getCategory('Unknown'), isNull);
    });
  });

  group('SpendingCategory tests', () {
    test('adding and removing transactions updates total spending', () {
      final category = SpendingCategory(name: 'Test');
      final transactionA = Transaction('04-05-2026', 'Vendor A', 'Test', 'Note A', '10.00');
      final transactionB = Transaction('04-06-2026', 'Vendor B', 'Test', 'Note B', '5.50');

      category.addTransaction(transactionA);
      category.addTransaction(transactionB);
      expect(category.transactions.length, 2);
      expect(category.totalSpending, 15.50);

      category.removeTransaction(transactionA);
      expect(category.transactions.length, 1);
      expect(category.totalSpending, 5.50);

      category.removeTransaction(transactionA);
      expect(category.transactions.length, 1);
      expect(category.totalSpending, 5.50);
    });
  });
}
