//Store: Using Firestore database for storing all transactions to Firestore under the user ID on upload
// Load: When the app opens check if user has saved transactions and load them automatically 
// Persistent Sessions: Using Firestore (Google's cloud database) allows us to store custom data like transactions like a giant dictionary of user IDs in the cloud (not RAM), before we only had Firebase Auth to store identity info but nothing else)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_finances_wrapped/Transactions/Transaction.dart' as app;

//FIRESTORE SERVICE:
// handles all reading and wiriting to Firestore
// keeps database logic out of the UI widgets

class FirestoreService {

//the Firestore instance -- connection to database
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //helper to get the current user's ID
  // every user gets own space in Firestore
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

//SAVETRANSACTIONS function is called after CSV upload -- saves all transactions to Firestore
// overwrites any existing transactions for this user, so re uploading replaces the old data
  Future<void> saveTransactions(List<app.Transaction> transactions) async 
  {
    if (_uid == null) return; //safety check -- must b logged in

// reference to this user's transactions subcollection
// path: users/{user_id}/transactions
    final collection = _db 
        .collection('users')
        .doc(_uid)
        .collection('transactions');
  


    // save each transaction as its own new document in the transactions subcollections
    //batch write is more efficient than indv writes bc it writes all in one go
    final batch = _db.batch();
    for (final t in transactions) {
      final docRef = collection.doc(); //auto generate ref
      batch.set(docRef, {
        'date': t.date,
        'description': t.description,
        'amount': t.amount,
        'category': t.category,
        'note': t.note,
        'month': _getMonthKey(t.date), // NEW — "2026-04" format
      });
    }
    await batch.commit(); // sends all writes at once to document at once
  }

  //LOAD TRANSACTIONS
  //called on app load - fetches saved transactions from Firestore by returning as list
  // returns empty list if user has no saved data tet
  Future<List<app.Transaction>> loadTransactions() async {
    if (_uid == null) return []; //not logged in

    final collection = _db 
        .collection('users')
        .doc(_uid)
        .collection('transactions');

        final snapshot = await collection.get();

  //maps each document in trabsactions subcollection to a transaction object and returns as list 
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return app.Transaction(
            data['date'] ?? '',
            data['description'] ?? '',
            data['category'] ?? '',
            data['note'] ?? '',
            data['amount'] ?? '0',
          );
        }).toList();
  }

  //HAS DATA
  // check if user has any saved transactions 
  // used to decide whether to show empty state or transactions list on app load
  Future<bool> hasData() async {
    if (_uid == null) return false; //not logged in

    final snapshot = await  _db
        .collection('users')
        .doc(_uid)
        .collection('transactions')
        .limit(1)
        .get();

        return snapshot.docs.isNotEmpty;
  }

//LOGIC FOR MONTHLY GROUPING 
//--------------------------------
      // converts "04-15-2026" → "2026-04" for grouping by month
      // this format sorts alphabetically = chronologically
      String _getMonthKey(String date) {
        try {
          final parts = date.split('-');
          if (parts.length != 3) return 'unknown';
          return '${parts[2]}-${parts[0].padLeft(2, '0')}'; // year-month
        } catch (e) {
          return 'unknown';
        }
      }

      // returns a sorted list of all months the user has data for
      // e.g. ["2026-01", "2026-03", "2026-04"]
      Future<List<String>> getAvailableMonths() async {
        if (_uid == null) return [];

        final snapshot = await _db
            .collection('users')
            .doc(_uid)
            .collection('transactions')
            .get();

        // collect unique month keys from all transactions
        final months = <String>{};
        for (final doc in snapshot.docs) {
          final month = doc.data()['month'] as String?;
          if (month != null && month != 'unknown') {
            months.add(month);
          }
        }

        // sort so oldest month first
        final sorted = months.toList()..sort();
        return sorted;
      }

        // loads only transactions from a specific month
        // e.g. loadTransactionsForMonth("2026-04")
        Future<List<app.Transaction>> loadTransactionsForMonth(String monthKey) async {
          if (_uid == null) return [];

          final snapshot = await _db
              .collection('users')
              .doc(_uid)
              .collection('transactions')
              .where('month', isEqualTo: monthKey) // filter by month
              .get();

          return snapshot.docs.map((doc) {
            final data = doc.data();
            return app.Transaction(
              data['date'] ?? '',
              data['description'] ?? '',
              data['category'] ?? '',
              data['note'] ?? '',
              data['amount'] ?? '0',
            );
          }).toList();
        }

        // loads ALL transactions for the current user across all months
        // used for "All Time", "Past Year", "Last 90 Days", "Last 60 Days" filters
        Future<List<app.Transaction>> loadAllTransactions() async {
          if (_uid == null) return [];

          final snapshot = await _db
              .collection('users')
              .doc(_uid)
              .collection('transactions')
              .get();

          return snapshot.docs.map((doc) {
            final data = doc.data();
            return app.Transaction(
              data['date'] ?? '',
              data['description'] ?? '',
              data['category'] ?? '',
              data['note'] ?? '',
              data['amount'] ?? '0',
            );
          }).toList();
        }

}


