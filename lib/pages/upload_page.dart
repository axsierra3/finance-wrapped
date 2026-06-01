import 'package:flutter/material.dart';
import '../services/csv_upload_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_finances_wrapped/Transactions/DataAnalysis.dart';
import 'package:flutter_finances_wrapped/app_theme.dart';


//Upload page widget/ home page
// Shows greeting, upload button, total spending, and spending category cards after CSV upload
class UploadPage extends StatefulWidget {
  final Function(List<List<dynamic>>) onCsvLoaded;
  final DataAnalysis? dataAnalysis; 
  final String selectedFilter;
  final List<String> availableMonths;
  final Function(String) onFilterChanged;
//required onCSvLoaded is a callback function, so it is a function defined in NavTabManager
// when we call it here, execution jumps back up to NavTabManager with params passed in here
// also must recieve processed data from NavTabManager
  const UploadPage({
    super.key,
    required this.onCsvLoaded,
    required this.dataAnalysis, //starts null, but when state rebuilds, nav will update it
    required this.selectedFilter,                 // NEW
    required this.availableMonths,                // NEW
    required this.onFilterChanged,                // NEW
  });

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  static const Color _pageBackground = AppTheme.softMint;
  static const Color _surfaceColor = Colors.white;
  static const Color _headlineColor = AppTheme.darkGreen;
  static const Color _bodyColor = AppTheme.mutedGreen;
  static final Color _borderColor = AppTheme.mintBorder.withValues(alpha: 0.5);

//state variables (allowed to change and will trigger UI rebuilds as they change)
  bool isLoading = false;
  // bool hasUploaded = false; // tracks if CSV has been uploaded this session
  String message = "";

  bool get hasError => message.startsWith("Error");

//waiting funct that calls CSV upload service to pick file and process
  Future<void> pickAndLoadCsv() async {
    setState(() {
      isLoading = true;
      message = "";
    });

    try {
      final rows = await BalanceSheetCsv.readBalanceSheetCsv();
      // send rows up to NavTabManager thru CALLBACK after reading CSV
      //navTabManager will handle creating the sheet, adding it to that user data object, run analyze to categorixe, and rebuild so other pages (overview and wrapped) get it
      widget.onCsvLoaded(rows); 
      setState(() {
        message = "Loaded successfully!";
      });
    } catch (e) {
      setState(() {
        message = "Error: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

//format raw double to $money string
  String _formatCurrency(double value) {
    final isNegative = value < 0;
    final abs = value.abs();
    final fixed = abs % 1 == 0
        ? abs.toStringAsFixed(0)
        : abs.toStringAsFixed(2);
    final parts = fixed.split('.');
    final buffer = StringBuffer();
    for (int i = 0; i < parts[0].length; i++) {
      final fromEnd = parts[0].length - i;
      buffer.write(parts[0][i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(',');
    }
    final dec = parts.length > 1 && parts[1] != '00' ? '.${parts[1]}' : '';
    return '${isNegative ? '-' : ''}\$$buffer$dec';
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Friend';
        //colors of status pill
    final statusBackground = hasError 
        ? const Color(0xFFFEE4E2) 
        : AppTheme.mint.withValues(alpha: 0.4);
    final statusTextColor = hasError
        ? const Color(0xFFB42318)
        : AppTheme.forestGreen;

    // grab categories from dataAnalysis if it exists
    // if null (no CSV yet) this will just be an empty map
    final categories = widget.dataAnalysis?.categories ?? {};
    final totalSpending = widget.dataAnalysis?.getTotalSpending() ?? 0.0;

    return Scaffold(
      backgroundColor: _pageBackground,
      //app bar at top of screen w/ title and logout button
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Finance Wrapped',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGreen,
          ),
        ),
        // logout button in top right
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppTheme.forestGreen),
              tooltip: 'Log out',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                // StreamBuilder in AuthWrapper detects signOut
                // and automatically rebuilds to show SignUpPage
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // greeting
              Text(
                'Hi, $firstName',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _headlineColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                // if csvData is null nobody has uploaded yet → show prompt
                // once csvData exists → show snapshot message
                widget.dataAnalysis == null
                    ? 'Upload your first balance sheet to start unwrapping...'
                    : 'Here\'s your financial snapshot.',
                style: const TextStyle(fontSize: 15, color: _bodyColor),
              ),
              // month filter chips — only show if there's data
              if (widget.availableMonths.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildFilterChips(),
                const SizedBox(height: 16), //room below chips
              ],

              // total spending card — shows -- when no CSV yet
              _buildTotalCard(totalSpending),
              const SizedBox(height: 20),

              // category cards — shows empty state when no CSV yet
              const Text(
                'Spending by Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _headlineColor,
                ),
              ),
              const SizedBox(height: 12),

              // if no data yet show 3 empty placeholder cards
              // if data exists show real category cards
              if (categories.isEmpty)
                ..._buildEmptyCategoryCards()
              else
                ...categories.entries.map((entry) => _buildCategoryCard(
                  category: entry.key,
                  amount: entry.value.totalSpending,
                  total: totalSpending,
                )),

              const SizedBox(height: 24),

              // upload button at the bottom
             const SizedBox(height: 24),

              // upload button at the bottom
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : pickAndLoadCsv,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mintBorder.withValues(alpha: 0.3),
                    foregroundColor: AppTheme.darkGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppTheme.mintBorder.withValues(alpha: 0.5),
                      ),
                    ),
                    elevation: 0,
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ))
                      : const Icon(Icons.upload_file_rounded),
                  label: Text(
                    isLoading ? 'Uploading...' : 'Upload CSV',
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              // status pill only shows after upload attempt
              if (message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusTextColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

// Building the tabs for filtering by fixed time ranges and by months found
Widget _buildFilterChips() {
  // fixed filters always shown first
  final fixedFilters = ['All Time', 'Past Year', 'Last 90 Days', 'Last 60 Days'];

  // format month key "2026-04" → "Apr 2026" for display
  String formatMonth(String key) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final monthNum = int.tryParse(parts[1]) ?? 0;
    return '${months[monthNum]} ${parts[0]}';
  }

  // combine fixed filters + individual months
  final allFilters = [...fixedFilters, ...widget.availableMonths];

  return SizedBox(
    height: 36,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: allFilters.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final filter = allFilters[index];
        final isActive = filter == widget.selectedFilter;
        final label = widget.availableMonths.contains(filter)
            ? formatMonth(filter)
            : filter;

// each chip is a GestureDetector that calls onFilterChanged when tapped, passing the filter it represents
        return GestureDetector(
          onTap: () => widget.onFilterChanged(filter),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              // active = dark green, inactive = light mint
              color: isActive
                  ? AppTheme.darkGreen
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? AppTheme.darkGreen
                    : AppTheme.mintBorder.withValues(alpha: 0.6),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isActive ? AppTheme.mint : AppTheme.mutedGreen,
              ),
            ),
          ),
        );
      },
    ),
  );
}



  // total spending big card near the top
  Widget _buildTotalCard(double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL SPENDING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: AppTheme.mint.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 12),
          //AMOUNT TEXT 
          Text(
            // shows -- if no data yet, real value once CSV loaded
            total == 0.0 ? '--' : _formatCurrency(total),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppTheme.mint,
            ),
          ),
        ],
      ),
    );
  }

  // 3 grey placeholder cards shown before CSV is uploaded
  // gives the page structure so it doesn't look empty
  List<Widget> _buildEmptyCategoryCards() {
    return List.generate(3, (i) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // grey shimmer-ish placeholder bars
          Container(
            width: 100,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFE5EAF0),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Container(
            width: 60,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFE5EAF0),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    ));
  }

  // real category cardw once data exists
  // reusable card widget for each spending category
  // calculates the percentage of total spending for that category to show in the UI
  Widget _buildCategoryCard({
    required String category,
    required double amount,
    required double total,
  }) {
    final percent = total > 0 ? (amount / total * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            category,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _headlineColor,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(amount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.forestGreen,
                ),
              ),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 12, color: _bodyColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}