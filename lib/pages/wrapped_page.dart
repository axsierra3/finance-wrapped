import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_finances_wrapped/Transactions/DataAnalysis.dart';

class WrappedPage extends StatefulWidget {
  final DataAnalysis? dataAnalysis;

  const WrappedPage({super.key, required this.dataAnalysis});

  @override
  State<WrappedPage> createState() => _WrappedPageState();
}

class _WrappedPageState extends State<WrappedPage> {
  int _currentSlide = 0;
  static const int _totalSlides = 6;

  // guess slide state
  String? _userGuess;        // which month the user tapped
  bool _hasGuessed = false;  // whether they've guessed yet

  static const Color _ink = Color(0xFF111111);
  static const Color _cream = Color(0xFFFFF6DF);
  static const Color _spotifyGreen = Color(0xFF1ED760);
  static const List<String> _slideLabels = [
    'Opening',
    'Total',
    'Category',
    'Signature',
    'Biggest month',
    'Peak day',
  ];

//backgroound color gradients for each slide
  final List<List<Color>> _slideGradients = const [
    [Color(0xFF101010), Color(0xFF1ED760)], //0 intro
    [Color(0xFF291B68), Color(0xFF67E8F9)], //1 total
    [Color(0xFF0B3D2E), Color(0xFFF7D154)], //2 top category
    [Color(0xFF4527A0), Color(0xFFFF5C8A)], //3 badge
    [const Color(0xFF1b4332), const Color(0xFF0f3460)], // 4 guess month 
    [Color(0xFF11243C), Color(0xFFFF8A3D)], //5 biggest day
  ];

  _VisualMark _categoryMark(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const _VisualMark(Icons.restaurant_rounded, [
          Color(0xFFFF4D6D),
          Color(0xFFFFC857),
        ]);
      case 'rent':
        return const _VisualMark(Icons.home_rounded, [
          Color(0xFF2DD4BF),
          Color(0xFF134E4A),
        ]);
      case 'transport':
        return const _VisualMark(Icons.directions_car_filled_rounded, [
          Color(0xFF38BDF8),
          Color(0xFF1E3A8A),
        ]);
      case 'entertainment':
        return const _VisualMark(Icons.live_tv_rounded, [
          Color(0xFFA855F7),
          Color(0xFFEC4899),
        ]);
      case 'utilities':
        return const _VisualMark(Icons.bolt_rounded, [
          Color(0xFFFACC15),
          Color(0xFFF97316),
        ]);
      case 'shopping':
        return const _VisualMark(Icons.shopping_bag_rounded, [
          Color(0xFFFB7185),
          Color(0xFF7C3AED),
        ]);
      case 'health':
        return const _VisualMark(Icons.local_hospital_rounded, [
          Color(0xFF34D399),
          Color(0xFF0EA5E9),
        ]);
      case 'tuition':
        return const _VisualMark(Icons.school_rounded, [
          Color(0xFF818CF8),
          Color(0xFF312E81),
        ]);
      default:
        return const _VisualMark(Icons.payments_rounded, [
          Color(0xFF1ED760),
          Color(0xFF14B8A6),
        ]);
    }
  }

  _BadgeInfo _getBadge() {
    if (widget.dataAnalysis == null) {
      return const _BadgeInfo(
        icon: Icons.payments_rounded,
        title: 'Big Spender',
        description: 'Your financial recap is ready for its first spin.',
        colors: [Color(0xFF1ED760), Color(0xFF67E8F9)],
      );
    }
    if (widget.dataAnalysis!.isCoffeeAddict()) {
      return const _BadgeInfo(
        icon: Icons.local_cafe_rounded,
        title: 'Coffee Regular',
        description: 'Coffee showed up enough to earn a spotlight.',
        colors: [Color(0xFFD97706), Color(0xFFFDE68A)],
      );
    }
    if (widget.dataAnalysis!.isFoodie()) {
      return const _BadgeInfo(
        icon: Icons.restaurant_menu_rounded,
        title: 'Food Headliner',
        description: 'Food took the number one slot in your spending mix.',
        colors: [Color(0xFFFF4D6D), Color(0xFFFFC857)],
      );
    }
    if (widget.dataAnalysis!.isStreamer()) {
      return const _BadgeInfo(
        icon: Icons.play_circle_fill_rounded,
        title: 'Stream Team',
        description: 'You kept every service on the roster.',
        colors: [Color(0xFFA855F7), Color(0xFF22D3EE)],
      );
    }
    if (widget.dataAnalysis!.isHomebody()) {
      return const _BadgeInfo(
        icon: Icons.weekend_rounded,
        title: 'Home Base',
        description: 'Rent claimed a major share of your year.',
        colors: [Color(0xFF2DD4BF), Color(0xFF065F46)],
      );
    }
    return const _BadgeInfo(
      icon: Icons.trending_up_rounded,
      title: 'Balanced Listener',
      description: 'Your spending stayed spread across the playlist.',
      colors: [Color(0xFF1ED760), Color(0xFF7C3AED)],
    );
  }

 void _nextSlide() {
  if (_currentSlide == 4 && !_hasGuessed) return; // lock next until guessed
  if (_currentSlide < _totalSlides - 1) {
    setState(() => _currentSlide++);
  }
}

void _prevSlide() {
  if (_currentSlide > 0) {
    setState(() {
      _currentSlide--;
      // reset guess if going back to guess slide
      if (_currentSlide == 4) {
        _userGuess = null;
        _hasGuessed = false;
      }
    });
  }
}
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
    final totalSpending = widget.dataAnalysis?.getTotalSpending() ?? 0.0;
    final txCount = widget.dataAnalysis?.getTotalTransactionCount() ?? 0;
    final topCategory = widget.dataAnalysis?.getTopCategory();
    final biggestDay = widget.dataAnalysis?.getBiggestSpendingDay() ?? '--';
    final biggestDayAmount =
        widget.dataAnalysis?.getBiggestSpendingDayAmount() ?? 0.0;
    final biggestDayVendors =
        widget.dataAnalysis?.getBiggestSpendingDayVendorAmounts() ?? {};
    final badge = _getBadge();
    final gradient = _slideGradients[_currentSlide];
    final biggestMonth = widget.dataAnalysis?.getBiggestSpendingMonth();
    final biggestMonthAmount = widget.dataAnalysis?.getBiggestSpendingMonthAmount() ?? 0.0;
    final availableMonths = widget.dataAnalysis?.getSpendingByMonth().keys.toList() ?? [];

    return Scaffold(
      backgroundColor: gradient.first,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    if (details.globalPosition.dx > screenWidth / 2) {
                      _nextSlide();
                    } else {
                      _prevSlide();
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.98, end: 1).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: _buildSlide(
                      key: ValueKey(_currentSlide),
                      firstName: firstName,
                      totalSpending: totalSpending,
                      txCount: txCount,
                      topCategory: topCategory?.name ?? 'No category yet',
                      topCategoryAmount: topCategory?.totalSpending ?? 0.0,
                      topCategoryPercent: totalSpending > 0
                          ? (topCategory?.totalSpending ?? 0) /
                                totalSpending *
                                100
                          : 0.0,
                      biggestDay: biggestDay,
                      biggestDayAmount: biggestDayAmount,
                      biggestDayVendors: biggestDayVendors,
                      badge: badge,
                      biggestMonth: biggestMonth,
                      biggestMonthAmount: biggestMonthAmount,
                      availableMonths: availableMonths,
                    ),
                  ),
                ),
              ),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Column(
        children: [
          Row(
            children: List.generate(_totalSlides, (index) {
              final active = index <= _currentSlide;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: _ink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: _spotifyGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Finance Wrapped',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${_currentSlide + 1}/$_totalSlides',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
      child: Row(
        children: [
          _roundIconButton(
            icon: Icons.chevron_left_rounded,
            onPressed: _currentSlide > 0 ? _prevSlide : null,
          ),
          const Spacer(),
          Text(
            _slideLabels[_currentSlide],
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _roundIconButton(
            icon: Icons.chevron_right_rounded,
            onPressed: _currentSlide < _totalSlides - 1 ? _nextSlide : null,
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: enabled ? _ink : Colors.white.withValues(alpha: 0.35),
      style: IconButton.styleFrom(
        backgroundColor: enabled
            ? Colors.white
            : Colors.white.withValues(alpha: 0.12),
        fixedSize: const Size(44, 44),
      ),
    );
  }

  Widget _buildSlide({
    required Key key,
    required String firstName,
    required double totalSpending,
    required int txCount,
    required String topCategory,
    required double topCategoryAmount,
    required double topCategoryPercent,
    required String biggestDay,
    required double biggestDayAmount,
    required Map<String, double> biggestDayVendors,
    required _BadgeInfo badge,
    required String? biggestMonth,
    required double biggestMonthAmount,
    required List<String> availableMonths,
  }) {
    //switch  on current slide index tp return the right slide widget, pass in all the data it needs
    switch (_currentSlide) {
      case 0:
        return _slideIntro(key: key, firstName: firstName);
      case 1:
        return _slideTotal(key: key, total: totalSpending, count: txCount);
      case 2:
        return _slideTopCategory(
          key: key,
          category: topCategory,
          amount: topCategoryAmount,
          percent: topCategoryPercent,
        );
      case 3:
        return _slideBadge(key: key, badge: badge);
        case 4: return _slideGuessMonth(
        key: key,
        biggestMonth: biggestMonth,
        biggestMonthAmount: biggestMonthAmount,
        availableMonths: availableMonths,
  );
      case 5:
        return _slideBiggestDay(
          key: key,
          day: biggestDay,
          amount: biggestDayAmount,
          vendors: biggestDayVendors,
        );
      default:
        return _slideIntro(key: key, firstName: firstName);
    }
  }

  Widget _slideIntro({required Key key, required String firstName}) {
    return _slideFrame(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          _miniStoryStack(),
          const SizedBox(height: 34),
          _eyebrow('Your year in review'),
          const SizedBox(height: 12),
          const Text(
            'Finance\nWrapped',
            style: TextStyle(
              color: Colors.white,
              fontSize: 58,
              height: 0.94,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "$firstName's 2026 money recap, mixed from your CSV.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _captionPill(Icons.album_rounded, '2026 recap ready'),
        ],
      ),
    );
  }

  Widget _slideTotal({
    required Key key,
    required double total,
    required int count,
  }) {
    return _slideFrame(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          _iconMark(
            const _VisualMark(Icons.payments_rounded, [
              Color(0xFF1ED760),
              Color(0xFF67E8F9),
            ]),
            size: 92,
          ),
          const SizedBox(height: 28),
          _eyebrow('Total spending'),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 60,
              height: 0.94,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Every dollar you spent, tracked.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 26),
          _glassStatRow([
            _StatItem(Icons.receipt_long_rounded, '$count', 'transactions'),
            //_StatItem(Icons.album_rounded, 'CSV', 'source file'),
          ]),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _slideTopCategory({
    required Key key,
    required String category,
    required double amount,
    required double percent,
  }) {
    final mark = _categoryMark(category);

    return _slideFrame(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _iconMark(mark, size: 104),
              const SizedBox(width: 18),
              Expanded(
                child: _captionPill(Icons.bar_chart_rounded, 'Top category'),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _eyebrow('Your biggest spending category'),
          const SizedBox(height: 12),
          Text(
            category,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              height: 0.98,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 32,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 26),
          _progressBlock(percent),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _slideBadge({required Key key, required _BadgeInfo badge}) {
    return _slideFrame(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                Transform.rotate(
                  angle: -10 * math.pi / 180,
                  child: _badgeCard(badge),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _eyebrow('Your signature'),
          const SizedBox(height: 12),
          Text(
            badge.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 46,
              height: 0.98,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            badge.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 17,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _slideGuessMonth({
  required Key key,
  required String? biggestMonth,
  required double biggestMonthAmount,
  required List<String> availableMonths,
}) {
  // format "2026-04" → "April 2026" for display
  String formatMonth(String key) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final monthNum = int.tryParse(parts[1]) ?? 0;
    return '${months[monthNum]} ${parts[0]}';
  }

  final formattedBiggest = biggestMonth != null
      ? formatMonth(biggestMonth)
      : '—';

  // only show this slide if there are multiple months to guess from
  // if only one month just skip to reveal
  final showGuess = availableMonths.length > 1 && !_hasGuessed;
  final showReveal = _hasGuessed || availableMonths.length <= 1;

  return _slideFrame(
    key: key,
    child: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('BIGGEST SPENDING MONTH',
            style: TextStyle(
              color: Colors.white54, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 20),

          const Text('Which month did you\nspend the most?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.3,
            )),
          const SizedBox(height: 8),

          Text(
            _hasGuessed
                ? (_userGuess == biggestMonth
                    ? 'you know yourself too well'
                    : 'not quite...')
                : 'take a guess before we reveal',
            style: const TextStyle(
              color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // guess buttons — one per available month
          ...availableMonths.map((month) {
            final isCorrect = month == biggestMonth;
            final isGuessed = month == _userGuess;
            final formatted = formatMonth(month);

            Color bgColor = Colors.white.withValues(alpha: 0.1);
            Color borderColor = Colors.white.withValues(alpha: 0.25);
            Color textColor = Colors.white;
            String label = formatted;

            if (_hasGuessed) {
              if (isCorrect) {
                // highlight correct answer in mint
                bgColor = const Color(0xFF4ecca3).withValues(alpha: 0.25);
                borderColor = const Color(0xFF4ecca3);
                textColor = const Color(0xFF4ecca3);
                label = '$formatted ✓';
              } else {
                // dim wrong answers
                bgColor = Colors.red.withValues(alpha: 0.15);
                borderColor = Colors.red.withValues(alpha: 0.3);
                textColor = Colors.white.withValues(alpha: 0.4);
              }
            }

            return GestureDetector(
              onTap: _hasGuessed ? null : () {
                // record the guess and lock buttons
                setState(() {
                  _userGuess = month;
                  _hasGuessed = true;
                });
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            );
          }),

          // reveal card — shows after guessing
          if (showReveal) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Text('YOUR BIGGEST MONTH',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 1,
                    )),
                  const SizedBox(height: 8),
                  Text(
                    formattedBiggest,
                    style: const TextStyle(
                      color: Color(0xFF4ecca3),
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    )),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(biggestMonthAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    )),
                  const SizedBox(height: 8),
                  Text(
                    _userGuess == biggestMonth
                        ? 'you called it. no surprises here.'
                        : 'you really went off that month.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    )),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  Widget _slideBiggestDay({
    required Key key,
    required String day,
    required double amount,
    required Map<String, double> vendors,
  }) {
    return _slideFrame(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          _iconMark(
            const _VisualMark(Icons.calendar_month_rounded, [
              Color(0xFFFF8A3D),
              Color(0xFFFDE68A),
            ]),
            size: 92,
          ),
          const SizedBox(height: 28),
          _eyebrow('Biggest spending day'),
          const SizedBox(height: 12),
          Text(
            day,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 46,
              height: 0.98,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 58,
              height: 0.95,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          _vendorList(vendors),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _slideFrame({required Key key, required Widget child}) {
    return SizedBox(
      key: key,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 12),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _miniStoryStack() {
    return SizedBox(
      height: 138,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 88,
            top: 8,
            child: Transform.rotate(
              angle: 8 * math.pi / 180,
              child: _miniStoryCard(
                color: const Color(0xFF67E8F9),
                icon: Icons.bar_chart_rounded,
              ),
            ),
          ),
          Positioned(
            left: 44,
            top: 18,
            child: Transform.rotate(
              angle: -7 * math.pi / 180,
              child: _miniStoryCard(
                color: const Color(0xFFFF5C8A),
                icon: Icons.local_offer_rounded,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: _miniStoryCard(
              color: _cream,
              icon: Icons.graphic_eq_rounded,
              foreground: _ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStoryCard({
    required Color color,
    required IconData icon,
    Color foreground = Colors.white,
  }) {
    return Container(
      width: 108,
      height: 128,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 28),
          const Spacer(),
          Container(
            width: 48,
            height: 7,
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 76,
            height: 7,
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconMark(_VisualMark mark, {double size = 88}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: mark.colors,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: mark.colors.last.withValues(alpha: 0.34),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Icon(mark.icon, color: Colors.white, size: size * 0.48),
    );
  }

  Widget _eyebrow(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.68),
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }

  Widget _captionPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassStatRow(List<_StatItem> stats) {
    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(stat.icon, color: Colors.white, size: 24),
                const SizedBox(height: 18),
                Text(
                  stat.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  stat.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _progressBlock(double percent) {
    final normalized = (percent / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 12,
            color: Colors.white.withValues(alpha: 0.2),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: normalized,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, _spotifyGreen],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${percent.toStringAsFixed(1)}% of total spending',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _badgeCard(_BadgeInfo badge) {
    return Container(
      width: 138,
      height: 138,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: badge.colors,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(badge.icon, color: Colors.white, size: 54),
          const SizedBox(height: 12),
          Container(
            width: 64,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vendorList(Map<String, double> vendors) {
    final visibleVendors = vendors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topVendors = visibleVendors.take(3).toList();

    if (topVendors.isEmpty) {
      return _captionPill(Icons.storefront_rounded, 'No merchants found');
    }

    return Column(
      children: topVendors.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatCurrency(entry.value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _VisualMark {
  final IconData icon;
  final List<Color> colors;

  const _VisualMark(this.icon, this.colors);
}

class _BadgeInfo {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> colors;

  const _BadgeInfo({
    required this.icon,
    required this.title,
    required this.description,
    required this.colors,
  });
}

class _StatItem {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem(this.icon, this.value, this.label);
}