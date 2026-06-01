import 'package:flutter_finances_wrapped/Transactions/Transaction.dart';

//updated  impelemntation that takes the already parsed csv data from the csv upload service
class TransactionSheet {
  late final sheet;
  late final sheetDatePeriod;
  var transactions = <Transaction>{};
//takes already parsed csv data as list of lists as input
  TransactionSheet(List<List<dynamic>> decodedSheet) {
    this.sheet = decodedSheet;

    for (int line = 1; line < decodedSheet.length; line++) {
      Transaction currentTransaction = Transaction(
        decodedSheet[line][1].toString(), // date
        decodedSheet[line][2].toString(), // description
        decodedSheet[line][3].toString(), // category
        decodedSheet[line][4].toString(), // note
        decodedSheet[line][5].toString(), // amount
      );

      transactions.add(currentTransaction);
    }
  }

  // creates a TransactionSheet directly from Transaction objects
  // used when loading from Firestore instead of parsing a CSV
  TransactionSheet.fromTransactions(List<Transaction> transactions) {
    this.transactions = transactions.toSet();
  }
}