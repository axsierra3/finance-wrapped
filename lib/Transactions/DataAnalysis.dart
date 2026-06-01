import 'dart:core';
import 'SpendingCategory.dart';
import 'TransactionSheet.dart';

class DataAnalysis
{
  var sheets = <TransactionSheet>[]; //list of sheets to analyze, will be all sheets for user data object
  var categories = <String, SpendingCategory>{};

  DataAnalysis({required this.sheets});

  void categorize()
  {
    categories.clear();
    for (var sheet in sheets)
    {
      for (var t in sheet.transactions)
      {
        categories.putIfAbsent(t.category, () => SpendingCategory(name: t.category));
        categories[t.category]!.addTransaction(t);
      }
    }
  }

  SpendingCategory? getCategory(String name)
  {
    return categories[name];
  }

  double getTotalSpending()
  {
    double total = 0.0;
    for (var cat in categories.values)
    {
      total += cat.totalSpending;
    }
    return total;
  }

//returns category w/ highest total spending 
  SpendingCategory? getTopCategory() {
  if (categories.isEmpty) return null;
  return categories.values.reduce(    //reduce (accumulates)finds max by comparing totalSpending of each category
    (a, b) => a.totalSpending > b.totalSpending ? a : b
  );
  }

  // returns total number of transactions across all sheets
  int getTotalTransactionCount() {
    int count = 0;
    for (var sheet in sheets) { //for each sheet in list of sheets, add num transactions
      count += sheet.transactions.length;
    }
    return count;
  }

//map each string date to double total spending for that day accross all sheets, used to find biggest spending day
  Map<String, double> getSpendingByDay() {
    final byDay = <String, double>{};
    for (var sheet in sheets) {
      for (var t in sheet.transactions) {
        final amount = double.tryParse(t.amount) ?? 0.0; //parse amount, default to 0 if invalid
        byDay[t.date] = (byDay[t.date] ?? 0.0) + amount; //add amount to that date key, or initialize if DNE
      }
    }
    return byDay;
  }

  // returns the date string with the highest total spending
  String? getBiggestSpendingDay() {
    final byDay = getSpendingByDay();
    if (byDay.isEmpty) return null;
    return byDay.entries.reduce((a, b) => a.value > b.value ? a : b).key; //reduce to find max spending day
  }

  double getBiggestSpendingDayAmount() {
    final byDay = getSpendingByDay();
    if (byDay.isEmpty) return 0.0;
    return byDay.entries.reduce((a, b) => a.value > b.value ? a : b).value; //reduce to find max spending amount
  }

  // returns list of vendor descriptions on the biggest spending day
  List<String> getBiggestSpendingDayVendors() {
    final biggestDay = getBiggestSpendingDay();
    if (biggestDay == null) return [];
    final vendors = <String>[];   //list of vendors
    for (var sheet in sheets) {
      for (var t in sheet.transactions) {
        if (t.date == biggestDay) vendors.add(t.description); //add description to list of vendors if date macthes
      }
    }
    return vendors;
  }



  // returns map of vendor description -> total amount spent at that vendor on the biggest spending day
  Map<String, double> getBiggestSpendingDayVendorAmounts() {
    final biggestDay = getBiggestSpendingDay();
    if (biggestDay == null) return {};
    final vendors = <String, double>{};
    for (var sheet in sheets) {
      for (var t in sheet.transactions) {
        if (t.date == biggestDay) {
          final amount = double.tryParse(t.amount) ?? 0.0;
          vendors[t.description] = (vendors[t.description] ?? 0.0) + amount; //sum amounts per vendor
        }
      }
    }
    return vendors;
  }

// groups total spending by "YYYY-MM" key
Map<String, double> getSpendingByMonth() {
  final byMonth = <String, double>{};
  for (var sheet in sheets) {
    for (var t in sheet.transactions) {
      final date = _parseDate(t.date);
      if (date == null) continue;
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final amount = double.tryParse(t.amount) ?? 0.0;
      byMonth[key] = (byMonth[key] ?? 0.0) + amount;
    }
  }
  return byMonth;
}

  // returns the month key with the highest total spending
  // e.g. "2026-04"
  String? getBiggestSpendingMonth() {
    final byMonth = getSpendingByMonth();
    if (byMonth.length < 1) return null;
    return byMonth.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // returns total spent in the biggest spending month
  double getBiggestSpendingMonthAmount() {
    final byMonth = getSpendingByMonth();
    if (byMonth.isEmpty) return 0.0;
    return byMonth.values.reduce((a, b) => a > b ? a : b);
  }


  //----BADGES FOR WRAPPED------
 // checks if user is a "coffee addict" — bought coffee 2+ times
  bool isCoffeeAddict() {
    int count = 0;
    final coffeeKeywords = ['starbucks', 'coffee', 'cafe', 'dunkin', 'peet\'s', 'caribou', 'tim hortons']; //list of keywords to identify coffee purchases
    for (var sheet in sheets) {
      for (var t in sheet.transactions) {
        final desc = t.description.toLowerCase();
        if (coffeeKeywords.any((k) => desc.contains(k))) count++;
      }
    }
    return count >= 2;
  } 

  // checks if user is a "homebody" — rent is 30%+ of total spending
  bool isHomebody() {
    final rent = categories['Rent']?.totalSpending ?? 0.0;
    final total = getTotalSpending();
    return total > 0 && (rent / total) >= 0.30;
  }

  // checks if user is a "streamer" — has 2+ subscription services
  bool isStreamer() {
    int count = 0;
    final streamingServices = ['netflix', 'spotify', 'hulu', 'disney', 'apple tv', 'youtube'];
    for (var sheet in sheets) {
      for (var t in sheet.transactions) {
        final desc = t.description.toLowerCase();
        if (streamingServices.any((s) => desc.contains(s))) count++;
      }
    }
    return count >= 2;
  }

  // food is the top spending category
  bool isFoodie() {
    final topCat = getTopCategory();
    return topCat?.name.toLowerCase() == 'food';
  }


// parses "MM-DD-YYYY" into a DateTime object
// returns null if format is unexpected
DateTime? _parseDate(String dateStr) {
  try {
    final parts = dateStr.split('-');
    if (parts.length != 3) return null;
    return DateTime(
      int.parse(parts[2]), // year
      int.parse(parts[0]), // month
      int.parse(parts[1]), // day
    );
  } catch (e) {
    return null;
  }
}

// ── MOST FREQUENT VENDOR ─────────────────────────────
// counts how many times each description appears
// returns the one that appears most
String? getMostFrequentVendor() {
  final counts = <String, int>{};
  for (var sheet in sheets) {
    for (var t in sheet.transactions) {
      counts[t.description] = (counts[t.description] ?? 0) + 1;
    }
  }
  if (counts.isEmpty) return null;
  return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
}

// ── MOST ACTIVE DAY OF WEEK ──────────────────────────
// counts transactions per day of week
// returns the name of the most active day
String? getMostActiveDayOfWeek() {
  final counts = <int, int>{};
  for (var sheet in sheets) {
    for (var t in sheet.transactions) {
      final date = _parseDate(t.date);
      if (date == null) continue;
      counts[date.weekday] = (counts[date.weekday] ?? 0) + 1;
    }
  }
  if (counts.isEmpty) return null;
  final mostActive = counts.entries
      .reduce((a, b) => a.value > b.value ? a : b).key;
  const days = {
    1: 'Monday', 2: 'Tuesday', 3: 'Wednesday',
    4: 'Thursday', 5: 'Friday', 6: 'Saturday', 7: 'Sunday'
  };
  return days[mostActive];
}
}