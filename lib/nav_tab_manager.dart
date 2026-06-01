import 'package:flutter/material.dart';
import 'package:flutter_finances_wrapped/Transactions/TransactionSheet.dart';
import 'package:flutter_finances_wrapped/user_handling/user_data.dart';
import 'pages/upload_page.dart';
import 'pages/overview_page.dart';
import 'pages/wrapped_page.dart';
import 'app_theme.dart';
import 'package:flutter_finances_wrapped/services/firestore_service.dart';

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

    currentUser!.transactionSheets.clear();
    currentUser!.addTransactionSheet(newSheet); //add the new sheet to user's sheet list
    currentUser!.analyze(); //run analysis on new sheet (updates processed data and total spending in user data object)

    _firestoreService.saveTransactions(
      currentUser!.getAllTransactions().toList(),
    );
    setState(() {}); //setState tells Flutter to rebuild NavTabManager, whcih repasses the updated currentUSer down to all pages
  }

  // to be called in initState to load any saved transactions from Firestore when app starts up
  // called once on startup — checks if user has saved transactions
 // and loads them automatically so they don't have to re-upload
  Future<void> _loadFromFirestore() async {
    final transactions = await _firestoreService.loadTransactions();
    
    // only do something if there's actually saved data
    if (transactions.isEmpty) return;

    // create a TransactionSheet from the loaded transactions
    // we can't use the CSV row format here since we're loading
    // Transaction objects directly from Firestore
    final sheet = TransactionSheet.fromTransactions(transactions);
    
    currentUser!.transactionSheets.clear();
    currentUser!.addTransactionSheet(sheet);
    currentUser!.analyze();

    // setState so all tabs get the freshly loaded data
    setState(() {});
  }


   @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        // IndexedStack keeps all 3 pages alive in memory simultaneously
        // doesnt rebuild everytime user switches tabs, so overview doesntreset every time you switch
        index: _currentIndex, //index can be 0 (home), 1 (overview), 2 (wrapped_)
        children: [
          // pass the callback DOWN to UploadPage so it can report back
          // the user's processed data is also passed to to UploadPage 
          UploadPage(onCsvLoaded: onCsvLoaded, dataAnalysis: currentUser?.processedData),

          // pass the user's processed data DOWN to Overview and Wrapped
          // will be null until a CSV is uploaded, doesnt matter
          OverviewPage(dataAnalysis: currentUser?.processedData),
          WrappedPage(dataAnalysis: currentUser?.processedData),
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