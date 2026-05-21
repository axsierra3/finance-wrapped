import 'dart:core';

class Transaction
{
    final date;
    final String description;
    final String category;
    final String note;
    final String amount;

    Transaction(this.date, this.description, this.category, this.note, this.amount);
}