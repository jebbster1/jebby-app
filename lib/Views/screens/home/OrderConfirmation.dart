import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:jebby/Views/widgets/address_autocomplete_field.dart';
import 'package:jebby/utils/google_places_address.dart';
import 'package:jebby/utils/show_snackbar.dart';
import 'package:jebby/res/app_url.dart';
import 'package:jebby/res/color.dart';
import 'package:jebby/view_model/getTax_modal.dart';

import '../../../view_model/apiServices.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final dynamic image;
  final dynamic name;
  final dynamic price;
  final dynamic orderId;
  final dynamic prodId;
  final dynamic location;
  final dynamic long;
  final dynamic lat;
  final dynamic username;
  final dynamic userid;
  final dynamic vendorID;

  const OrderConfirmationScreen({
    super.key,
    this.image,
    this.name,
    this.price,
    this.orderId,
    this.prodId,
    this.location,
    this.long,
    this.lat,
    this.username,
    this.userid,
    this.vendorID,
  });

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  static const Color _pageBg = Color(0xFFF3F3F5);
  static const Color _subtitleGrey = Color(0xFF72747A);
  /// Same as `ProductDetails` (`_accent` / `_starInactive`) and `MyProducts.productCard`.
  static const Color _starAccent = Color(0xFFF6AE02);
  static const Color _starInactive = Color(0xFFC6C8CF);

  bool isLoading = true;
  bool isError = false;

  getProducts() {
    ApiRepository.shared.getProductsById(
      (list) {
        if (!mounted) return;
        if (list.data!.isEmpty) {
          setState(() {
            isLoading = false;
            isError = false;
          });
        } else {
          setState(() {
            isLoading = false;
            isError = false;
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
      widget.prodId.toString(),
    );
  }

  late var vendorAccountId;
  bool orderVisibility = false;
  final _locationController = TextEditingController();
  ParsedUsAddress? _resolvedAddress;

  var newLocation = "";

  void getUserData() {
    ApiRepository.shared.userCredential(
      (List) {
        if (!mounted) return;
        if (List.data!.isNotEmpty) {
          setState(() {
            vendorAccountId =
                ApiRepository.shared.getUserCredentialModelList!.data![0].accountId.toString();
            orderVisibility = true;
          });
        }
      },
      (error) {
        if (error != null && mounted) {
          setState(() {});
        }
      },
      widget.vendorID.toString(),
    );
  }

  var Latitiude = "";
  var Longitude = "";

  void _clearResolvedAddress() {
    setState(() {
      _resolvedAddress = const ParsedUsAddress();
      Latitiude = "";
      Longitude = "";
      newLocation = "";
    });
  }

  Future<void> _applySelectedAddress(ParsedUsAddress address) async {
    setState(() {
      _resolvedAddress = address;
      _locationController.text = address.displayLine;
      newLocation = address.displayLine;
      if (address.hasCoordinates) {
        Latitiude = address.latitude!.toString();
        Longitude = address.longitude!.toString();
      } else {
        Latitiude = "";
        Longitude = "";
        newLocation = "";
      }
    });

    if (address.hasCoordinates) {
      await _getZipCodeFromCoordinates(address.latitude!, address.longitude!);
    } else if (address.hasPostalCode) {
      await getSalesTax(address.postalCode);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  String? zipCode;
  String? countryCode;

  Future<void> _getZipCodeFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        zipCode = placemark.postalCode ?? '';
        countryCode = placemark.isoCountryCode ?? '';
        getSalesTax(placemark.postalCode ?? '');
      }
    } catch (e) {}
  }

  double taxValue = 0;

  Future<void> getSalesTax(zipcode) async {
    String apiKey = dotenv.env['apiKey'] ?? 'No secret key found';
    final apiUrl = 'https://api.taxjar.com/v2/rates?zip=${zipcode}';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final taxRates = jsonResponse['rate']['combined_rate'];
      setState(() {
        taxValue = double.parse(taxRates);
      });
    }
  }

  var JebbyFee = 0;
  dynamic array = [];
  Map<String, dynamic> _data = {};

  Future<void> _loadData() async {
    try {
      final data = await GetJebbyfee.fetchData();
      if (!mounted) return;
      setState(() {
        _data = data;
        array = _data['data'] ?? [];
        JebbyFee = array.length > 0 ? int.parse(array[0]['jebby_fees'].toString()) : 0;
      });
    } catch (e) {}
  }

  bool locationVisibility = false;

  int _priceInt() {
    try {
      return int.parse(widget.price.toString().trim());
    } catch (_) {
      return 0;
    }
  }

  /// Mirrors `ProductDetails._myProductsStyleStars`.
  Widget _myProductsStyleStars(double rating, {double size = 18}) {
    final filledStars = (rating.isNaN ? 0.0 : rating).round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final active = index < filledStars;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            active ? Icons.star : Icons.star_border,
            color: active ? _starAccent : _starInactive,
            size: size,
          ),
        );
      }),
    );
  }

  String _productImageUrl() {
    final p = widget.image?.toString().trim() ?? '';
    if (p.isEmpty) return '';
    if (p.toLowerCase().startsWith('http')) return p;
    final base = AppUrl.baseUrlM;
    if (base.endsWith('/')) return base + (p.startsWith('/') ? p.substring(1) : p);
    return '$base/${p.startsWith('/') ? p.substring(1) : p}';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    getUserData();
    getProducts();
    _getZipCodeFromCoordinates(widget.lat, widget.long);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(
      Theme.of(context).textTheme.apply(
        bodyColor: const Color(0xFF1A1A1A),
        displayColor: const Color(0xFF1A1A1A),
      ),
    );

    final p = _priceInt();
    final jebbyLine = p * JebbyFee / 100;
    final taxLine = taxValue * 100;
    final total = (p + jebbyLine + taxLine).round();
    final taxDisplay = taxLine.toString();
    final jebbyDisplay = jebbyLine.toString();

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
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Confirmation',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Review your rental and pay to complete reorder.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _subtitleGrey,
                ),
              ),
              const SizedBox(height: 20),
              _buildProductCard(),
              const SizedBox(height: 16),
              _buildDeliveryCard(),
              const SizedBox(height: 16),
              _buildSummaryCard(p, taxDisplay, jebbyDisplay, total),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed:
                      orderVisibility
                          ? () {
                            if (locationVisibility &&
                                _locationController.text.trim().isNotEmpty &&
                                ParsedUsAddress.mapLocationValidationError(
                                      _resolvedAddress,
                                    ) !=
                                    null) {
                              showAppErrorSnackbar(
                                ParsedUsAddress.selectFromSuggestionsMessage,
                                title: 'Required',
                              );
                              return;
                            }
                            ApiRepository.shared.reOrderStripePayment(
                              widget.price,
                              vendorAccountId,
                              context,
                              widget.orderId,
                              newLocation == "" ? widget.location : newLocation,
                              (jebbyLine + taxLine).round(),
                            );
                          }
                          : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Pay now',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard() {
    final url = _productImageUrl();
    final prodList = ApiRepository.shared.getProductsByIdList?.data;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 88,
                height: 88,
                child:
                    url.isEmpty
                        ? ColoredBox(
                          color: const Color(0xFFF5F5F5),
                          child: Icon(Icons.image_outlined, color: Colors.grey.shade400),
                        )
                        : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder:
                              (_, __) => ColoredBox(
                                color: const Color(0xFFF5F5F5),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
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
                                child: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade500),
                              ),
                        ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name?.toString() ?? '—',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${widget.price}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  if (!isLoading && !isError && prodList != null && prodList.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _myProductsStyleStars(
                          double.tryParse(prodList[0].stars?.toString() ?? '0') ?? 0,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${prodList[0].length?.toString() ?? '0'}) Reviews',
                          style: GoogleFonts.inter(fontSize: 13, color: _subtitleGrey),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rental location',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      locationVisibility = true;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'Change',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.username?.toString() ?? '',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.location?.toString() ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.35,
                color: _subtitleGrey,
              ),
            ),
            if (locationVisibility) ...[
              const SizedBox(height: 16),
              Text(
                'Location',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _subtitleGrey,
                ),
              ),
              const SizedBox(height: 8),
              AddressAutocompleteField(
                controller: _locationController,
                resolvedAddress: _resolvedAddress,
                onEditingStarted: _clearResolvedAddress,
                onAddressSelected: _applySelectedAddress,
                hint: 'Search address',
                decoration: InputDecoration(
                  hintText: 'Search address',
                  hintStyle: GoogleFonts.inter(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryColor,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int p, String taxDisplay, String jebbyDisplay, int total) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _summaryRow('Sub total', '\$$p'),
            Divider(height: 24, color: Colors.grey.shade200),
            _summaryRow('Sales tax', '\$$taxDisplay'),
            Divider(height: 24, color: Colors.grey.shade200),
            _summaryRow('Jebby fee', '\$$jebbyDisplay'),
            Divider(height: 24, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '\$$total',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryColor,
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

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF4A4A4F),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
