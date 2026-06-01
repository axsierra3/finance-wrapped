import 'package:flutter/material.dart';
import 'package:flutter_finances_wrapped/Transactions/Transaction.dart' as app;
import 'package:flutter_finances_wrapped/Transactions/TransactionSheet.dart';
import 'package:flutter_finances_wrapped/user_handling/user_data.dart';
import 'pages/upload_page.dart';
import 'pages/overview_page.dart';
import 'pages/wrapped_page.dart';
import 'app_theme.dart';
import 'package:flutter_finances_wrapped/services/firestore_service.dart';
import 'package:flutter_finances_wrapped/Transactions/DataAnalysis.dart';

class NavTabManager extends StatefulWidget {
  const NavTabManager({super.key});

  @override
  State<NavTabManager> createState() => _NavTabManagerState();
}

class _NavTabManagerState extends State<NavTabManager> {

  // tracks which tab is currently selected (0 = Home/Upload, 1 = Overview, 2 = Wrapped)
  int _currentIndex = 0;

  // the logged-in user — will be initialized in initState
  UserData? currentUser;
  //separate analysis objects so overview/wrapped always show all time
  // home page respects the selected filter
  DataAnalysis? _allTimeAnalysis; 

//default filter for home page
  String _selectedFilter = 'All Time'; 

//list of available months for filtering 
//populated from available month keys loaded from Firestore (derived from transaction dates)
//ex: ["2026-01", "2026-04"]
  List<String> _availableMonths = [];
  // our connection to Firestore — handles all save/load operations
  final FirestoreService _firestoreService = FirestoreService();

//init state runs only once when NavtTavManager is first created, useful for setup
  @override
  void initState() {
    super.initState(); 
    currentUser = UserData.getCurrent(); //current user is null before login, but set to object later

//load any previously saved transactions from Firestore
//runs async so doesnt block UI from appearing
    _loadFromFirestore();
  }

  void onCsvLoaded(List<List<dynamic>> rows) {
    if (currentUser == null) return; //shouldnt happen, safety check

    final newSheet = TransactionSheet(rows); //create a trans sheet from csv data from upload page

    currentUser!.addTransactionSheet(newSheet); //add the new sheet to user's sheet list
    currentUser!.analyze(); //run analysis on new sheet (updates processed data and total spending in user data object)

    _firestoreService.saveTransactions(
      currentUser!.getAllTransactions().toList(),
    );
    // reload months and reapply filter so UI updates with new data
  _loadFromFirestore();
  }

  // to be called in initState to load any saved transactions from Firestore when app starts up
  // called once on startup — checks if user has saved transactions
 // and loads them automatically so they don't have to re-upload
  Future<void> _loadFromFirestore() async {
  final months = await _firestoreService.getAvailableMonths();
  setState(() { _availableMonths = months; });

  // always load all-time data for overview + wrapped
  final allTransactions = await _firestoreService.loadAllTransactions();
  if (allTransactions.isNotEmpty) {
    final sheet = TransactionSheet.fromTransactions(allTransactions);
    final analysis = DataAnalysis(sheets: [sheet]);
    analysis.categorize();
    setState(() { _allTimeAnalysis = analysis; });
  }

  // then apply the selected filter for home page
  await _applyFilter(_selectedFilter);
}
// applies the selected filter and updates UserData + DataAnalysis
Future<void> _applyFilter(String filter) async {
  if (currentUser == null) return;

  List<app.Transaction> transactions = [];
  final now = DateTime.now();

  if (filter == 'All Time') {
    transactions = await _firestoreService.loadAllTransactions();
  } else if (filter == 'Past Year') {
    final all = await _firestoreService.loadAllTransactions();
    transactions = all.where((t) {
      final date = _parseDate(t.date);
      if (date == null) return false;
      return date.isAfter(now.subtract(const Duration(days: 365)));
    }).toList();
  } else if (filter == 'Last 90 Days') {
    final all = await _firestoreService.loadAllTransactions();
    transactions = all.where((t) {
      final date = _parseDate(t.date);
      if (date == null) return false;
      return date.isAfter(now.subtract(const Duration(days: 90)));
    }).toList();
  } else if (filter == 'Last 60 Days') {
    final all = await _firestoreService.loadAllTransactions();
    transactions = all.where((t) {
      final date = _parseDate(t.date);
      if (date == null) return false;
      return date.isAfter(now.subtract(const Duration(days: 60)));
    }).toList();
  } else {
    // if it's a specific month key like "2026-04"
    transactions = await _firestoreService.loadTransactionsForMonth(filter);
  }

  // rebuild UserData with filtered transactions
  final sheet = TransactionSheet.fromTransactions(transactions);
  currentUser!.transactionSheets.clear();
  currentUser!.addTransactionSheet(sheet);
  currentUser!.analyze();

  setState(() {
    _selectedFilter = filter;
  });
}

// parses "MM-DD-YYYY" into DateTime for date comparisons
DateTime? _parseDate(String dateStr) {
  try {
    final parts = dateStr.split('-');
    if (parts.length != 3) return null;
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  } catch (e) {
    return null;
  }
}

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        // IndexedStack keeps all 3 pages alive in memory simultaneously
        // doesnt rebuild everytime user switches tabs, so overview doesntreset every time you switch
        index: _currentIndex, //index can be 0 (home), 1 (overview), 2 (wrapped_)
        children: [
          // pass the processed data and filter data down to UploadPage
          UploadPage(
              onCsvLoaded: onCsvLoaded,
              dataAnalysis: currentUser?.processedData,
              selectedFilter: _selectedFilter,
              availableMonths: _availableMonths,
              onFilterChanged: (filter) => _applyFilter(filter),
            ),

          // pass the user's processed data DOWN to Overview and Wrapped
          // will be null until a CSV is uploaded, doesnt matter
          OverviewPage(dataAnalysis: _allTimeAnalysis),
          WrappedPage(dataAnalysis: _allTimeAnalysis),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: AppTheme.forestGreen,
        selectedItemColor: AppTheme.softMint,
        unselectedItemColor: const Color.fromARGB(255, 181, 213, 199),

        onTap: (index) {
          setState(() {   //change state to current index/page
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'Wrapped',
          ),
        ],
      ),
    );
  }
}