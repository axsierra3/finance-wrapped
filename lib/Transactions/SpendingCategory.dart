import 'dart:core';
import 'Transaction.dart';

class SpendingCategory
{
  final String name;
  var transactions = <Transaction>[];
  double totalSpending = 0.0;

  SpendingCategory({required this.name});

  void addTransaction(Transaction t)
  {
    transactions.add(t);
    totalSpending += double.tryParse(t.amount) ?? 0.0;
  }

  void removeTransaction(Transaction t)
  {
    if (transactions.remove(t))
    {
      totalSpending -= double.tryParse(t.amount) ?? 0.0;
    }
  }
}