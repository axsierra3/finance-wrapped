import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_finances_wrapped/Transactions/Transaction.dart';

void main() {
  group('Transaction class tests', () {
  test('Transaction class stores values correctly', () {
    final transaction = Transaction("4-2-2026", "Starbucks", "Food", "Coffee", "6.30");

    expect(transaction.date, "4-2-2026");
    expect(transaction.description, "Starbucks");
    expect(transaction.category, "Food");
    expect(transaction.note, "Coffee");
    expect(transaction.amount, "6.30");

  });
  });
}