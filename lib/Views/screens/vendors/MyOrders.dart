import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jebby/res/color.dart';
import 'package:jebby/Views/screens/vendors/OrderDetail.dart';
import 'package:jebby/Views/screens/vendors/vendorhome.dart';
import 'package:provider/provider.dart';

import '../../../Services/provider/sign_in_provider.dart';
import '../../../model/postOrderStatusUpdateModel.dart';
import '../../../model/user_model.dart';
import '../../../res/app_url.dart';
import '../../../view_model/apiServices.dart';
import '../../../view_model/user_view_model.dart';

class OrderRequestScreen extends StatefulWidget {
  const OrderRequestScreen({super.key});

  @override
  State<OrderRequestScreen> createState() => _OrderRequestScreenState();
}

class _OrderRequestScreenState extends State<OrderRequestScreen> {
  static const Color _pageBg = Color(0xFFF3F3F5);
  static const Color _subtitleGrey = Color(0xFF72747A);
  static const Color _pillTrack = Color(0xFFE8E8EC);

  /// 0 = New (status 0), 1 = Pending (status 1), 2 = Completed (status 2)
  int selectedTab = 0;

  EdgeInsets _listBottomPadding(BuildContext context) {
    return EdgeInsets.only(
      bottom: MediaQuery.of(context).padding.bottom + 24,
    );
  }

  bool isLoading = true;
  bool isError = false;
  bool isEmpty = false;

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

  void orderStatus(dynamic id, int status, String desc) {
    orderStatusUpdate(id, status, desc, sourceId, 'listing');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Updating status…',
          style: GoogleFonts.inter(),
        ),
      ),
    );
  }

  Future<PostOrderStatusUpdateModel> orderStatusUpdate(
    dynamic id,
    int status,
    String desc,
    String vendorID,
    String route,
  ) async {
    final request = json.encode(<String, dynamic>{
      'id': id,
      'status': status,
      'description': desc,
    });

    final response = await http.post(
      Uri.parse(AppUrl.orderStatusById),
      body: request,
      headers: {'Content-type': 'application/json'},
    );
    if (response.statusCode == 200) {
      try {
        ApiRepository.shared.getVenodorOrders(vendorID.toString(), (List) {
          if (mounted) {
            setState(() {});
          }
        }, (error) {});
      } catch (error) {
        // onError(error.toString());
      }
    }
    return PostOrderStatusUpdateModel();
  }

  void _openNewOrderDetail({
    required String name,
    required String id,
    required String price,
    required String start,
    required String end,
    required dynamic orderId,
    required String email,
    required String location,
    required String nego_price,
  }) {
    Get.to(
      () => OrderDetailScreen(
        prodId: id,
        name: name,
        price: price,
        start: start,
        end: end,
        vendorId: sourceId,
        orderId: orderId,
        orderComplete: 0,
        route: 'new',
        email: email,
        location: location,
        nego_price: nego_price,
      ),
    );
  }

  Widget _vendorNewOrderRequestCard({
    required String name,
    required dynamic orderId,
    required String id,
    required String price,
    required String start,
    required String end,
    required String email,
    required String location,
    required String nego_price,
  }) {
    final priceStr = _displayPrice(price, nego_price);
    final due = _formatVendorDate(end);
    return _VendorOrderCardShell(
      badgeLabel: 'NEW',
      badgeBg: const Color(0xFFFFF3E0),
      badgeFg: const Color(0xFFE65100),
      displayPrice: priceStr,
      title: name,
      metaLine: 'Return due: $due',
      onHeaderTap:
          () => _openNewOrderDetail(
            name: name,
            id: id,
            price: price,
            start: start,
            end: end,
            orderId: orderId,
            email: email,
            location: location,
            nego_price: nego_price,
          ),
      actionRow: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: () => orderStatus(orderId, 1, 'Order Approved'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Approve',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: () => orderStatus(orderId, 3, 'Order Approved'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.grey.shade500,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Decline',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
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
          _pillTab(0, 'New'),
          _pillTab(1, 'Pending'),
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
    if (raw == null || raw.isEmpty || raw == 'null') return '—';
    try {
      return DateFormat('d/M/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _displayPrice(dynamic totalPrice, dynamic negoPrice) {
    final int nego;
    if (negoPrice == null) {
      nego = 0;
    } else if (negoPrice is int) {
      nego = negoPrice;
    } else {
      nego = int.tryParse(negoPrice.toString()) ?? 0;
    }
    if (nego != 0) return nego.toString();
    if (totalPrice == null) return '0';
    return totalPrice.toString();
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
        return _newOrdersList();
      case 1:
        return _pendingOrdersList();
      default:
        return _completedOrdersList();
    }
  }

  Widget _newOrdersList() {
    final newOrders = _allOrders().where((e) => e.status == 0).toList();
    if (newOrders.isEmpty) {
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
      itemCount: newOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final data = newOrders[index];
        return _vendorNewOrderRequestCard(
          name: data.name.toString(),
          orderId: data.id,
          id: data.productId.toString(),
          price: data.totalPrice.toString(),
          start: data.rentStart.toString(),
          end: data.originalReturn.toString(),
          email: data.email.toString(),
          location: data.location.toString(),
          nego_price: data.negoPrice.toString(),
        );
      },
    );
  }

  Widget _pendingOrdersList() {
    final list = _allOrders().where((e) => e.status == 1).toList();
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
      itemBuilder: (context, index) {
        final data = list[index];
        final name = data.name.toString();
        final price = data.totalPrice.toString();
        final start = data.rentStart.toString();
        final end = data.originalReturn.toString();
        final id = data.productId.toString();
        final orderId = data.id;
        final email = data.email.toString();
        final location = data.location.toString();
        final nego_price = data.negoPrice.toString();
        void openPending() {
          Get.to(
            () => OrderDetailScreen(
              prodId: id,
              name: name,
              price: price,
              start: start,
              end: end,
              vendorId: sourceId,
              orderId: orderId,
              orderComplete: 0,
              route: 'pending',
              email: email,
              location: location,
              nego_price: nego_price,
            ),
          );
        }

        return _VendorOrderCardShell(
          badgeLabel: 'PENDING',
          badgeBg: const Color(0xFFFFF3E0),
          badgeFg: const Color(0xFFE65100),
          displayPrice: _displayPrice(data.totalPrice, data.negoPrice),
          title: name,
          metaLine: 'Return due: ${_formatVendorDate(end)} · ${email}',
          onHeaderTap: openPending,
          actionRow: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: openPending,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Open order',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: openPending,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: const BorderSide(color: AppColors.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Details',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _completedOrdersList() {
    final list = _allOrders().where((e) => e.status == 2).toList();
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
      itemBuilder: (context, index) {
        final data = list[index];
        final name = data.name.toString();
        final price = data.totalPrice.toString();
        final start = data.rentStart.toString();
        final end = data.originalReturn.toString();
        final id = data.productId.toString();
        final orderId = data.id;
        final email = data.email.toString();
        final location = data.location.toString();
        final nego_price = data.negoPrice.toString();
        void openCompleted() {
          Get.to(
            () => OrderDetailScreen(
              prodId: id,
              name: name,
              price: price,
              start: start,
              end: end,
              vendorId: sourceId,
              orderId: orderId,
              orderComplete: 1,
              route: 'complete',
              email: email,
              location: location,
              nego_price: nego_price,
            ),
          );
        }

        return _VendorOrderCardShell(
          badgeLabel: 'COMPLETED',
          badgeBg: const Color(0xFFE8F5E9),
          badgeFg: const Color(0xFF2E7D32),
          displayPrice: _displayPrice(data.totalPrice, data.negoPrice),
          title: name,
          metaLine: 'Completed · Return was ${_formatVendorDate(end)}',
          onHeaderTap: openCompleted,
          actionRow: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: openCompleted,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'View summary',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: openCompleted,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: const BorderSide(color: AppColors.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Details',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Get.back();
              } else {
                Get.offAll(() => const VendrosHomeScreen());
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
                'Review new rentals, then track pending and completed orders.',
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
  final VoidCallback onHeaderTap;
  final Widget actionRow;

  const _VendorOrderCardShell({
    required this.badgeLabel,
    required this.badgeBg,
    required this.badgeFg,
    required this.displayPrice,
    required this.title,
    required this.metaLine,
    required this.onHeaderTap,
    required this.actionRow,
  });

  @override
  Widget build(BuildContext context) {
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
            InkWell(
              onTap: onHeaderTap,
              borderRadius: BorderRadius.circular(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: ColoredBox(
                        color: const Color(0xFFF5F5F5),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.grey.shade400,
                          size: 32,
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
                            Container(
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
            ),
            const SizedBox(height: 14),
            actionRow,
          ],
        ),
      ),
    );
  }
}
