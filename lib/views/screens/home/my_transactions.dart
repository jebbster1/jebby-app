import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jebby/constants/color.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../services/provider/sign_in_provider.dart';
import '../../../models/user_model.dart';
import '../../../models/stripe_transactions_model.dart';
import 'package:jebby/repositories/api_repository.dart';
import '../../../view_models/user_view_model.dart';

class MyTransactionsScreen extends StatefulWidget {
  const MyTransactionsScreen({super.key});

  @override
  State<MyTransactionsScreen> createState() => _MyTransactionsScreenState();
}

class _MyTransactionsScreenState extends State<MyTransactionsScreen> with WidgetsBindingObserver {
  static const String _interRegular = 'Inter, Regular';
  static const String _interBold = 'Inter, Bold';

  bool isLoading = true;
  bool isError = false;
  bool isEmpty = false;

  Future getData() async {
    final sp = context.read<SignInProvider>();
    final usp = context.read<UserViewModel>();
    usp.getUser();
    sp.getDataFromSharedPreferences();
  }

  Future<UserModel> getUserDate() => UserViewModel().getUser();

  String? token;
  String sourceId = "";
  String? fullname;
  String? email;
  String? role;

  static final NumberFormat _moneyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  /// Matches summary row in design: space after dollar (e.g. `$ 300.24`).
  static final NumberFormat _summaryMoneyFormat = NumberFormat.currency(
    symbol: '\$ ',
    decimalDigits: 2,
  );

  void profileData(BuildContext context) async {
    getUserDate()
        .then((value) async {
          token = value.token.toString();
          sourceId = value.id.toString();
          fullname = value.name.toString();
          email = value.email.toString();
          role = value.role.toString();
          getUserTransactions();
        })
        .onError((error, stackTrace) {
          if (kDebugMode) {}
        });
  }

  void getUserTransactions() {
    ApiRepository.shared.getUserStripeTransactions(
      sourceId,
      (StripeTransactionsModel data) {
        if (this.mounted) {
          if (data.data == null || data.data!.isEmpty) {
            setState(() {
              isLoading = false;
              isEmpty = true;
              isError = false;
            });
          } else {
            setState(() {
              isLoading = false;
              isError = false;
              isEmpty = false;
            });
          }
        }
      },
      (error) {
        if (error != null) {
          setState(() {
            isLoading = false;
            isError = true;
            isEmpty = false;
          });
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getData();
    profileData(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh data when app becomes active
    if (state == AppLifecycleState.resumed && sourceId.isNotEmpty) {
      getUserTransactions();
    }
  }

  Widget transactionCard(String productName, String totalPrice, String status, String date, String paymentMethod) {
    final amount = double.tryParse(totalPrice) ?? 0;
    final incoming = amount >= 0;
    final txDate = _tryParseDate(date) ?? DateTime.now();
    return _buildTransactionRow(
      title: productName,
      date: txDate,
      amount: amount,
      isIncoming: incoming,
      status: status,
      method: paymentMethod,
    );
  }

  DateTime? _tryParseDate(String value) {
    try {
      return DateFormat('MMM dd, yyyy').parse(value);
    } catch (_) {
      return null;
    }
  }

  bool _isIncoming(StripeTransactionData tx) => _transactionAmount(tx) >= 0;

  double _transactionAmount(StripeTransactionData tx) {
    if (tx.amount != null) return tx.amount!;
    if (tx.totalPrice != null) return tx.totalPrice!.toDouble();
    return 0;
  }

  String _formatMoney(double amount, {bool showSign = false}) {
    final abs = _moneyFormat.format(amount.abs());
    if (!showSign) return abs;
    if (amount > 0) return '+$abs';
    if (amount < 0) return '-$abs';
    return abs;
  }

  String _displayStatus(bool incoming, String rawStatus) {
    final normalized = rawStatus.toLowerCase();
    if (normalized == 'succeeded' || normalized == 'completed') {
      return incoming ? 'RECEIVED' : 'PAID';
    }
    if (normalized == 'processing') return 'PROCESSING';
    if (normalized == 'canceled') return 'FAILED';
    return incoming ? 'RECEIVED' : 'PAID';
  }

  String _monthLabel(DateTime date) => DateFormat('MMMM yyyy').format(date);

  /// Date block in group header — matches typography used in `vendorhome.dart` section cards.
  Widget _sectionDateHeader(DateTime dateKey) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(dateKey.year, dateKey.month, dateKey.day);

    final lineStyle = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
      height: 1.05,
      letterSpacing: -0.15,
    );

    if (txDay == today) {
      return Text('Today', style: lineStyle);
    }
    if (txDay == today.subtract(const Duration(days: 1))) {
      return Text('Yesterday', style: lineStyle);
    }
    return Text(
      DateFormat('MMM dd yyyy, EEEE').format(dateKey),
      style: lineStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Date section header + transaction rows (no elevated card — sits on scaffold grey).
  Widget _transactionDateSection({
    required DateTime dateKey,
    required double sectionTotal,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _sectionDateHeader(dateKey)),
              Text(
                _formatMoney(sectionTotal, showSign: true),
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9DA3B4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _summaryCard({
    required bool incoming,
    required double amount,
  }) {
    final arrowColor = incoming ? const Color(0xFF2DB86A) : const Color(0xFFE5537D);
    final iconFill = incoming ? const Color(0xFFE8F5EC) : const Color(0xFFFDEDEE);
    final iconBorder = incoming ? const Color(0xFFB8E0C8) : const Color(0xFFF0B4BC);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: iconBorder, width: 1),
              ),
              alignment: Alignment.center,
              child: Icon(
                incoming ? Icons.south_west_rounded : Icons.north_east_rounded,
                size: 18,
                color: arrowColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              incoming ? 'Incoming' : 'Outgoing',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: _interRegular,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _summaryMoneyFormat.format(amount),
          style: const TextStyle(
            fontSize: 18,
            fontFamily: _interBold,
            color: Colors.black,
            letterSpacing: -0.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// Same row layout as `todayItem` in `vendorhome.dart` (CircleAvatar + Inter + amount + pill badge).
  Widget _buildTransactionRow({
    required String title,
    required DateTime date,
    required double amount,
    required bool isIncoming,
    required String status,
    required String method,
  }) {
    final amountColor = isIncoming ? const Color(0xFF4CAF50) : Colors.red;
    final avatarBg = isIncoming ? const Color(0xFFE8F5E9) : const Color(0xFFFFE4EC);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: avatarBg,
            child: Icon(
              isIncoming ? Icons.south_west : Icons.north_east,
              color: amountColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, yyyy').format(date),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMoney(amount, showSign: true),
                style: GoogleFonts.inter(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _displayStatus(isIncoming, status),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double res_height = MediaQuery.of(context).size.height;
    final GlobalKey<ScaffoldState> _key = GlobalKey();

    return Scaffold(
      key: _key,
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
          style: IconButton.styleFrom(foregroundColor: Colors.black87),
        ),
        title: Text(
          'My Transactions',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: res_height,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment History',
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: _interBold,
                      color: Color(0xFF111827),
                      letterSpacing: -0.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'View all your Stripe payment transactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: _interRegular,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: isError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Error loading transactions",
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: _interRegular,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  isLoading = true;
                                  isError = false;
                                  isEmpty = false;
                                });
                                getUserTransactions();
                              },
                              child: Text(
                                "Retry",
                                style: TextStyle(
                                  fontFamily: _interBold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: AppColors.primaryColor,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Loading transactions...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: _interRegular,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      "No transactions yet",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: _interBold,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Your payment history will appear here",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: _interRegular,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Builder(
                                builder: (context) {
                                  final items = List<StripeTransactionData>.from(
                                    ApiRepository.shared.stripeTransactionsModelList!.data!,
                                  )..sort((a, b) {
                                      final aDate = a.created ?? DateTime.fromMillisecondsSinceEpoch(0);
                                      final bDate = b.created ?? DateTime.fromMillisecondsSinceEpoch(0);
                                      return bDate.compareTo(aDate);
                                    });

                                  double incomingTotal = 0;
                                  double outgoingTotal = 0;
                                  for (final tx in items) {
                                    final amount = _transactionAmount(tx);
                                    if (_isIncoming(tx)) {
                                      incomingTotal += amount.abs();
                                    } else {
                                      outgoingTotal += amount.abs();
                                    }
                                  }

                                  final Map<DateTime, List<StripeTransactionData>> grouped = {};
                                  for (final tx in items) {
                                    final created = tx.created ?? DateTime.now();
                                    final key = DateTime(created.year, created.month, created.day);
                                    grouped.putIfAbsent(key, () => []).add(tx);
                                  }

                                  final sortedKeys = grouped.keys.toList()
                                    ..sort((a, b) => b.compareTo(a));
                                  final latestDate = items.isNotEmpty
                                      ? (items.first.created ?? DateTime.now())
                                      : DateTime.now();

                                  return ListView(
                                    physics: const BouncingScrollPhysics(),
                                    children: [
                                      const SizedBox(height: 6),
                                      Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(999),
                                            border: Border.all(
                                              color: const Color(0xFFE5E7EB),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            _monthLabel(latestDate),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontFamily: _interRegular,
                                              color: Color(0xFF374151),
                                              fontWeight: FontWeight.w600,
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            _summaryCard(incoming: true, amount: incomingTotal),
                                            _summaryCard(incoming: false, amount: outgoingTotal),
                                          ],
                                        ),
                                      const SizedBox(height: 20),
                                      for (final dateKey in sortedKeys)
                                        Builder(
                                          builder: (context) {
                                            final list = grouped[dateKey]!;
                                            double sectionTotal = 0;
                                            for (final tx in list) {
                                              sectionTotal += _transactionAmount(tx);
                                            }
                                            return _transactionDateSection(
                                              dateKey: dateKey,
                                              sectionTotal: sectionTotal,
                                              children: [
                                                for (final tx in list)
                                                  _buildTransactionRow(
                                                    title: tx.productName?.trim().isNotEmpty == true
                                                        ? tx.productName!
                                                        : 'Unknown',
                                                    date: tx.created ?? DateTime.now(),
                                                    amount: _transactionAmount(tx),
                                                    isIncoming: _isIncoming(tx),
                                                    status: tx.status ?? 'unknown',
                                                    method: tx.paymentMethodTypes?.first ?? 'Stripe',
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                    ],
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 