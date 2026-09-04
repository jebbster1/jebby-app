import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jebby/constants/color.dart';
import 'package:jebby/views/screens/reservations/reservation_detail.dart';
import 'package:jebby/views/screens/vendors/vendor_home.dart';
import 'package:provider/provider.dart';

import '../../../services/provider/sign_in_provider.dart';
import '../../../utils/order_status.dart';
import '../../../models/user_model.dart';
import '../../../constants/app_url.dart';
import 'package:jebby/repositories/api_repository.dart';
import '../../../view_models/user_view_model.dart';

class VendorMyOrdersScreen extends StatefulWidget {
  const VendorMyOrdersScreen({super.key});

  @override
  State<VendorMyOrdersScreen> createState() => _VendorMyOrdersScreenState();
}

class _VendorMyOrdersScreenState extends State<VendorMyOrdersScreen> {
  static const Color _pageBg = Color(0xFFF3F3F5);
  static const Color _subtitleGrey = Color(0xFF72747A);
  static const Color _pillTrack = Color(0xFFE8E8EC);

  /// 0 = All, 1 = Requests (booking requested), 2 = Active (in progress), 3 = Completed
  int selectedTab = 0;

  EdgeInsets _listBottomPadding(BuildContext context) {
    return EdgeInsets.only(
      bottom: MediaQuery.of(context).padding.bottom + 24,
    );
  }

  bool isLoading = true;
  bool isError = false;
  bool isEmpty = false;

  int? _actionLoadingOrderId;
  String? _actionLoadingKind;

  static const Color _labelGrey = Color(0xFF72747A);
  static const Color _titleDark = Color(0xFF1A1A1A);

  Future<void> getData() async {
    final sp = context.read<SignInProvider>();
    final usp = context.read<UserViewModel>();
    usp.getUser();
    sp.getDataFromSharedPreferences();
  }

  Future<UserModel> getUserDate() => UserViewModel().getUser();

  String? token;
  String sourceId = '';
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
        })
        .onError((error, stackTrace) {
          if (kDebugMode) {}
        });
  }

  void getNewOrders() {
    ApiRepository.shared.getVenodorOrders(
      sourceId,
      (List) {
        if (mounted) {
          if (List.data!.isEmpty) {
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

  Future<bool> _confirmVendorBookingAction({
    required String title,
    required String message,
    required String confirmLabel,
    Color confirmColor = AppColors.primaryColor,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _titleDark,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _labelGrey,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: _labelGrey,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                confirmLabel,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: confirmColor,
                ),
              ),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  Widget _actionButtonChild(bool loading, String label) {
    if (loading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    }
    return Text(
      label,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  Future<void> _approveBooking(dynamic orderId, String productName) async {
    final id = int.tryParse(orderId.toString());
    if (id == null) return;

    final name = productName.trim();
    final confirmed = await _confirmVendorBookingAction(
      title: 'Approve booking?',
      message: name.isNotEmpty && name != 'null'
          ? 'Accept this rental request for "$name"? The renter will be asked to complete payment.'
          : 'Accept this rental request? The renter will be asked to complete payment.',
      confirmLabel: 'Approve',
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _actionLoadingOrderId = id;
      _actionLoadingKind = 'approve';
    });
    try {
      final ok = await ApiRepository.shared.acceptVendorBooking(id);
      if (ok && mounted) {
        ApiRepository.shared.getVenodorOrders(sourceId.toString(), (List) {
          if (mounted) setState(() {});
        }, (error) {});
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoadingOrderId = null;
          _actionLoadingKind = null;
        });
      }
    }
  }

  Future<void> _declineBooking(dynamic orderId, String productName) async {
    final id = int.tryParse(orderId.toString());
    if (id == null) return;

    final name = productName.trim();
    final confirmed = await _confirmVendorBookingAction(
      title: 'Decline booking?',
      message: name.isNotEmpty && name != 'null'
          ? 'Decline the rental request for "$name"? The renter will be notified.'
          : 'Decline this rental request? The renter will be notified.',
      confirmLabel: 'Decline',
      confirmColor: Colors.red.shade700,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _actionLoadingOrderId = id;
      _actionLoadingKind = 'decline';
    });
    try {
      final ok = await ApiRepository.shared.declineVendorBooking(
        id,
        reason: 'Order Declined',
      );
      if (ok && mounted) {
        ApiRepository.shared.getVenodorOrders(sourceId.toString(), (List) {
          if (mounted) setState(() {});
        }, (error) {});
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoadingOrderId = null;
          _actionLoadingKind = null;
        });
      }
    }
  }

  Future<void> _openReservation(dynamic orderId) async {
    final id = int.tryParse(orderId.toString());
    if (id == null) return;
    await Get.to(() => ReservationDetailScreen(orderId: id));
    if (!mounted || sourceId.isEmpty) return;
    getNewOrders();
  }

  Widget _vendorNewOrderRequestCard({
    required String productName,
    required String renterName,
    required String? productImage,
    required dynamic orderId,
    required String id,
    required String price,
    required String start,
    required String end,
    required String email,
    required String location,
  }) {
    final due = _formatVendorDate(end);
    final renter = renterName.trim().isNotEmpty && renterName != 'null' ? renterName : 'Renter';
    final orderIdInt = int.tryParse(orderId.toString());
    final approving =
        orderIdInt != null &&
        _actionLoadingOrderId == orderIdInt &&
        _actionLoadingKind == 'approve';
    final declining =
        orderIdInt != null &&
        _actionLoadingOrderId == orderIdInt &&
        _actionLoadingKind == 'decline';
    final busy = orderIdInt != null && _actionLoadingOrderId == orderIdInt;
    return _VendorOrderCardShell(
      badgeLabel: OrderStatus.renterBadgeLabel(OrderStatus.bookingRequested),
      badgeBg: const Color(0xFFFFF3E0),
      badgeFg: const Color(0xFFE65100),
      displayPrice: price,
      title: productName,
      metaLine: 'Requested by $renter · Return due: $due',
      imageUrl: _imageUrl(productImage),
      onHeaderTap: () => _openReservation(orderId),
      actionRow: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: busy ? null : () => _approveBooking(orderId, productName),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primaryColor.withValues(alpha: 0.7),
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _actionButtonChild(approving, 'Approve'),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: busy ? null : () => _declineBooking(orderId, productName),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.grey.shade500,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade400,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _actionButtonChild(declining, 'Decline'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _pillTrack,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _pillTab(0, 'All'),
          _pillTab(1, 'Requests'),
          _pillTab(2, 'Active'),
          _pillTab(3, 'Completed'),
        ],
      ),
    );
  }

  Widget _pillTab(int index, String label) {
    final selected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.black : _subtitleGrey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<dynamic> _allOrders() {
    return ApiRepository.shared.getAllOrdersByVenodrIdList?.data ?? [];
  }

  String _formatVendorDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      return DateFormat('d/M/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _displayPrice(dynamic totalPrice) {
    if (totalPrice == null) return '0';
    return totalPrice.toString();
  }

  String _imageUrl(String? path) {
    final p = path?.trim() ?? '';
    if (p.isEmpty) return '';
    if (p.toLowerCase().startsWith('http')) return p;
    final base = AppUrl.baseUrlM.endsWith('/') ? AppUrl.baseUrlM : '${AppUrl.baseUrlM}/';
    final rel = p.startsWith('/') ? p.substring(1) : p;
    return '$base$rel';
  }

  String _productTitle(dynamic productName, dynamic productId) {
    final name = productName?.toString().trim();
    if (name != null && name.isNotEmpty && name != 'null') return name;
    return 'Product #${productId ?? ''}';
  }

  Widget _buildTabContent() {
    if (isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Something went wrong while loading orders.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 15, color: _subtitleGrey),
          ),
        ),
      );
    }
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }
    if (isEmpty) {
      return Center(
        child: Text(
          'No orders found',
          style: GoogleFonts.inter(fontSize: 15, color: _subtitleGrey),
        ),
      );
    }

    switch (selectedTab) {
      case 0:
        return _allOrdersList();
      case 1:
        return _newOrdersList();
      case 2:
        return _pendingOrdersList();
      default:
        return _completedOrdersList();
    }
  }

  List<dynamic> _ordersForSelectedTab() {
    final all = _allOrders();
    switch (selectedTab) {
      case 0:
        return all;
      case 1:
        return all.where((e) => OrderStatus.isNewBooking(e.orderStatus)).toList();
      case 2:
        return all.where((e) => OrderStatus.isVendorActiveTab(e.orderStatus)).toList();
      default:
        return all.where((e) => OrderStatus.isCompleted(e.orderStatus)).toList();
    }
  }

  Widget _ordersList(List<dynamic> list) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No orders in this tab',
          style: GoogleFonts.inter(fontSize: 15, color: _subtitleGrey),
        ),
      );
    }
    return ListView.separated(
      padding: _listBottomPadding(context),
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildVendorOrderCard(list[index]),
    );
  }

  Widget _allOrdersList() => _ordersList(_ordersForSelectedTab());

  Widget _buildVendorOrderCard(dynamic data) {
    final status = data.orderStatus?.toString();
    final productName = _productTitle(data.productName, data.productId);
    final renterName = data.name.toString();
    final price = data.totalPrice.toString();
    final start = data.rentalStartDate.toString();
    final end = data.rentalEndDate.toString();
    final id = data.productId.toString();
    final orderId = data.id;
    final email = data.email.toString();
    final location = data.location.toString();
    final renter =
        renterName.trim().isNotEmpty && renterName != 'null' ? renterName : 'Renter';

    if (OrderStatus.isNewBooking(status)) {
      return _vendorNewOrderRequestCard(
        productName: productName,
        renterName: renterName,
        productImage: data.productImage,
        orderId: orderId,
        id: id,
        price: price,
        start: start,
        end: end,
        email: email,
        location: location,
      );
    }

    if (OrderStatus.isCompleted(status)) {
      return _VendorOrderCardShell(
        badgeLabel: 'COMPLETED',
        badgeBg: const Color(0xFFE8F5E9),
        badgeFg: const Color(0xFF2E7D32),
        displayPrice: _displayPrice(data.totalPrice),
        title: productName,
        metaLine: 'Completed · Return was ${_formatVendorDate(end)}',
        imageUrl: _imageUrl(data.productImage),
        onHeaderTap: () => _openReservation(orderId),
      );
    }

    if (OrderStatus.isTerminal(status)) {
      final rejected = OrderStatus.isRejected(status);
      return _VendorOrderCardShell(
        badgeLabel: OrderStatus.renterBadgeLabel(status),
        badgeBg: const Color(0xFFF5F5F5),
        badgeFg: const Color(0xFF616161),
        displayPrice: _displayPrice(data.totalPrice),
        title: productName,
        metaLine: rejected
            ? 'Declined · ${_formatVendorDate(start)} – ${_formatVendorDate(end)}'
            : 'Cancelled · ${_formatVendorDate(start)} – ${_formatVendorDate(end)}',
        imageUrl: _imageUrl(data.productImage),
        onHeaderTap: () => _openReservation(orderId),
      );
    }

    if (OrderStatus.isVendorActiveTab(status)) {
      void openReservation() => _openReservation(orderId);

      return _VendorOrderCardShell(
        badgeLabel: OrderStatus.renterBadgeLabel(status),
        badgeBg: const Color(0xFFFFF3E0),
        badgeFg: const Color(0xFFE65100),
        displayPrice: _displayPrice(data.totalPrice),
        title: productName,
        metaLine:
            'Requested by $renter · Return due: ${_formatVendorDate(end)}',
        imageUrl: _imageUrl(data.productImage),
        onHeaderTap: openReservation,
        actionRow: SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            onPressed: openReservation,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Open reservation',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    final cancelled = OrderStatus.isCancelled(status);
    final rejected = OrderStatus.isRejected(status);
    final terminal = cancelled || rejected;
    return _VendorOrderCardShell(
      badgeLabel: OrderStatus.renterBadgeLabel(status),
      badgeBg: terminal ? const Color(0xFFF5F5F5) : const Color(0xFFFFF3E0),
      badgeFg: terminal ? const Color(0xFF616161) : const Color(0xFFE65100),
      displayPrice: _displayPrice(data.totalPrice),
      title: productName,
      metaLine: 'Requested by $renter · Return due: ${_formatVendorDate(end)}',
      imageUrl: _imageUrl(data.productImage),
      onHeaderTap: () => _openReservation(orderId),
    );
  }

  Widget _newOrdersList() => _ordersList(_ordersForSelectedTab());

  Widget _pendingOrdersList() => _ordersList(_ordersForSelectedTab());

  Widget _completedOrdersList() => _ordersList(_ordersForSelectedTab());

  @override
  void initState() {
    super.initState();
    getData();
    profileData(context);
  }

  @override
  void activate() {
    super.activate();
    if (sourceId.isNotEmpty) {
      getNewOrders();
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
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Get.back();
              } else {
                Get.offAll(() => const VendorHomeScreen());
              }
            },
            style: IconButton.styleFrom(foregroundColor: Colors.black),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Orders',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Review booking requests, then track active and completed rentals.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _subtitleGrey,
                ),
              ),
              const SizedBox(height: 20),
              _buildPillTabs(),
              const SizedBox(height: 16),
              Expanded(child: _buildTabContent()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Order row layout aligned with renter [MyOrdersScreen] `_RenterOrderCard`.
class _VendorOrderCardShell extends StatelessWidget {
  final String badgeLabel;
  final Color badgeBg;
  final Color badgeFg;
  final String displayPrice;
  final String title;
  final String metaLine;
  final String imageUrl;
  final VoidCallback onHeaderTap;
  final Widget? actionRow;

  const _VendorOrderCardShell({
    required this.badgeLabel,
    required this.badgeBg,
    required this.badgeFg,
    required this.displayPrice,
    required this.title,
    required this.metaLine,
    this.imageUrl = '',
    required this.onHeaderTap,
    this.actionRow,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onHeaderTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: imageUrl.isEmpty
                          ? ColoredBox(
                              color: const Color(0xFFF5F5F5),
                              child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
                            )
                          : CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => ColoredBox(
                                color: const Color(0xFFF5F5F5),
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryColor.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => ColoredBox(
                                color: const Color(0xFFF5F5F5),
                                child: Icon(Icons.chair_outlined, color: Colors.grey.shade500),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '\$$displayPrice',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  badgeLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: badgeFg,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          metaLine,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF9A9AA1),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (actionRow != null) ...[
                const SizedBox(height: 14),
                actionRow!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
