import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/views/screens/home/product_details.dart';
import 'package:jebby/views/screens/navigation/home_main.dart';
import 'package:jebby/views/screens/reservations/reservation_detail.dart';
import 'package:jebby/constants/app_url.dart';
import 'package:jebby/constants/color.dart';
import 'package:provider/provider.dart';

import '../../../services/provider/sign_in_provider.dart';
import '../../../utils/order_status.dart';
import '../../../utils/rental_date.dart';
import '../../../utils/show_snackbar.dart';
import '../../../models/get_all_orders_by_user_id_model.dart' as user_orders;
import '../../../models/user_model.dart';
import 'package:jebby/repositories/api_repository.dart';
import '../../../view_models/user_view_model.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  /// 0 = All, 1 = Active (in-progress rentals), 2 = Completed
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
      return all.where((e) => OrderStatus.isRenterActive(e.orderStatus)).toList();
    }
    return all.where((e) => OrderStatus.isCompleted(e.orderStatus)).toList();
  }

  String _formatExpectedArrival(String? raw) => formatRentalDateForDisplay(raw);

  String _statusBadgeLabel(String? status) => OrderStatus.renterBadgeLabel(status);

  String _imageUrl(String? path) {
    final p = path?.trim() ?? '';
    if (p.isEmpty) return '';
    if (p.toLowerCase().startsWith('http')) return p;
    final base = AppUrl.baseUrlM.endsWith('/') ? AppUrl.baseUrlM : '${AppUrl.baseUrlM}/';
    final rel = p.startsWith('/') ? p.substring(1) : p;
    return '$base$rel';
  }

  Future<void> _openReservation(user_orders.Data data) async {
    final orderId = data.id;
    if (orderId == null) return;
    await Get.to(() => ReservationDetailScreen(orderId: orderId));
    if (!mounted || sourceId.isEmpty) return;
    getNewOrders();
  }

  void _openRentAgain(user_orders.Data data) {
    final productId = data.productId?.toString() ?? '';
    if (productId.isEmpty) return;

    ApiRepository.shared.getProductsById(
      (list) {
        final product =
            list.data != null && list.data!.isNotEmpty ? list.data!.first : null;
        if (product == null) {
          showAppErrorSnackbar('This listing is no longer available.');
          return;
        }
        if (!productHasFutureBookableDates(
          product.availableFrom,
          product.availableTo,
        )) {
          showAppErrorSnackbar(
            'This listing is not available for future rental dates.',
          );
          return;
        }

        final imagePath = product.images?.isNotEmpty == true
            ? product.images!.first.path
            : data.productImage?.toString() ?? '';

        Get.to(
          () => ProductDetailScreen(
            productId,
            product.name ?? data.productName ?? 'Listing',
            product.price ?? 0,
            product.stars ?? '0',
            imagePath,
            product.specifications ?? '',
            product.userId ?? data.vendorId,
            product.description ?? '',
            product.delivery_charges ?? 0,
            sourceId: 'rent_again',
          ),
        );
      },
      (_) {
        showAppErrorSnackbar('This listing is no longer available.');
      },
      productId,
    );
  }

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

  void _goBackFromMyOrders() {
    if (Navigator.of(context).canPop()) {
      Get.back();
      return;
    }
    Get.offAll(() => const MainScreen());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(
      Theme.of(context).textTheme.apply(
        bodyColor: const Color(0xFF1A1A1A),
        displayColor: const Color(0xFF1A1A1A),
      ),
    );

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBackFromMyOrders();
      },
      child: Theme(
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
            onPressed: _goBackFromMyOrders,
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
                'Manage rentals and book again',
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
          _pillTab(1, 'Active'),
          _pillTab(2, 'Completed'),
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
        final activeReservation = OrderStatus.isRenterActive(data.orderStatus);
        final canRentAgain = OrderStatus.isCompleted(data.orderStatus);
        return _RenterOrderCard(
          name: data.productName?.toString() ?? '—',
          price: priceStr,
          orderStatus: data.orderStatus,
          statusLabel: _statusBadgeLabel(data.orderStatus),
          expectedArrival: _formatExpectedArrival(data.rentalEndDate),
          imageUrl: _imageUrl(data.productImage?.toString()),
          showOpenReservation: activeReservation,
          showRentAgain: canRentAgain,
          onCardTap: () => _openReservation(data),
          onRentAgain: () => _openRentAgain(data),
        );
      },
    );
  }
}

class _RenterOrderCard extends StatelessWidget {
  final String name;
  final String price;
  final String? orderStatus;
  final String statusLabel;
  final String expectedArrival;
  final String imageUrl;
  final bool showOpenReservation;
  final bool showRentAgain;
  final VoidCallback onCardTap;
  final VoidCallback onRentAgain;

  const _RenterOrderCard({
    required this.name,
    required this.price,
    required this.orderStatus,
    required this.statusLabel,
    required this.expectedArrival,
    required this.imageUrl,
    required this.showOpenReservation,
    required this.showRentAgain,
    required this.onCardTap,
    required this.onRentAgain,
  });

  static const Color _badgeBgOrange = Color(0xFFFFF3E0);
  static const Color _badgeFgOrange = Color(0xFFE65100);
  static const Color _badgeBgGreen = Color(0xFFE8F5E9);
  static const Color _badgeFgGreen = Color(0xFF2E7D32);
  static const Color _badgeBgGrey = Color(0xFFF5F5F5);
  static const Color _badgeFgGrey = Color(0xFF616161);

  @override
  Widget build(BuildContext context) {
    final completed = OrderStatus.isCompleted(orderStatus);
    final terminal = OrderStatus.isTerminal(orderStatus);
    final badgeBg = completed
        ? _badgeBgGreen
        : terminal
        ? _badgeBgGrey
        : _badgeBgOrange;
    final badgeFg = completed
        ? _badgeFgGreen
        : terminal
        ? _badgeFgGrey
        : _badgeFgOrange;

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onCardTap,
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
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  statusLabel,
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
                          'Return due: $expectedArrival',
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
              if (showOpenReservation || showRentAgain) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (showOpenReservation)
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: FilledButton(
                            onPressed: onCardTap,
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
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    if (showRentAgain)
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: FilledButton(
                            onPressed: onRentAgain,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Rent again',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
