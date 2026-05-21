import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_finances_wrapped/Transactions/TransactionSheet.dart';
import 'package:flutter_finances_wrapped/Transactions/Transaction.dart';
import 'package:flutter_finances_wrapped/Transactions/DataAnalysis.dart';

//UserData class to hold all relevant data for a user including name, username, transaction sheet list and processed data from analysis class
class UserData
{
  final String uid;
  final String username;
  final String firstName;
  var transactionSheets = <TransactionSheet>[];
  DataAnalysis? processedData;
  double totalSpending = 0.0;

  UserData({required this.uid, required this.username, required this.firstName});
  // build UserData object from the currently logged-in Firebase user
  factory UserData.fromFirebaseUser(User user)
  {
    String username = user.email ?? '';
    String firstName = user.displayName ?? '';
    return UserData(uid: user.uid, username: username, firstName: firstName);
  }

  // grab the current user, or null if not logged in
  static UserData? getCurrent()
  {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return UserData.fromFirebaseUser(user); //returns a UserData object built from firebase user
  }

  void addTransactionSheet(TransactionSheet sheet)
  {
    transactionSheets.add(sheet);
  }

  // all transactions across every sheet, flattened
  Set<Transaction> getAllTransactions()
  {
    var all = <Transaction>{};
    for (var sheet in transactionSheets)
    {
      all.addAll(sheet.transactions);
    }
    return all;
  }

//creates data analysis object by passing in user's transaction sheets, then runs categorize and sets total spending
  void analyze()
  {
    processedData = DataAnalysis(sheets: transactionSheets);
    processedData!.categorize();
    totalSpending = processedData!.getTotalSpending();
  }
}