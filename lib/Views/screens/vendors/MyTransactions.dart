import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/res/color.dart';
import 'package:jebby/view_model/apiServices.dart';
import 'package:jebby/view_model/onboarding_controller.dart';
import 'package:jebby/Views/screens/onboarding/review_submit_screen.dart';
import 'package:jebby/Views/screens/vendors/stripe_requirements_modal.dart';
import 'package:provider/provider.dart';

import '../../../Services/provider/sign_in_provider.dart';
import '../../../utils/order_status.dart';
import '../../../model/user_model.dart';
import '../../../view_model/user_view_model.dart';

class TransactionListScreen extends StatefulWidget {
  TransactionListScreen({Key? key}) : super(key: key);

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen>
    with WidgetsBindingObserver {
  static const Color _pageBg = Color(0xFFF3F3F5);
  static const Color _subtitleGrey = Color(0xFF72747A);

  bool isLoading = true;
  bool isError = false;
  bool isEmpty = false;
  bool isAccountLoading = false;
  String? accountStatus;
  String? accountMessage;
  Map<String, dynamic>? accountDetails;
  bool _requirementsModalShown = false;

  getNewOrders() {
    ApiRepository.shared.getVenodorOrders(
      sourceId,
      (List) {
        if (this.mounted) {
          if (List.data!.length == 0) {
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
          });
        }
      },
    );
  }

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
  void profileData(BuildContext context) async {
    getUserDate()
        .then((value) async {
          token = value.token.toString();
          sourceId = value.id.toString();
          fullname = value.name.toString();
          email = value.email.toString();
          role = value.role.toString();
          getNewOrders();
          checkStripeAccountStatus();
        })
        .onError((error, stackTrace) {
          if (kDebugMode) {}
        });
  }

  void _applyStripeStatusResponse(Map<String, dynamic> data) {
    final rawStatus = data['status']?.toString().trim();
    accountStatus = (rawStatus == null || rawStatus.isEmpty) ? null : rawStatus;
    accountMessage = data['message']?.toString();

    Map<String, dynamic> account = {};
    if (data['account'] is Map) {
      account = Map<String, dynamic>.from(data['account'] as Map);
    } else {
      if (data['account_id'] != null) account['id'] = data['account_id'];
      if (data['charges_enabled'] != null) {
        account['charges_enabled'] = data['charges_enabled'];
      }
      if (data['payouts_enabled'] != null) {
        account['payouts_enabled'] = data['payouts_enabled'];
      }
      if (data['details_submitted'] != null) {
        account['details_submitted'] = data['details_submitted'];
      }
      if (data['type'] != null) account['type'] = data['type'];
      if (data['balance'] != null) account['balance'] = data['balance'];
    }

    if (data['requirements'] is Map) {
      account['requirements'] = data['requirements'];
    } else if (account['requirements'] == null &&
        data['account'] is Map &&
        (data['account'] as Map)['requirements'] is Map) {
      account['requirements'] = (data['account'] as Map)['requirements'];
    }

    accountDetails = account.isEmpty ? null : account;
  }

  Future<void> _prepareOnboardingController() async {
    final controller = ensureOnboardingController();
    if (controller.userId.isEmpty && sourceId.isNotEmpty) {
      await controller.loadAndReconcile(
        userId: sourceId,
        name: fullname,
        email: email,
      );
    }
  }

  Future<void> _showRequirementsModal() async {
    if (!_hasActionableRequirements() || _isPendingStripeReview()) return;

    final requirements = _accountRequirements;
    if (requirements == null) return;

    await _prepareOnboardingController();
    if (!mounted) return;

    await StripeRequirementsModal.show(
      context,
      userId: sourceId,
      requirements: requirements,
      message: accountMessage,
      onSubmitted: checkStripeAccountStatus,
    );
  }

  void _maybeAutoShowRequirementsModal() {
    if (_requirementsModalShown || !mounted || isAccountLoading) return;
    if (!_hasActionableRequirements() || _isPendingStripeReview()) return;

    _requirementsModalShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showRequirementsModal();
    });
  }

  Future<void> _openProviderOnboarding({bool openReview = false}) async {
    final controller = ensureOnboardingController();
    await _prepareOnboardingController();

    if (openReview ||
        accountStatus == 'requires_info' ||
        controller.state.isComplete) {
      Get.to(() => const ReviewSubmitScreen());
      return;
    }

    await controller.startOrResume();
  }

  String _accountStatusHeadline(String status) {
    switch (status) {
      case 'active':
        return 'Account active';
      case 'pending':
        return 'Account pending';
      case 'requires_info':
        return 'Action required';
      case 'not_started':
        return 'Account not set up';
      case 'failed':
      case 'failure':
        return 'Setup failed';
      case 'error':
        return 'Could not load account';
      default:
        return 'Account status';
    }
  }

  Color _accountStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green.shade700;
      case 'pending':
        return Colors.blue.shade700;
      case 'requires_info':
        return Colors.orange.shade800;
      case 'failed':
      case 'failure':
      case 'error':
        return Colors.red.shade700;
      default:
        return _subtitleGrey;
    }
  }

  IconData _accountStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending_actions;
      case 'requires_info':
        return Icons.info_outline;
      case 'failed':
      case 'failure':
      case 'error':
        return Icons.error_outline;
      case 'not_started':
        return Icons.warning_amber_rounded;
      default:
        return Icons.account_balance_outlined;
    }
  }

  String _accountStatusDescription(String status) {
    switch (status) {
      case 'active':
        return 'Your Stripe payout account is active and ready to receive payments.';
      case 'pending':
        return 'Your account is being reviewed. This usually takes 1–2 business days.';
      case 'requires_info':
        return accountMessage ??
            'Stripe needs additional information to finish verifying your account.';
      case 'not_started':
        return 'Set up your payout account to receive payments from rentals.';
      case 'failed':
      case 'failure':
        return accountMessage ??
            'There was an issue with your account setup. Please try again.';
      case 'error':
        return accountMessage ??
            'We could not load your Stripe account status. Pull to refresh or try again.';
      default:
        return accountMessage ??
            'Your Stripe Connect account status is $status.';
    }
  }

  String _accountTypeLabel() {
    final type = accountDetails?['type']?.toString().toLowerCase() ?? '';
    if (type == 'custom') return 'Custom';
    if (type == 'express') return 'Express';
    if (type == 'standard') return 'Standard';
    return 'Connect';
  }

  bool _requirementListHasItems(dynamic value) {
    return value is List && value.isNotEmpty;
  }

  Map<String, dynamic>? get _accountRequirements {
    final requirements = accountDetails?['requirements'];
    return requirements is Map ? Map<String, dynamic>.from(requirements) : null;
  }

  bool _hasActionableRequirements() {
    final requirements = _accountRequirements;
    if (requirements == null) return false;

    if (_requirementListHasItems(requirements['currently_due']) ||
        _requirementListHasItems(requirements['past_due'])) {
      return true;
    }

    return requirements['disabled_reason'] != null;
  }

  bool _hasRequirementsToDisplay() {
    final requirements = _accountRequirements;
    if (requirements == null) return false;

    for (final key in [
      'currently_due',
      'past_due',
      'eventually_due',
      'pending_verification',
    ]) {
      if (_requirementListHasItems(requirements[key])) return true;
    }

    return requirements['disabled_reason'] != null;
  }

  bool _isPendingStripeReview() {
    if (accountStatus == 'pending') return true;

    final requirements = _accountRequirements;
    if (requirements == null) return false;

    return _requirementListHasItems(requirements['pending_verification']) &&
        !_hasActionableRequirements();
  }

  bool _hasOutstandingRequirements() => _hasActionableRequirements();

  Widget _buildAccountSummaryDetails() {
    if (accountDetails == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (accountDetails!['id'] != null) ...[
          Text(
            'Account ID: ${accountDetails!['id']}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
        ],
        if (accountDetails!['charges_enabled'] != null) ...[
          Text(
            'Charges enabled: ${accountDetails!['charges_enabled'] == true ? 'Yes' : 'No'}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
        ],
        if (accountDetails!['payouts_enabled'] != null)
          Text(
            'Payouts enabled: ${accountDetails!['payouts_enabled'] == true ? 'Yes' : 'No'}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        if (_hasRequirementsToDisplay()) ...[
          const SizedBox(height: 12),
          Text(
            _isPendingStripeReview()
                ? 'Verification in progress'
                : 'Outstanding requirements',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _subtitleGrey,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementsSection(accountDetails!['requirements']),
        ],
      ],
    );
  }

  Widget _buildAccountActionButton({
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildResolvedAccountStatus(String status) {
    final color = _accountStatusColor(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_accountStatusIcon(status), color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _accountStatusHeadline(status),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _accountStatusDescription(status),
          style: GoogleFonts.inter(fontSize: 14, color: _subtitleGrey),
        ),
        if (accountDetails != null) ...[
          const SizedBox(height: 8),
          _buildAccountSummaryDetails(),
        ],
        const SizedBox(height: 16),
        if (_hasOutstandingRequirements())
          _buildAccountActionButton(
            label: 'Submit required info',
            backgroundColor: AppColors.primaryColor,
            onPressed: _showRequirementsModal,
          )
        else if (status == 'active')
          _buildAccountActionButton(
            label: 'View account details',
            backgroundColor: const Color(0xFF2E7D32),
            onPressed: _showAccountDetailsModal,
          )
        else if (status == 'not_started')
          _buildAccountActionButton(
            label: 'Set up account',
            backgroundColor: AppColors.primaryColor,
            onPressed: () => _openProviderOnboarding(),
          )
        else if (status == 'pending')
          _buildAccountActionButton(
            label: 'View setup progress',
            backgroundColor: const Color(0xFF1E88E5),
            onPressed: _showAccountDetailsModal,
          )
        else if (status == 'failed' ||
            status == 'failure' ||
            status == 'error')
          _buildAccountActionButton(
            label: status == 'error' ? 'Retry' : 'Try again',
            backgroundColor: const Color(0xFFC62828),
            onPressed:
                status == 'error'
                    ? checkStripeAccountStatus
                    : () => _openProviderOnboarding(openReview: true),
          )
        else
          _buildAccountActionButton(
            label: 'Manage account',
            backgroundColor: AppColors.primaryColor,
            onPressed: _showAccountDetailsModal,
          ),
      ],
    );
  }

  void checkStripeAccountStatus() {
    if (sourceId.isEmpty) {
      return;
    }

    setState(() {
      isAccountLoading = true;
      accountMessage = null;
    });

    ApiRepository.shared.checkStripeAccountStatus(
      sourceId,
      (data) {
        if (this.mounted) {
          setState(() {
            isAccountLoading = false;
            if (data is Map<String, dynamic>) {
              _applyStripeStatusResponse(data);
            } else if (data is Map) {
              _applyStripeStatusResponse(Map<String, dynamic>.from(data));
            } else {
              accountStatus = 'error';
              accountDetails = null;
            }
          });
          _maybeAutoShowRequirementsModal();
        }
      },
      (error) {
        if (this.mounted) {
          setState(() {
            isAccountLoading = false;
            accountStatus = 'error';
            accountMessage = error?.toString();
            accountDetails = null;
          });
        }
      },
    );
  }

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
    // Refresh data when app becomes active (e.g., returning from onboarding)
    if (state == AppLifecycleState.resumed && sourceId.isNotEmpty) {
      getNewOrders();
      checkStripeAccountStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(
      Theme.of(context).textTheme.apply(
        bodyColor: const Color(0xFF1A1A1A),
        displayColor: const Color(0xFF1A1A1A),
      ),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: _pageBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Get.back(),
            style: IconButton.styleFrom(foregroundColor: Colors.black),
          ),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Transactions',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'View payout history and manage your Stripe payout account.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: _subtitleGrey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    accountSection(),
                    const SizedBox(height: 20),
                    Text(
                      'Recent activity',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: _buildTransactionSliver(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSliver() {
    if (isError) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 220,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Could not load transactions.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 15, color: _subtitleGrey),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      isError = false;
                      isEmpty = false;
                    });
                    getNewOrders();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 180,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
        ),
      );
    }
    if (isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 220,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No transactions yet',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _subtitleGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your transaction history will appear here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: _subtitleGrey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final raw = ApiRepository.shared.getAllOrdersByVenodrIdList?.data ?? [];
    final visible = raw.where((e) => !OrderStatus.isTerminal(e.orderStatus)).toList();

    if (visible.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 120,
          child: Center(
            child: Text(
              'No active transactions',
              style: GoogleFonts.inter(fontSize: 15, color: _subtitleGrey),
            ),
          ),
        ),
      );
    }

    return SliverList.separated(
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final data = visible[index];
        return _transactionCard(
          data.name.toString(),
          data.totalPrice.toString(),
          data.email.toString(),
        );
      },
    );
  }

  Widget _transactionCard(
    String name,
    String price,
    String email,
  ) {
    final amount = price;
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.payments_outlined,
                color: AppColors.primaryColor.withValues(alpha: 0.85),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF9A9AA1),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              '\$$amount',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget accountSection() {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Stripe payout account',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isAccountLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primaryColor,
                      strokeWidth: 2,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Checking account status…',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _subtitleGrey,
                      ),
                    ),
                  ],
                ),
              )
            else if (accountStatus == 'not_started' || accountStatus == null)
              _buildResolvedAccountStatus('not_started')
            else
              _buildResolvedAccountStatus(accountStatus!),
          ],
        ),
      ),
    );
  }

  void _showAccountDetailsModal() {
    final maxH = MediaQuery.of(context).size.height * 0.78;
    final status = accountStatus ?? 'unknown';
    final statusLabel = _accountStatusHeadline(status);
    final statusGood = status == 'active';
    final statusBad =
        status == 'failed' ||
        status == 'failure' ||
        status == 'error' ||
        status == 'requires_info';
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 28,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxH, maxWidth: 400),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 8, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            color: AppColors.primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Stripe account',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey.shade600,
                            size: 22,
                          ),
                          style: IconButton.styleFrom(
                            foregroundColor: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                  Flexible(
                    child: Container(
                      color: const Color(0xFFF3F3F5),
                      width: double.infinity,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Details',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _subtitleGrey,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildDetailRow(
                              'Account status',
                              statusLabel,
                              Icons.verified_outlined,
                              valueGood: statusGood,
                              valueBad: statusBad,
                            ),
                            const SizedBox(height: 10),
                            if (accountDetails != null) ...[
                              _buildDetailRow(
                                'Account ID',
                                accountDetails!['id'] ?? 'N/A',
                                Icons.tag_outlined,
                                isMonospace: true,
                              ),
                              const SizedBox(height: 10),
                              _buildDetailRow(
                                'Charges enabled',
                                accountDetails!['charges_enabled'] == true
                                    ? 'Yes'
                                    : 'No',
                                Icons.credit_card_outlined,
                                valueGood:
                                    accountDetails!['charges_enabled'] == true,
                                valueBad:
                                    accountDetails!['charges_enabled'] != true,
                              ),
                              const SizedBox(height: 10),
                              _buildDetailRow(
                                'Payouts enabled',
                                accountDetails!['payouts_enabled'] == true
                                    ? 'Yes'
                                    : 'No',
                                Icons.account_balance_wallet_outlined,
                                valueGood:
                                    accountDetails!['payouts_enabled'] == true,
                                valueBad:
                                    accountDetails!['payouts_enabled'] != true,
                              ),
                              const SizedBox(height: 16),
                              _buildBalanceSection(),
                              const SizedBox(height: 16),
                            ],
                            if (accountDetails != null &&
                                accountDetails!['requirements'] != null) ...[
                              Text(
                                'Requirements',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _subtitleGrey,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildRequirementsSection(
                                accountDetails!['requirements'],
                              ),
                              const SizedBox(height: 10),
                            ],
                            _buildDetailRow(
                              'Account type',
                              _accountTypeLabel(),
                              Icons.storefront_outlined,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static const Color _modalValueGood = Color(0xFF2E7D32);
  static const Color _modalValueBad = Color(0xFFC62828);

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    bool isMonospace = false,
    bool valueGood = false,
    bool valueBad = false,
  }) {
    final Color valueColor =
        valueBad
            ? _modalValueBad
            : valueGood
            ? _modalValueGood
            : Colors.black;

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF72747A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _subtitleGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style:
                        isMonospace
                            ? TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: valueColor,
                              fontFamily: 'monospace',
                            )
                            : GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: valueColor,
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsSection(Map<String, dynamic> requirements) {
    List<Widget> requirementWidgets = [];

    if (requirements['currently_due'] != null) {
      requirementWidgets.add(
        _buildRequirementItem('Currently Due', requirements['currently_due']),
      );
    }
    if (requirements['eventually_due'] != null) {
      requirementWidgets.add(
        _buildRequirementItem('Eventually Due', requirements['eventually_due']),
      );
    }
    if (requirements['past_due'] != null) {
      requirementWidgets.add(
        _buildRequirementItem('Past Due', requirements['past_due']),
      );
    }
    if (requirements['pending_verification'] != null) {
      requirementWidgets.add(
        _buildRequirementItem(
          'Pending verification',
          requirements['pending_verification'],
        ),
      );
    }
    if (requirements['disabled_reason'] != null) {
      requirementWidgets.add(
        _buildRequirementItem(
          'Disabled Reason',
          requirements['disabled_reason'],
        ),
      );
    }

    return Column(children: requirementWidgets);
  }

  Widget _buildRequirementItem(String title, dynamic requirements) {
    if (requirements is List && requirements.isEmpty) {
      return const SizedBox.shrink();
    }

    final isPastDue = title == 'Past Due';
    final borderColor =
        isPastDue ? const Color(0xFFFFCDD2) : Colors.grey.shade300;
    final titleColor = isPastDue ? _modalValueBad : _subtitleGrey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 8),
              if (requirements is List)
                ...requirements
                    .map(
                      (req) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: _subtitleGrey,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                req.toString().replaceAll('_', ' '),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF2A2A2E),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList()
              else
                Text(
                  requirements.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF2A2A2E),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSection() {
    // Extract balance data from accountDetails
    Map<String, dynamic>? balance = accountDetails?['balance'];
    List<dynamic>? available = balance?['available'];
    List<dynamic>? pending = balance?['pending'];

    // Calculate totals
    double availableTotal = 0.0;
    double pendingTotal = 0.0;
    String currency = 'USD';

    if (available != null) {
      for (var item in available) {
        availableTotal += (item['amount'] ?? 0) / 100.0; // Convert from cents
        currency = item['currency'] ?? 'USD';
      }
    }

    if (pending != null) {
      for (var item in pending) {
        pendingTotal += (item['amount'] ?? 0) / 100.0; // Convert from cents
      }
    }

    double totalBalance = availableTotal + pendingTotal;
    final currencyUpper = currency.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Balances',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _subtitleGrey,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildBalanceItem(
                        'Available',
                        '\$${availableTotal.toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildBalanceItem(
                        'Pending',
                        '\$${pendingTotal.toStringAsFixed(2)}',
                        subtitle: 'Future payouts',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildBalanceItem(
                        'Total',
                        '\$${totalBalance.toStringAsFixed(2)}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildBalanceItem('Currency', currencyUpper),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceItem(String label, String amount, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _subtitleGrey,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: _subtitleGrey.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
