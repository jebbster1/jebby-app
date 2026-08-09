import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jebby/Views/screens/home/OrderConfirmation.dart';
import 'package:jebby/Views/screens/home/TrackingDetail.dart';
import 'package:jebby/res/app_url.dart';
import 'package:jebby/res/color.dart';
import 'package:provider/provider.dart';

import '../../../Services/provider/sign_in_provider.dart';
import '../../../model/getAllOrdersByUserIdModel.dart' as user_orders;
import '../../../model/user_model.dart';
import '../../../view_model/apiServices.dart';
import '../../../view_model/user_view_model.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  /// 0 = All, 1 = To Ship (status 1), 2 = Received (status 2)
  int selectedTab = 0;

  static const Color _pageBg = Color(0xFFF3F3F5);
  static const Color _subtitleGrey = Color(0xFF72747A);
  static const Color _pillTrack = Color(0xFFE8E8EC);

  bool isLoading = true;
  bool isError = false;
  bool isEmpty = false;

  String sourceId = "";
  String? fullname;

  Future<void> getData() async {
    final sp = context.read<SignInProvider>();
    final usp = context.read<UserViewModel>();
    usp.getUser();
    sp.getDataFromSharedPreferences();
  }

  Future<UserModel> getUserDate() => UserViewModel().getUser();

  void profileData(BuildContext context) {
    getUserDate()
        .then((value) async {
          sourceId = value.id.toString();
          fullname = value.name.toString();
          getNewOrders();
        })
        .onError((error, stackTrace) {
          if (kDebugMode) {}
        });
  }

  void getNewOrders() {
    ApiRepository.shared.getAllOrdersByUserId(
      sourceId,
      (List) {
        if (!mounted) return;
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
      },
      (error) {
        if (error != null && mounted) {
          setState(() {
            isLoading = false;
            isError = true;
          });
        }
      },
    );
  }

  List<user_orders.Data> _allOrders() {
    final raw = ApiRepository.shared.getAllOrdersByUserIdModelList?.data;
    if (raw == null) return [];
    return List<user_orders.Data>.from(raw);
  }

  List<user_orders.Data> _filteredOrders() {
    final all = _allOrders();
    if (selectedTab == 0) return all;
    if (selectedTab == 1) {
      return all.where((e) => e.status == 1).toList();
    }
    return all.where((e) => e.status == 2).toList();
  }

  String _formatExpectedArrival(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      return DateFormat('d/M/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _createdShort(user_orders.Data data) {
    try {
      return DateFormat('dd-MM-yy').format(DateTime.parse(data.createdAt.toString()));
    } catch (_) {
      return data.createdAt?.toString() ?? '';
    }
  }

  String _statusBadgeLabel(int? status) {
    switch (status) {
      case 0:
      case 1:
        return 'PENDING';
      case 2:
        return 'RECEIVED';
      default:
        return 'CANCELLED';
    }
  }

  double _parseCoord(dynamic v) {
    if (v == null) return 0;
    return double.tryParse(v.toString()) ?? 0;
  }

  String _imageUrl(String? path) {
    final p = path?.trim() ?? '';
    if (p.isEmpty) return '';
    if (p.toLowerCase().startsWith('http')) return p;
    final base = AppUrl.baseUrlM.endsWith('/') ? AppUrl.baseUrlM : '${AppUrl.baseUrlM}/';
    final rel = p.startsWith('/') ? p.substring(1) : p;
    return '$base$rel';
  }

  void _openTrack(user_orders.Data data) {
    Get.to(
      () => TrackingDetailScreen(
        date: data.rentStart.toString(),
        vendorId: data.vendorId.toString(),
        status: data.status.toString(),
        created: _createdShort(data),
        approve: data.approveDate.toString(),
        complete: data.completeDate.toString(),
        cancel: data.cancelDate.toString(),
      ),
    );
  }

  void _openReorder(user_orders.Data data) {
    Get.to(
      () => OrderConfirmationScreen(
        image: data.productImage.toString(),
        name: data.productName.toString(),
        price: data.totalPrice.toString(),
        orderId: data.id.toString(),
        prodId: data.productId.toString(),
        location: data.location.toString(),
        long: _parseCoord(data.longitude),
        lat: _parseCoord(data.latitude),
        username: fullname,
        userid: sourceId,
        vendorID: data.vendorId.toString(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    getData();
    profileData(context);
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
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
                'Reorder and Track your Products',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _subtitleGrey,
                ),
              ),
              const SizedBox(height: 20),
              _buildPillTabs(),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
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
          _pillTab(1, 'To Ship'),
          _pillTab(2, 'Received'),
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
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.black : _subtitleGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isError) {
      return Center(
        child: Text(
          'Something went wrong while loading orders.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: _subtitleGrey),
        ),
      );
    }
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
    }
    if (isEmpty) {
      return Center(
        child: Text(
          'No orders found',
          style: GoogleFonts.inter(color: _subtitleGrey, fontSize: 15),
        ),
      );
    }

    final items = _filteredOrders();
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No orders in this tab',
          style: GoogleFonts.inter(color: _subtitleGrey, fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final data = items[index];
        final priceStr = data.totalPrice?.toString() ?? '0';
        return _RenterOrderCard(
          name: data.productName?.toString() ?? '—',
          price: priceStr,
          status: data.status,
          statusLabel: _statusBadgeLabel(data.status),
          expectedArrival: _formatExpectedArrival(data.originalReturn),
          imageUrl: _imageUrl(data.productImage?.toString()),
          canReorder: true,
          onTrack: () => _openTrack(data),
          onReorder: () => _openReorder(data),
        );
      },
    );
  }
}

class _RenterOrderCard extends StatelessWidget {
  final String name;
  final String price;
  final int? status;
  final String statusLabel;
  final String expectedArrival;
  final String imageUrl;
  final bool canReorder;
  final VoidCallback onTrack;
  final VoidCallback onReorder;

  const _RenterOrderCard({
    required this.name,
    required this.price,
    required this.status,
    required this.statusLabel,
    required this.expectedArrival,
    required this.imageUrl,
    required this.canReorder,
    required this.onTrack,
    required this.onReorder,
  });

  static const Color _badgeBgOrange = Color(0xFFFFF3E0);
  static const Color _badgeFgOrange = Color(0xFFE65100);
  static const Color _badgeBgGreen = Color(0xFFE8F5E9);
  static const Color _badgeFgGreen = Color(0xFF2E7D32);
  static const Color _badgeBgGrey = Color(0xFFF5F5F5);
  static const Color _badgeFgGrey = Color(0xFF616161);

  @override
  Widget build(BuildContext context) {
    final received = status == 2;
    final cancelled = status != null && status != 0 && status != 1 && status != 2;
    final badgeBg =
        cancelled
            ? _badgeBgGrey
            : received
            ? _badgeBgGreen
            : _badgeBgOrange;
    final badgeFg =
        cancelled
            ? _badgeFgGrey
            : received
            ? _badgeFgGreen
            : _badgeFgOrange;

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
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
                    child:
                        imageUrl.isEmpty
                            ? ColoredBox(
                              color: const Color(0xFFF5F5F5),
                              child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
                            )
                            : CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (_, __) => ColoredBox(
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
                              errorWidget:
                                  (_, __, ___) => ColoredBox(
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
                            '\$$price',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusLabel,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: badgeFg,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
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
                        'Expected Arrival: $expectedArrival',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9A9AA1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: onTrack,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Track',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      onPressed: canReorder ? onReorder : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Reorder',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
