import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_finances_wrapped/user_handling/user_data.dart';
import 'package:flutter_finances_wrapped/Transactions/TransactionSheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';

class _FakeUser extends Fake implements User {
  @override
  final String uid;

  @override
  final String? email;

  @override
  final String? displayName;

  _FakeUser({required this.uid, this.email, this.displayName});
}

void main() {
  group('UserData backend tests', () {
    const csvData = '''
AccountNumber,Date,Description,Category,Note,Amount
200001,04-01-2026,Starbucks,Food,Coffee,6.30
200002,04-01-2026,Shell,Transport,Gas,42.30
200003,04-02-2026,Netflix,Entertainment,Subscription,15.99
''';

    late TransactionSheet sheet;
    late UserData userData;

    setUp(() {
      final rows = const CsvToListConverter(eol: '\n', fieldDelimiter: ',').convert(csvData);
      sheet = TransactionSheet(rows);
      userData = UserData(uid: 'uid-abc', username: 'test@example.com', firstName: 'Test');
    });

    test('fromFirebaseUser creates UserData from Firebase user fields', () {
      final fakeUser = _FakeUser(
        uid: 'uid-abc',
        email: 'test@example.com',
        displayName: 'Test',
      );

      final fromUser = UserData.fromFirebaseUser(fakeUser);

      expect(fromUser.uid, 'uid-abc');
      expect(fromUser.username, 'test@example.com');
      expect(fromUser.firstName, 'Test');
      expect(fromUser.transactionSheets, isEmpty);
      expect(fromUser.processedData, isNull);
      expect(fromUser.totalSpending, 0.0);
    });

    test('addTransactionSheet and getAllTransactions return flattened transaction set', () {
      userData.addTransactionSheet(sheet);

      final all = userData.getAllTransactions();
      expect(all.length, 3);
      expect(all.map((t) => t.description), containsAll(['Starbucks', 'Shell', 'Netflix']));
    });

    test('analyze populates processedData and computes total spending', () {
      userData.addTransactionSheet(sheet);
      userData.analyze();

      expect(userData.processedData, isNotNull);
      expect(userData.totalSpending, closeTo(64.59, 0.001));
      expect(userData.processedData?.categories.length, 3);
      expect(userData.processedData?.getCategory('Food')?.totalSpending, closeTo(6.30, 0.001));
      expect(userData.processedData?.getCategory('Transport')?.totalSpending, closeTo(42.30, 0.001));
      expect(userData.processedData?.getCategory('Entertainment')?.totalSpending, closeTo(15.99, 0.001));
    });
  });
}
