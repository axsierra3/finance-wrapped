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
  

    //firse delete all existing transactions to prevent duplicates if user re uploads
    final existing = await collection.get();
    for (final doc in existing.docs) {
      await doc.reference.delete(); 
    }

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

      

}


