import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/Services/provider/sign_in_provider.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:jebby/Views/screens/auth/register.dart';
import 'package:jebby/res/color.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../../model/user_model.dart';
import '../../../res/app_url.dart';
import '../../../utils/profile_image.dart';
import '../../../utils/rental_date.dart';
import '../../../view_model/apiServices.dart';
import '../../../view_model/user_view_model.dart';
import 'package:jebby/Services/analytics_service.dart';

// ignore: must_be_immutable
class CheckoutScreen extends StatefulWidget {
  var userId;
  var productID;
  var rentalStartDate;
  var rentalEndDate;
  String vendorName;
  String vendorAddress;
  String cell;
  String vendorImage;
  var vendorID;
  var availableFrom;
  var availableTo;
  var price;
  var vendorAccountId;
  var userName;
  var email;
  var location;
  var lat;
  var long;
  var delivery_charges;
  var JebbyFee;
  var security_deposit;
  var zipCode;
  var countryCode;
  var pickupWindowBegin;
  var pickupWindowEnd;
  var returnWindowBegin;
  var returnWindowEnd;
  String transportType;

  CheckoutScreen(
    this.userId,
    this.productID,
    this.rentalStartDate,
    this.rentalEndDate,
    this.vendorName,
    this.vendorAddress,
    this.cell,
    this.vendorImage,
    this.vendorID,
    this.availableFrom,
    this.availableTo,
    this.price,
    this.vendorAccountId,
    this.userName,
    this.email,
    this.location,
    this.lat,
    this.long,
    this.delivery_charges,
    this.JebbyFee,
    this.security_deposit,
    this.zipCode,
    this.countryCode, {
    this.pickupWindowBegin,
    this.pickupWindowEnd,
    this.returnWindowBegin,
    this.returnWindowEnd,
    this.transportType = 'pickup',
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final termscontroller = Get.put(TermsController());

  /// Same palette as [ProductDetailScreen] for a consistent renter flow.
  static const Color _accent = Color(0xFFF6AE02);
  static const Color _titleDark = Color(0xFF1B1B1F);
  static const Color _labelGrey = Color(0xFF72747A);
  static const Color _sheetInnerBg = Color(0xFFF7F7F9);

  final PageController _pageController = PageController();
  int _imageIndex = 0;
  bool _checkoutLoading = false;

  DateTime selectedDate = DateTime.now();
  DateTime selectedDate1 = DateTime.now();

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  var _locationController = TextEditingController();
  double taxValue = 0;

  int dc = 0;
  int diff = 0;
  int Jebby = 0;

  /// Safe int from messy money strings (empty → 0, no FormatException).
  int _digits(dynamic v) =>
      int.tryParse('${v ?? ''}'.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  bool get _usesDelivery => widget.transportType == 'delivery';

  String _windowSummary(dynamic begin, dynamic end) {
    final beginText = begin?.toString() ?? '';
    final endText = end?.toString() ?? '';
    if (beginText.isEmpty || endText.isEmpty) return 'Not selected';
    String clock(String raw) {
      final timePart = raw.contains(' ') ? raw.split(' ').last : raw;
      final parts = timePart.split(':');
      if (parts.length < 2) return timePart;
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour % 12 == 0 ? 12 : hour % 12;
      return '$hour12:${minute.padLeft(2, '0')} $period';
    }

    final datePart = beginText.contains(' ') ? beginText.split(' ').first : widget.rentalStartDate?.toString() ?? '';
    return '$datePart ${clock(beginText)} - ${clock(endText)}';
  }

  Future<void> getSalesTax() async {
    String apiKey = dotenv.env['apiKey'] ?? 'No secret key found';
    final apiUrl = 'https://api.taxjar.com/v2/rates?zip=${widget.zipCode}';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      try {
        final m = json.decode(response.body) as Map;
        final r = m['rate'] as Map?;
        setState(() {
          taxValue = double.tryParse('${r?['combined_rate'] ?? ''}') ?? 0;
        });
      } catch (_) {}
    }
  }

  @override
  void initState() {
    super.initState();
    getSalesTax();
    getData();
    profileData(context);
    emailController.text = widget.email;
    _locationController.text = widget.location;
    selectedDate = rentalDateToDateTime(widget.rentalStartDate?.toString()) ?? DateTime.now();
    selectedDate1 = rentalDateToDateTime(widget.rentalEndDate?.toString()) ?? DateTime.now();
    diff = selectedDate1.difference(selectedDate).inDays;
    dc = _usesDelivery ? _digits(widget.delivery_charges) : 0;
    Jebby = _digits(widget.JebbyFee);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _checkoutGalleryUrls() {
    final urls = <String>[];
    final list = ApiRepository.shared.getProductsByIdList;
    final data = list?.data;
    if (data != null && data.isNotEmpty) {
      final imageEntries = <dynamic>[];
      if (data.length >= 2 && data[1].images != null) {
        imageEntries.addAll(data[1].images!);
      } else if (data[0].images != null) {
        imageEntries.addAll(data[0].images!);
      }
      for (final im in imageEntries) {
        final p = im.path?.toString() ?? '';
        if (p.isNotEmpty) urls.add(AppUrl.baseUrlM + p);
      }
    }
    if (urls.isEmpty) {
      final v = ProfileImage.sanitizePath(widget.vendorImage.toString());
      final vendorUrl = ProfileImage.resolveUrl(AppUrl.baseUrlM, v);
      if (vendorUrl != null) urls.add(vendorUrl);
    }
    return urls;
  }

  Future getData() async {
    final sp = context.read<SignInProvider>();
    final usp = context.read<UserViewModel>();
    usp.getUser();
    sp.getDataFromSharedPreferences();
  }

  Future<UserModel> getUserDate() => UserViewModel().getUser();

  String? token;
  String userID = "";
  String? fullname;
  String? email;
  String? phoneNumber;
  String? role;

  void profileData(BuildContext context) async {
    getUserDate()
        .then((value) async {
          token = value.token.toString();
          userID = value.id.toString();
          fullname = value.name.toString();
          email = value.email.toString();
          phoneNumber = value.phoneNumber.toString();
          role = value.role.toString();
        })
        .onError((error, stackTrace) {
          if (kDebugMode) {}
        });
  }

  int _rentalDayCount() {
    final d = selectedDate1.difference(selectedDate).inDays;
    return d + 1;
  }

  num _rentalSubtotal() {
    final days = _rentalDayCount();
    return widget.price * days;
  }

  num _jebbyFeesAmount() => _rentalSubtotal() * Jebby / 100;

  num _grandTotal() {
    final daysDiff = selectedDate1.difference(selectedDate).inDays;
    final sub = widget.price * (daysDiff + 1);
    final jebbyFees = (sub * Jebby / 100);
    return (sub + dc + jebbyFees + _digits(widget.security_deposit)) +
        (sub * taxValue);
  }

  Future<void> _onCheckoutPressed() async {
    if (_checkoutLoading) return;

    setState(() => _checkoutLoading = true);
    try {
      AnalyticsService.instance.track(
        'booking_requested',
        props: {
          'product_id': widget.productID,
          'user_id': widget.userId,
        },
      );
      await ApiRepository.shared.postOrder(
        context,
        widget.userId,
        widget.productID,
        widget.rentalStartDate,
        widget.rentalEndDate,
        widget.location,
        widget.lat,
        widget.long,
        widget.security_deposit.toString(),
        transportType: widget.transportType,
        transportFee: dc,
        pickupWindowBegin: widget.pickupWindowBegin?.toString(),
        pickupWindowEnd: widget.pickupWindowEnd?.toString(),
        returnWindowBegin: widget.returnWindowBegin?.toString(),
        returnWindowEnd: widget.returnWindowEnd?.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _checkoutLoading = false);
      }
    }
  }

  TextStyle _productTitleStyle() {
    return GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: _titleDark,
      height: 1.25,
    );
  }

  TextStyle _labelStyle() {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: _labelGrey,
    );
  }

  TextStyle _valueStyle() {
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: _titleDark,
    );
  }

  TextStyle _grandLabelStyle() {
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: _titleDark,
    );
  }

  TextStyle _grandValueStyle() {
    return GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: _titleDark,
    );
  }

  TextStyle _ctaTextStyle() {
    return GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );
  }

  Widget _roundedPanel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _sheetInnerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8EC)),
      ),
      child: child,
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: _labelStyle())),
          Text(value, style: _valueStyle()),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey.shade300);
  }

  Widget _buildImageHeader(Size size) {
    final h = size.height * 0.34;
    final urls = _checkoutGalleryUrls();
    final hasGallery = urls.isNotEmpty;

    return SizedBox(
      height: h,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!hasGallery)
            ColoredBox(
              color: Colors.grey.shade300,
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: Colors.grey.shade500,
                ),
              ),
            )
          else
            PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _imageIndex = i),
              itemCount: urls.length,
              itemBuilder:
                  (_, i) => CachedNetworkImage(
                    imageUrl: urls[i],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: h,
                    placeholder:
                        (_, __) => ColoredBox(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor),
                            ),
                          ),
                        ),
                    errorWidget:
                        (_, __, ___) => ColoredBox(
                          color: Colors.grey.shade300,
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: Colors.grey.shade500,
                          ),
                        ),
                  ),
            ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 14, top: 10),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => Get.back(),
                    customBorder: const CircleBorder(),
                    splashColor: Colors.black26,
                    highlightColor: Colors.black12,
                    child: Ink(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xE6FFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (hasGallery && urls.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(urls.length, (i) {
                  final active = _imageIndex == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 8 : 6,
                    height: active ? 8 : 6,
                    decoration: BoxDecoration(
                      color:
                          active
                              ? _accent
                              : Colors.white.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSheet({required double bottomInset}) {
    final list = ApiRepository.shared.getProductsByIdList;
    final productName =
        (list?.data != null && list!.data!.isNotEmpty)
            ? list.data![0].name.toString()
            : 'Order summary';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 28, 20, 20 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(productName, style: _productTitleStyle()),
            const SizedBox(height: 16),
            _roundedPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _usesDelivery ? 'Delivery address' : 'Pickup location',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _labelGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.location?.toString() ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _titleDark,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _roundedPanel(
              child: Column(
                children: [
                  _summaryRow('Rental price', '\$${widget.price} / day'),
                  _divider(),
                  _summaryRow(
                    'Pickup or delivery',
                    _usesDelivery ? 'Delivery & Retrieval' : 'Pickup & Return',
                  ),
                  _divider(),
                  _summaryRow('Pickup window', _windowSummary(widget.pickupWindowBegin, widget.pickupWindowEnd)),
                  _divider(),
                  _summaryRow('Return window', _windowSummary(widget.returnWindowBegin, widget.returnWindowEnd)),
                  _divider(),
                  _summaryRow('Renting total', '\$${_rentalSubtotal()}'),
                  _divider(),
                  _summaryRow('Jebby fees', '\$${_jebbyFeesAmount()}'),
                  _divider(),
                  _summaryRow(
                    'Security deposit',
                    '\$${widget.security_deposit}',
                  ),
                  if (_usesDelivery) ...[
                    _divider(),
                    _summaryRow(
                      'Transport fee',
                      '\$${widget.delivery_charges == '' ? 0 : widget.delivery_charges}',
                    ),
                  ],
                  _divider(),
                  _summaryRow(
                    'Sales tax',
                    '${(taxValue * 100).toStringAsFixed(2)}%',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE8E8EC)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Grand total', style: _grandLabelStyle()),
                        ),
                        Text(
                          '\$${_grandTotal().toStringAsFixed(2)}',
                          style: _grandValueStyle(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final termsAccepted = termscontroller.termsValue.value;
              final canCheckout = termsAccepted && !_checkoutLoading;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      checkboxTheme: CheckboxThemeData(
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return kprimaryColor;
                          }
                          return null;
                        }),
                      ),
                    ),
                    child: Material(
                      color: _sheetInnerBg,
                      borderRadius: BorderRadius.circular(16),
                      child: CheckboxListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          'I agree to the Terms of Service and Privacy Policy',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.35,
                            color: _titleDark,
                          ),
                        ),
                        value: termsAccepted,
                        onChanged: (v) {
                          termscontroller.chanegValue(v ?? false);
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kprimaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: canCheckout ? _onCheckoutPressed : null,
                      child: _checkoutLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Request booking', style: _ctaTextStyle()),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildImageHeader(size)),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: _buildCheckoutSheet(bottomInset: bottomInset),
            ),
          ),
        ],
      ),
    );
  }
}
