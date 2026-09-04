import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/services/provider/sign_in_provider.dart';
import 'package:jebby/views/screens/home/checkout.dart';
import 'package:jebby/views/screens/profile/user_profile.dart';
import 'package:jebby/views/widgets/address_autocomplete_field.dart';
import 'package:jebby/utils/google_places_address.dart';
import 'package:jebby/utils/profile_image.dart';
import 'package:jebby/services/fee_values_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../models/user_model.dart';
import '../../../models/handoff_window.dart';
import '../../../constants/app_url.dart';
import 'package:jebby/repositories/api_repository.dart';

import '../../../view_models/user_view_model.dart';
import '../../../utils/delivery_radius.dart';
import '../../../utils/rental_date.dart';
import '../../../utils/show_snackbar.dart';

class RentNowScreen extends StatefulWidget {
  final String vendorName;
  final String vendorAddress;
  final String cell;
  final String vendorImage;
  final dynamic vendorID;
  final dynamic productID;
  final dynamic availableFrom;
  final dynamic availableTo;
  final dynamic price;
  final dynamic vendorAccountId;
  final dynamic route;
  final dynamic delivery_charges;
  final dynamic security_deposit;
  final bool offersPickup;
  final bool offersDelivery;
  final String productAddress;
  final String productLat;
  final String productLng;
  final List<HandoffWindow> handoffWindows;
  final int? deliveryRadiusMiles;

  RentNowScreen(
    this.vendorName,
    this.vendorAddress,
    this.cell,
    this.vendorImage,
    this.vendorID,
    this.productID,
    this.availableFrom,
    this.availableTo,
    this.price,
    this.vendorAccountId,
    this.route,
    this.delivery_charges,
    this.security_deposit,
    this.offersPickup,
    this.offersDelivery,
    this.productAddress,
    this.productLat,
    this.productLng,
    this.handoffWindows,
    this.deliveryRadiusMiles,
  );

  @override
  State<RentNowScreen> createState() => _RentNowScreenState();
}

class _RentNowScreenState extends State<RentNowScreen> {
  static const Color _accent = Color(0xFFF6AE02);
  static const Color _starInactive = Color(0xFFC6C8CF);
  static const Color _pageBg = Color(0xFFF3F3F5);
  static const Color _bodyGrey = Color(0xFF6D6D75);
  static const Color _titleDark = Color(0xFF1B1B1F);

  bool onlinepay = false;
  bool cod = false;
  final PageController _rentPageController = PageController();
  int _rentImageIndex = 0;

  var fromdate;
  var todate;

  DateTime selectedDate = DateTime.now();
  DateTime selectedDate1 = DateTime.now();
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isSelectingEnd = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController ShippingAddressController = TextEditingController();

  var _locationController = TextEditingController();
  var _CurrentAddressController = TextEditingController();
  ParsedUsAddress? _resolvedAddress;
  var Latitiude = "";
  var Longitude = "";
  var uuid = new Uuid();
  var vuid = new Uuid();

  var myFormat = DateFormat('dd, MMM/yyyy');
  var myFormat1 = DateFormat('dd, MMM/yyyy');
  var myPillFormat = DateFormat('MM/dd/yyyy');
  final DateFormat _rangeTitleFormat = DateFormat('MMM d');

  void _clearResolvedAddress() {
    setState(() {
      _resolvedAddress = const ParsedUsAddress();
      Latitiude = "";
      Longitude = "";
    });
  }

  Future<void> _applySelectedAddress(ParsedUsAddress address) async {
    final display = address.displayLine;
    setState(() {
      _resolvedAddress = address;
      _CurrentAddressController.text = display;
      _locationController.text = display;
      if (address.hasCoordinates) {
        Latitiude = address.latitude!.toString();
        Longitude = address.longitude!.toString();
      } else {
        Latitiude = "";
        Longitude = "";
      }
    });

    if (address.hasCoordinates) {
      await _getZipCodeFromCoordinates(
        address.latitude!,
        address.longitude!,
      );
    } else if (address.hasPostalCode) {
      setState(() => zipCode = address.postalCode);
    }
  }

  String? zipCode;
  String? countryCode;
  String _transportType = 'pickup';
  HandoffWindow? _pickupWindow;
  HandoffWindow? _returnWindow;
  List<RentalWindow> _bookedDates = [];

  List<HandoffWindow> get _listingWindows =>
      widget.handoffWindows.isNotEmpty ? widget.handoffWindows : HandoffWindow.defaultSlots;

  void _ensureWindowDefaults() {
    _pickupWindow ??= _listingWindows.first;
    _returnWindow ??= _listingWindows.first;
  }

  Map<String, String> _bookingWindowPayload() {
    final pickup = _pickupWindow ?? _listingWindows.first;
    final ret = _returnWindow ?? _listingWindows.first;
    final pickupDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final returnDate = DateFormat('yyyy-MM-dd').format(selectedDate1);
    return {
      'pickupWindowBegin': pickup.beginOnDate(pickupDate),
      'pickupWindowEnd': pickup.endOnDate(pickupDate),
      'returnWindowBegin': ret.beginOnDate(returnDate),
      'returnWindowEnd': ret.endOnDate(returnDate),
    };
  }

  Widget _handoffWindowPicker({
    required String title,
    required String dateLabel,
    required HandoffWindow? selected,
    required ValueChanged<HandoffWindow> onSelected,
  }) {
    final windows = _listingWindows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: _titleDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(dateLabel, style: GoogleFonts.inter(fontSize: 13, color: _bodyGrey)),
        const SizedBox(height: 8),
        if (windows.length == 1)
          Text(
            windows.first.displayRange,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: _titleDark),
          )
        else
          ...windows.map(
            (window) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _windowChip(
                window.displayRange,
                selected == window,
                () => onSelected(window),
              ),
            ),
          ),
      ],
    );
  }

  Widget _windowChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF4D6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _accent : const Color(0xFFE1E1E1)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _titleDark),
        ),
      ),
    );
  }
  Future<void> _getZipCodeFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        zipCode = placemark.postalCode ?? '';
        countryCode = placemark.isoCountryCode ?? '';
      } else {}
    } catch (e) {}
  }

  dynamic array = [];
  late Map<String, dynamic> _data;

  Future<void> _loadData() async {
    try {
      final data = await FeeValuesService.fetchValues();
      setState(() {
        _data = data;
        array = _data['data'];
      });
      JebbyFee = array.length > 0 ? array[0]['jebby_fees'] : 0;
    } catch (e) {}
  }

  void pre() async {
    SharedPreferences Prefrences = await SharedPreferences.getInstance();

    nameController.text = Prefrences.getString('fullname').toString();
    emailController.text = Prefrences.getString('email').toString();

    if (_usesDelivery) {
      await _applyUserDeliveryAddress();
    } else {
      _applyPickupLocation();
    }
  }

  Future<void> _applyUserDeliveryAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final storedAddress = prefs.getString('address');
    final addressText = storedAddress ?? '';
    final latStr = prefs.getString('latitude') ?? '';
    final lngStr = prefs.getString('longitude') ?? '';

    if (!mounted) return;
    setState(() {
      _CurrentAddressController.text = addressText;
      _locationController.text = addressText;
      Latitiude = latStr;
      Longitude = lngStr;
      if (addressText.isNotEmpty) {
        _resolvedAddress = ParsedUsAddress(
          formattedAddress: addressText,
          latitude: double.tryParse(latStr),
          longitude: double.tryParse(lngStr),
        );
      } else {
        _resolvedAddress = null;
      }
    });

    final lat = double.tryParse(latStr);
    final lng = double.tryParse(lngStr);
    if (lat != null && lng != null) {
      await _getZipCodeFromCoordinates(lat, lng);
      if (mounted) setState(() {});
    }
  }

  void _applyPickupLocation() {
    setState(() {
      _locationController.text = widget.productAddress;
      _CurrentAddressController.clear();
      _resolvedAddress = null;
      Latitiude = widget.productLat;
      Longitude = widget.productLng;
    });
  }

  Future<void> _setTransportType(String value) async {
    if (_transportType == value) return;
    setState(() => _transportType = value);
    if (value == 'delivery') {
      await _applyUserDeliveryAddress();
    } else {
      _applyPickupLocation();
    }
  }

  Widget _buildFulfillmentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fulfillment',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: _titleDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how the item is handed off and returned.',
            style: GoogleFonts.inter(fontSize: 13, color: _bodyGrey, height: 1.35),
          ),
          const SizedBox(height: 14),
          if (widget.offersPickup && widget.offersDelivery) ...[
            Text(
              'Pickup or delivery',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: _titleDark,
              ),
            ),
            const SizedBox(height: 8),
            _transportChip('Pickup & Return', 'pickup'),
            const SizedBox(height: 8),
            _transportChip('Delivery & Retrieval', 'delivery'),
          ] else if (widget.offersPickup)
            _transportChip('Pickup & Return', 'pickup')
          else if (widget.offersDelivery)
            _transportChip('Delivery & Retrieval', 'delivery'),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          _handoffWindowPicker(
            title: 'Pickup time window',
            dateLabel: myPillFormat.format(selectedDate),
            selected: _pickupWindow,
            onSelected: (window) => setState(() => _pickupWindow = window),
          ),
          const SizedBox(height: 12),
          _handoffWindowPicker(
            title: 'Return time window',
            dateLabel: myPillFormat.format(selectedDate1),
            selected: _returnWindow,
            onSelected: (window) => setState(() => _returnWindow = window),
          ),
        ],
      ),
    );
  }

  String _pickupLocationLabel() {
    final address = widget.productAddress.trim();
    if (address.isNotEmpty) return address;
    final lat = double.tryParse(widget.productLat);
    final lng = double.tryParse(widget.productLng);
    if (lat != null && lng != null && (lat != 0 || lng != 0)) {
      return 'Lat ${lat.toStringAsFixed(4)}, Lng ${lng.toStringAsFixed(4)}';
    }
    return 'Location unavailable';
  }

  Widget _transportChip(String label, String value) {
    final selected = _transportType == value;
    return InkWell(
      onTap: () => _setTransportType(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF4D6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _accent : const Color(0xFFE1E1E1),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: _titleDark,
          ),
        ),
      ),
    );
  }

  bool get _usesDelivery => _transportType == 'delivery';

  String _checkoutLocation() {
    if (_usesDelivery) {
      return _CurrentAddressController.text.toString();
    }
    return widget.productAddress.trim().isNotEmpty
        ? widget.productAddress.trim()
        : _pickupLocationLabel();
  }

  String _checkoutLat() {
    if (_usesDelivery) {
      return Latitiude.toString();
    }
    return widget.productLat.isNotEmpty ? widget.productLat : '0';
  }

  String _checkoutLng() {
    if (_usesDelivery) {
      return Longitude.toString();
    }
    return widget.productLng.isNotEmpty ? widget.productLng : '0';
  }

  bool _hasRequiredLocation() {
    if (_usesDelivery) {
      return _resolvedAddress?.hasResolvedMapLocation == true;
    }
    return widget.productAddress.trim().isNotEmpty ||
        (double.tryParse(widget.productLat) ?? 0) != 0 ||
        (double.tryParse(widget.productLng) ?? 0) != 0;
  }

  double? get _listingLat => double.tryParse(widget.productLat);

  double? get _listingLng => double.tryParse(widget.productLng);

  double? get _deliveryLat => double.tryParse(Latitiude);

  double? get _deliveryLng => double.tryParse(Longitude);

  String? get _deliveryRadiusError => _usesDelivery
      ? DeliveryRadius.validationError(
          listingLat: _listingLat,
          listingLng: _listingLng,
          deliveryLat: _deliveryLat,
          deliveryLng: _deliveryLng,
          radiusMiles: widget.deliveryRadiusMiles,
        )
      : null;

  bool _validateDeliveryRadius({bool showError = true}) {
    final error = _deliveryRadiusError;
    if (error == null) return true;
    if (showError) {
      showAppErrorSnackbar(
        error,
        title: DeliveryRadius.snackbarTitleForMessage(error),
      );
    }
    return false;
  }

  String _selectedStartDate() => DateFormat('yyyy-MM-dd').format(selectedDate);

  String _selectedEndDate() => DateFormat('yyyy-MM-dd').format(selectedDate1);

  bool _validateNoDateConflict({bool showError = true}) {
    final conflict = findOverlappingRentalOrder(
      newStart: _selectedStartDate(),
      newEnd: _selectedEndDate(),
      existingOrders: _bookedDates,
    );
    if (conflict == null) return true;
    if (showError) {
      showAppErrorSnackbar(
        'These dates are unavailable. Choose different dates.',
        title: 'Dates unavailable',
      );
    }
    return false;
  }

  void _syncBookedDates() {
    final product = ApiRepository.shared.getProductsByIdList?.data?.firstOrNull;
    if (product == null || '${product.id}' != '${widget.productID}') return;
    _bookedDates = product.bookedDates;
  }

  Widget _deliveryRadiusHint() {
    final radius = widget.deliveryRadiusMiles;
    if (!_usesDelivery || radius == null || radius <= 0) {
      return const SizedBox.shrink();
    }

    final outOfRange = _deliveryRadiusError != null &&
        _resolvedAddress?.hasResolvedMapLocation == true;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery available within $radius mi of the listing location.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _bodyGrey,
              height: 1.35,
            ),
          ),
          if (outOfRange) ...[
            const SizedBox(height: 6),
            Text(
              _deliveryRadiusError!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.red.shade700,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.offersDelivery && !widget.offersPickup) {
      _transportType = 'delivery';
    }
    _loadData();
    getData();
    profileData(context);
    _syncBookedDates();
    selectedDate =
        DateTime.now(); //DateTime.parse(widget.availableFrom).isBefore(DateTime.now()) ? DateTime.now() : DateTime.parse(widget.availableFrom);
    selectedDate1 = DateTime.now().add(
      Duration(days: 1),
    );
    _ensureWindowDefaults();
    pre();
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
  String? role;
  void profileData(BuildContext context) async {
    getUserDate()
        .then((value) async {
          token = value.token.toString();
          userID = value.id.toString();
          fullname = value.name.toString();
          email = value.email.toString();
          role = value.role.toString();
        })
        .onError((error, stackTrace) {
          if (kDebugMode) {}
        });
  }

  var JebbyFee;

  Widget _myProductsStyleStars(double rating, {double size = 18}) {
    final normalized = rating.isNaN ? 0.0 : rating;
    final filledStars = normalized.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final active = index < filledStars;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            active ? Icons.star : Icons.star_border,
            color: active ? _accent : _starInactive,
            size: size,
          ),
        );
      }),
    );
  }

  List<String> _extractRentImageUrls() {
    final list = ApiRepository.shared.getProductsByIdList;
    final urls = <String>[];
    final data = list?.data;
    if (data == null || data.isEmpty) {
      return const [];
    }

    final imageEntries = <dynamic>[];
    if (data.length >= 2 && data[1].images != null) {
      imageEntries.addAll(data[1].images!);
    } else if (data[0].images != null) {
      imageEntries.addAll(data[0].images!);
    }

    for (final im in imageEntries) {
      final raw = (im.path ?? '').toString().trim();
      if (raw.isEmpty) continue;
      urls.add(raw.toLowerCase().startsWith('http') ? raw : AppUrl.baseUrlM + raw);
    }
    return urls;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isMissingVendorAccount(dynamic accountId) {
    final text = accountId?.toString().trim() ?? '';
    return text.isEmpty || text == '0';
  }

  int _money(dynamic v) =>
      int.tryParse('${v ?? ''}'.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  String _moneyLabel(dynamic v) {
    final amount = _money(v);
    return '\$${amount.toStringAsFixed(0)}';
  }

  Widget _pricingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 17,
              color: const Color(0xFF494A50),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 17,
              color: _titleDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  DateTime _lastAllowedDate() {
    final parsed = DateTime.tryParse(widget.availableTo.toString());
    final now = DateTime.now();
    if (parsed == null) return DateTime(now.year + 1, now.month, now.day);
    return _dateOnly(parsed);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isWithinSelectedRange(DateTime d) {
    final day = _dateOnly(d);
    final start = _dateOnly(selectedDate);
    final end = _dateOnly(selectedDate1);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  void _pickRangeDay(DateTime d) {
    final day = _dateOnly(d);
    final today = _dateOnly(DateTime.now());
    final last = _lastAllowedDate();
    if (day.isBefore(today) || day.isAfter(last)) return;
    if (isDayInBookedRange(day, _bookedDates)) return;

    setState(() {
      if (!_isSelectingEnd) {
        selectedDate = day;
        selectedDate1 = day;
        _isSelectingEnd = true;
        return;
      }

      if (day.isBefore(_dateOnly(selectedDate))) {
        selectedDate = day;
        selectedDate1 = day;
      } else {
        selectedDate1 = day;
        _isSelectingEnd = false;
      }
      _ensureWindowDefaults();
    });
  }

  void _shiftCalendarMonth(int delta) {
    final now = DateTime.now();
    final earliest = DateTime(now.year, now.month);
    final latest = DateTime(_lastAllowedDate().year, _lastAllowedDate().month);
    final next = DateTime(_calendarMonth.year, _calendarMonth.month + delta);
    if (next.isBefore(earliest) || next.isAfter(latest)) return;
    setState(() => _calendarMonth = next);
  }

  Widget _buildRangeCalendar(double resWidth) {
    final today = _dateOnly(DateTime.now());
    final lastAllowed = _lastAllowedDate();
    final start = _dateOnly(selectedDate);
    final end = _dateOnly(selectedDate1);
    final isSingleDaySelection = _isSameDay(start, end);
    final monthFirst = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final int leadingEmpty = monthFirst.weekday % 7;
    final int daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: resWidth * 0.89,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 22, color: Color(0xFF0A143D)),
              const SizedBox(width: 12),
              Text(
                '${_rangeTitleFormat.format(start)} - ${_rangeTitleFormat.format(end)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A143D),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: resWidth * 0.89,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _monthButton(Icons.chevron_left, () => _shiftCalendarMonth(-1)),
                  Expanded(
                    child: Center(
                      child: Text(
                        DateFormat('MMMM yyyy').format(_calendarMonth),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0A143D),
                        ),
                      ),
                    ),
                  ),
                  _monthButton(Icons.chevron_right, () => _shiftCalendarMonth(1)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(fontSize: 13, color: Color(0xFF59689A)),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 4),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leadingEmpty + daysInMonth,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 0,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (context, index) {
                  if (index < leadingEmpty) return const SizedBox.shrink();
                  final dayNum = index - leadingEmpty + 1;
                  final day =
                      DateTime(_calendarMonth.year, _calendarMonth.month, dayNum);
                  final isBooked = isDayInBookedRange(day, _bookedDates);
                  final disabled =
                      day.isBefore(today) || day.isAfter(lastAllowed) || isBooked;
                  final isStart = _isSameDay(day, start);
                  final isEnd = _isSameDay(day, end);
                  final inRange = _isWithinSelectedRange(day);
                  final row = index ~/ 7;

                  bool hasLeftInRange = false;
                  if (index > 0 && (index - 1) ~/ 7 == row) {
                    final prev = dayNum - 1;
                    if (prev >= 1) {
                      final prevDay =
                          DateTime(_calendarMonth.year, _calendarMonth.month, prev);
                      final prevDisabled =
                          prevDay.isBefore(today) || prevDay.isAfter(lastAllowed);
                      hasLeftInRange =
                          !prevDisabled && _isWithinSelectedRange(prevDay);
                    }
                  }

                  bool hasRightInRange = false;
                  if ((index + 1) ~/ 7 == row) {
                    final next = dayNum + 1;
                    if (next <= daysInMonth) {
                      final nextDay =
                          DateTime(_calendarMonth.year, _calendarMonth.month, next);
                      final nextDisabled =
                          nextDay.isBefore(today) || nextDay.isAfter(lastAllowed);
                      hasRightInRange =
                          !nextDisabled && _isWithinSelectedRange(nextDay);
                    }
                  }

                  Color textColor = const Color(0xFF0A143D);
                  BoxDecoration? rangeDeco;
                  BoxDecoration? dayDeco;
                  Alignment dayAlignment = Alignment.center;
                  if (isBooked && !day.isBefore(today)) {
                    dayDeco = BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFEBEE),
                      border: Border.all(color: const Color(0xFFE53935), width: 1.5),
                    );
                    textColor = const Color(0xFFC62828);
                  } else if (disabled) {
                    textColor = const Color(0xFFB8BED1);
                  } else if (inRange && !isSingleDaySelection) {
                    rangeDeco = BoxDecoration(
                      color: const Color(0xFFDCE1EB),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(hasLeftInRange ? 0 : 10),
                        bottomLeft: Radius.circular(hasLeftInRange ? 0 : 10),
                        topRight: Radius.circular(hasRightInRange ? 0 : 10),
                        bottomRight: Radius.circular(hasRightInRange ? 0 : 10),
                      ),
                    );
                  }
                  if (!disabled && !isBooked && (isStart || isEnd)) {
                    dayDeco = BoxDecoration(
                      color: const Color(0xFF0A143D),
                      borderRadius: BorderRadius.circular(10),
                    );
                    textColor = Colors.white;
                    if (isStart && hasRightInRange) {
                      dayAlignment = Alignment.centerLeft;
                    } else if (isEnd && hasLeftInRange) {
                      dayAlignment = Alignment.centerRight;
                    }
                  }

                  const double dayExtent = 30;
                  return GestureDetector(
                    onTap: disabled ? null : () => _pickRangeDay(day),
                    child: Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        height: dayExtent,
                        width: double.infinity,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            if (rangeDeco != null)
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: rangeDeco,
                                ),
                              ),
                            Align(
                              alignment: dayAlignment,
                              child: SizedBox(
                                width: dayExtent,
                                height: dayExtent,
                                child: DecoratedBox(
                                  decoration: dayDeco ?? const BoxDecoration(),
                                  child: Center(
                                    child: Text(
                                      '$dayNum',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
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
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _monthButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD9DCE5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF8D95AD)),
      ),
    );
  }

  @override
  void dispose() {
    _rentPageController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    double res_width = MediaQuery.of(context).size.width;
    double res_height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: _pageBg,
      body: Container(
        color: Colors.white,
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            clipBehavior: Clip.none,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: res_height * 0.36,
                  child: OverflowBox(
                    minWidth: res_width,
                    maxWidth: res_width,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: res_height * 0.36,
                      width: res_width,
                      child: Stack(
                    children: [
                      Positioned.fill(
                        child: Builder(
                          builder: (_) {
                            final images = _extractRentImageUrls();
                            if (images.isEmpty) {
                              return Image.asset(
                                'assets/images/placeholder.png',
                                fit: BoxFit.cover,
                              );
                            }
                            return PageView.builder(
                              controller: _rentPageController,
                              itemCount: images.length,
                              onPageChanged: (i) =>
                                  setState(() => _rentImageIndex = i),
                              itemBuilder: (context, i) {
                                return CachedNetworkImage(
                                  imageUrl: images[i],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Image.asset(
                                    'assets/images/placeholder.png',
                                    fit: BoxFit.cover,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                    'assets/images/placeholder.png',
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            );
                          },
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
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Builder(
                          builder: (_) {
                            final images = _extractRentImageUrls();
                            if (images.length <= 1) return const SizedBox.shrink();
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(images.length, (i) {
                                final active = i == _rentImageIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  width: active ? 8 : 6,
                                  height: active ? 8 : 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: active
                                        ? const Color(0xffF6AE02)
                                        : Colors.white.withOpacity(0.75),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
                    ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        ApiRepository.shared.getProductsByIdList!.data![0].name
                            .toString(),
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _myProductsStyleStars(
                      double.tryParse(
                            ApiRepository.shared
                                .getProductsByIdList!
                                .data![0]
                                .stars
                                .toString(),
                          ) ??
                          0,
                      size: 20,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Rental Price",
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        color: const Color(0xFF494A50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "\$${double.tryParse(widget.price.toString())?.toStringAsFixed(2) ?? widget.price}",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        color: _accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (_usesDelivery) ...[
                  _pricingRow(
                    'Delivery',
                    _moneyLabel(widget.delivery_charges),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  (ApiRepository.shared.getProductsByIdList!.data![0].description ??
                          ApiRepository.shared.getProductsByIdList!.data![0]
                              .specifications ??
                          '')
                      .toString(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: _bodyGrey,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 30),
                _buildRangeCalendar(res_width),
                SizedBox(height: 20),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Name",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: _titleDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 5),
                        Container(
                          width: res_width * 0.89,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: TextFormField(
                            controller: nameController,
                            style: GoogleFonts.inter(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(left: 10, top: 3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Email",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: _titleDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 5),
                        Container(
                          width: res_width * 0.89,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: TextFormField(
                            controller: emailController,
                            style: GoogleFonts.inter(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              disabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(left: 10, top: 3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                //             contentPadding: EdgeInsets.only(left: 10, top: 5),
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: res_height * 0.02),
                      Text(
                        _usesDelivery
                            ? 'Delivery address'
                            : 'Pickup location',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: _titleDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: res_height * 0.005),
                      if (_usesDelivery) ...[
                        SizedBox(
                          width: res_width * 0.89,
                          child: AddressAutocompleteField(
                            controller: _CurrentAddressController,
                            resolvedAddress: _resolvedAddress,
                            onEditingStarted: _clearResolvedAddress,
                            onAddressSelected: _applySelectedAddress,
                            hint: 'Start typing your address',
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFE1E1E1),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(15),
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFE1E1E1),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(15),
                                ),
                              ),
                            ),
                          ),
                        ),
                        _deliveryRadiusHint(),
                      ] else
                        Container(
                          width: res_width * 0.89,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: const Color(0xFFE1E1E1)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 20,
                                color: _accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _pickupLocationLabel(),
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    color: _bodyGrey,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: res_width * 0.89,
                  child: _buildFulfillmentSection(),
                ),

                SizedBox(height: 20),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                SizedBox(height: 20),

                Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.to(
                          () => UserProfileScreen(
                            vendorID: widget.vendorID,
                            vendorName: widget.vendorName,
                            vendorImage: widget.vendorImage,
                            vendorAddress: widget.vendorAddress,
                          ),
                        );
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ProfileImage.circularAvatar(
                            radius: 30,
                            baseUrl: AppUrl.baseUrlM,
                            imagePath: widget.vendorImage,
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.vendorName == ""
                                    ? "Vendor"
                                    : widget.vendorName,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (onlinepay == true) {
                          if (DateTime.parse(selectedDate.toString())
                                  .difference(
                                    DateTime.parse(selectedDate1.toString()),
                                  )
                                  .inMilliseconds >=
                              0) {
                            showAppErrorSnackbar('Please Enter Valid End Date', title: 'Required');
                          } else if (_hasRequiredLocation()) {
                            if (!_validateDeliveryRadius()) return;
                            if (!_validateNoDateConflict()) return;
                            showAppSnackbar('Required', 'Please Wait');
                            ApiRepository.shared.postOrder(
                              context,
                              userID,
                              widget.productID,
                              DateFormat(
                                'yyyy-MM-dd',
                              ).format(selectedDate).toString(),
                              DateFormat(
                                'yyyy-MM-dd',
                              ).format(selectedDate1).toString(),
                              _checkoutLocation(),
                              _checkoutLat(),
                              _checkoutLng(),
                              widget.security_deposit.toString(),
                            );
                          } else {
                            String message = "Fields Cannot Be Empty";
                            if (!_hasRequiredLocation()) {
                              message = _usesDelivery
                                  ? ParsedUsAddress.selectFromSuggestionsMessage
                                  : "Pickup location is unavailable for this listing";
                            }
                            showAppErrorSnackbar(message, title: 'Required');
                          }
                        } else {
                          if (DateTime.parse(selectedDate.toString())
                                  .difference(
                                    DateTime.parse(selectedDate1.toString()),
                                  )
                                  .inMilliseconds >=
                              0) {
                            showAppErrorSnackbar('Please Enter Valid End Date', title: 'Required');
                          } else if (_isMissingVendorAccount(widget.vendorAccountId)) {
                            showAppErrorSnackbar(
                              'Vendor account not found. Please ensure the vendor has completed Stripe onboarding.',
                            );
                          } else if (_hasRequiredLocation()) {
                            if (!_validateDeliveryRadius()) return;
                            if (!_validateNoDateConflict()) return;
                            final windows = _bookingWindowPayload();
                            Get.to(
                              () => CheckoutScreen(
                                userID,
                                widget.productID,
                                DateFormat(
                                  'yyyy-MM-dd',
                                ).format(selectedDate).toString(),
                                DateFormat(
                                  'yyyy-MM-dd',
                                ).format(selectedDate1).toString(),
                                widget.vendorName,
                                widget.vendorAddress,
                                widget.cell,
                                widget.vendorImage,
                                widget.vendorID,
                                widget.availableFrom,
                                widget.availableTo,
                                widget.price,
                                widget.vendorAccountId,
                                fullname,
                                emailController.text.toString(),
                                _checkoutLocation(),
                                _checkoutLat(),
                                _checkoutLng(),
                                widget.delivery_charges,
                                JebbyFee,
                                widget.security_deposit,
                                zipCode,
                                countryCode,
                                pickupWindowBegin: windows['pickupWindowBegin'],
                                pickupWindowEnd: windows['pickupWindowEnd'],
                                returnWindowBegin: windows['returnWindowBegin'],
                                returnWindowEnd: windows['returnWindowEnd'],
                                transportType: _transportType,
                              ),
                            );
                          } else {
                            String message = "Fields Cannot Be Empty";
                            if (!_hasRequiredLocation()) {
                              message = _usesDelivery
                                  ? ParsedUsAddress.selectFromSuggestionsMessage
                                  : "Pickup location is unavailable for this listing";
                            }
                            showAppErrorSnackbar(message, title: 'Required');
                          }
                        }
                      },
                      child: Container(
                        width: res_width * 0.9,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Color(0xffFEB038),
                        ),
                        child: Center(
                          child: Text(
                            "Order Now",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                  ],
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }



}
