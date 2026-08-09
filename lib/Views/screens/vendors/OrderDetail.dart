import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:jebby/utils/api_headers.dart';
import 'package:intl/intl.dart';
import 'package:jebby/res/app_url.dart';
import 'package:jebby/res/color.dart';
import 'package:jebby/utils/show_snackbar.dart';
import 'package:jebby/Views/screens/vendors/MyOrders.dart';

import '../../../model/postOrderStatusUpdateModel.dart';
import '../../../view_model/apiServices.dart';

class OrderDetailScreen extends StatefulWidget {
  final dynamic prodId;
  final dynamic name;
  final dynamic price;
  final dynamic start;
  final dynamic end;
  final dynamic vendorId;
  final dynamic orderId;
  final dynamic orderComplete;
  final dynamic route;
  final dynamic email;
  final dynamic location;

  const OrderDetailScreen({
    super.key,
    this.prodId,
    this.name,
    this.price,
    this.start,
    this.end,
    this.vendorId,
    this.orderId,
    this.orderComplete,
    this.route,
    this.email,
    this.location,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailStateScreen();
}

class _OrderDetailStateScreen extends State<OrderDetailScreen> {
  static const Color _pageBg = Color(0xFFF3F3F5);
  static const Color _subtitleGrey = Color(0xFF72747A);
  static const Color _metaGrey = Color(0xFF9A9AA1);

  bool isLoading = true;
  bool isError = false;
  bool isEmpty = false;

  String _listingName = '';
  String _imageRelativePath = '';

  bool get _isNewRoute => widget.route?.toString().toLowerCase() == 'new';

  /// Matches legacy UI: primary action only when `orderComplete == 0`.
  bool get _isPending =>
      widget.orderComplete == 0 || widget.orderComplete == '0';

  bool get _showPendingState => !_isNewRoute && _isPending;

  String get _stateLabel {
    if (_isNewRoute) return 'NEW';
    if (_showPendingState) return 'PENDING';
    return 'COMPLETED';
  }

  Color get _stateBg {
    if (_isNewRoute || _showPendingState) return const Color(0xFFFFF3E0);
    return const Color(0xFFE8F5E9);
  }

  Color get _stateFg {
    if (_isNewRoute || _showPendingState) return const Color(0xFFE65100);
    return const Color(0xFF2E7D32);
  }

  void getProduct() {
    ApiRepository.shared.getProductsById(
      (list) {
        if (!mounted) return;
        if (list.data == null || list.data!.isEmpty) {
          setState(() {
            isLoading = false;
            isError = false;
            isEmpty = true;
          });
          return;
        }
        try {
          final data = ApiRepository.shared.getProductsByIdList!.data!;
          final path = data[1].images![0].path.toString();
          final title = data[0].name.toString();
          setState(() {
            isLoading = false;
            isError = false;
            isEmpty = false;
            _imageRelativePath = path;
            _listingName = title;
          });
        } catch (_) {
          setState(() {
            isLoading = false;
            isError = true;
            isEmpty = false;
          });
        }
      },
      (error) {
        if (error != null && mounted) {
          setState(() {
            isLoading = false;
            isError = true;
            isEmpty = false;
          });
        }
      },
      widget.prodId.toString(),
    );
  }

  void orderStatus(dynamic id, int status, String desc) {
    orderStatusUpdate(
      id,
      status,
      desc,
      widget.vendorId,
      widget.route.toString(),
    );
    showAppSnackbar('Status', 'Updating status…');
  }

  Future<PostOrderStatusUpdateModel> orderStatusUpdate(
    dynamic id,
    int status,
    String desc,
    dynamic vendorID,
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
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        ApiRepository.shared.getVenodorOrders(vendorID.toString(), (List) {
          if (mounted) {
            Get.off(() => const OrderRequestScreen());
          }
        }, (error) {});
      } catch (_) {}
    }
    return PostOrderStatusUpdateModel();
  }

  @override
  void initState() {
    super.initState();
    getProduct();
  }

  String _formatDateRange() {
    try {
      final s = DateFormat('d MMM yyyy').format(
        DateTime.parse(widget.start.toString()),
      );
      final e = DateFormat('d MMM yyyy').format(
        DateTime.parse(widget.end.toString()),
      );
      return '$s → $e';
    } catch (_) {
      return '${widget.start} → ${widget.end}';
    }
  }

  String _priceLine() {
    final p = widget.price?.toString() ?? '0';
    return '\$$p';
  }

  String _productHeading() {
    if (_listingName.isNotEmpty) return _listingName;
    return 'Listing';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
          style: IconButton.styleFrom(foregroundColor: Colors.black),
        ),
        centerTitle: true,
        title: Text(
          'Order Detail',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Loading listing…',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _subtitleGrey,
              ),
            ),
          ],
        ),
      );
    }
    if (isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, size: 48, color: _metaGrey),
              const SizedBox(height: 16),
              Text(
                'Could not load listing details.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: _subtitleGrey),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    isError = false;
                  });
                  getProduct();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
      );
    }
    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'No listing found for this order.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 15, color: _subtitleGrey),
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _stateBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _stateLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _stateFg,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildImageCard(),
                const SizedBox(height: 12),
                _buildListingSummaryCard(),
                const SizedBox(height: 12),
                _buildRenterCard(),
                if (!_isNewRoute && !_showPendingState) ...[
                  const SizedBox(height: 12),
                  _buildCompletedNote(),
                ],
              ],
            ),
          ),
        ),
        if (_isNewRoute)
          _buildRequestActions()
        else if (_showPendingState)
          _buildLogisticsAction(),
      ],
    );
  }

  Widget _buildImageCard() {
    final showNetwork = _imageRelativePath.isNotEmpty;

    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child:
              showNetwork
                  ? Image.network(
                    AppUrl.baseUrlM + _imageRelativePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                  : _imagePlaceholder(),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return ColoredBox(
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 48,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildListingSummaryCard() {
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
            Text(
              _productHeading(),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _priceLine(),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.date_range_outlined, size: 18, color: _subtitleGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rental period',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _subtitleGrey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _formatDateRange(),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRenterCard() {
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
            Text(
              'Renter',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _subtitleGrey,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow(
              Icons.person_outline_rounded,
              'Customer name',
              widget.name?.toString() ?? '—',
            ),
            const SizedBox(height: 12),
            _infoRow(
              Icons.email_outlined,
              'Email',
              widget.email?.toString() ?? '—',
            ),
            const SizedBox(height: 12),
            _infoRow(
              Icons.place_outlined,
              'Delivery',
              widget.location?.toString() ?? '—',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _metaGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _metaGrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedNote() {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: const Color(0xFF2E7D32),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This rental is marked complete. No further action is needed.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _subtitleGrey,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticsAction() {
    return Material(
      color: _pageBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                orderStatus(widget.orderId, 2, 'Order Completed');
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Reached logistic facility',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestActions() {
    return Material(
      color: _pageBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      orderStatus(widget.orderId, 3, 'Cancelled');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Decline',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      orderStatus(widget.orderId, 1, 'Approved');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Approve',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
