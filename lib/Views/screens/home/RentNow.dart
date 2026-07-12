import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/Services/provider/sign_in_provider.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:jebby/Views/screens/home/Checkout.dart';
import 'package:jebby/Views/screens/profile/userprofile.dart';
import 'package:jebby/view_model/getTax_modal.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../model/user_model.dart';
import '../../../res/app_url.dart';
import '../../../view_model/apiServices.dart';
import 'package:http/http.dart' as http;

import '../../../view_model/user_view_model.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';

class RentnowScreen extends StatefulWidget {
  final String vendorName;
  final String vendorAddress;
  final String cell;
  final String vendorImage;
  final dynamic vendorID;
  final dynamic productID;
  final dynamic pastart;
  final dynamic paend;
  final dynamic price;
  final dynamic vendorAccountId;
  final dynamic vendorPayPalEmail;
  final dynamic route;
  final dynamic delivery_charges;
  final dynamic security_deposit;

  RentnowScreen(
    this.vendorName,
    this.vendorAddress,
    this.cell,
    this.vendorImage,
    this.vendorID,
    this.productID,
    this.pastart,
    this.paend,
    this.price,
    this.vendorAccountId,
    this.vendorPayPalEmail,
    this.route,
    this.delivery_charges,
    this.security_deposit,
  );

  @override
  State<RentnowScreen> createState() => _RentnowScreenState();
}

class _RentnowScreenState extends State<RentnowScreen> {
  static const Color _accent = Color(0xFFF6AE02);
  static const Color _starInactive = Color(0xFFC6C8CF);
  static const Color _pageBg = Color(0xFFF3F3F5);
  // static const Color _labelGrey = Color(0xFF72747A);
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
  var Latitiude = "";
  var Longitude = "";
  var uuid = new Uuid();
  var vuid = new Uuid();
  List<dynamic> _placeList1 = [];
  String _sessionToken = '1234567890';

  var myFormat = DateFormat('dd, MMM/yyyy');
  var myFormat1 = DateFormat('dd, MMM/yyyy');
  var myPillFormat = DateFormat('MM/dd/yyyy');
  final DateFormat _rangeTitleFormat = DateFormat('MMM d');

  _onChanged() {
    getSuggestion(_locationController.text);
  }

  _onChanged2() {
    getSuggestion1(_CurrentAddressController.text);
  }

  void getSuggestion(String input) async {
    String kPLACES_API_KEY =
        dotenv.env['kPLACES_API_KEY'] ?? 'No secret key found';

    try {
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String request =
          '$baseURL?input=$input&key=$kPLACES_API_KEY&sessiontoken=$_sessionToken';
      var response = await http.get(Uri.parse(request));
      // log('mydata');
      // log(response.body.toString());
      if (response.statusCode == 200) {
        setState(() {});
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      // toastMessage('success');
    }
  }

  void getSuggestion1(String input) async {
    String kPLACES_API_KEY =
        dotenv.env['kPLACES_API_KEY'] ?? 'No secret key found';

    try {
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String request =
          '$baseURL?input=$input&key=$kPLACES_API_KEY&sessiontoken=$_sessionToken';
      var response = await http.get(Uri.parse(request));
      // log('mydata');
      // log(response.body.toString());
      if (response.statusCode == 200) {
        setState(() {
          _placeList1 = json.decode(response.body)['predictions'];
        });
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      // toastMessage('success');
    }
  }

  String? zipCode;
  String? countryCode;
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
      final data = await GetJebbyfee.fetchData();
      setState(() {
        _data = data;
        array = _data['data'];
      });
      JebbyFee = array.length > 0 ? array[0]['jebby_fees'] : 0;
    } catch (e) {}
  }

  void pre() async {
    SharedPreferences Prefrences = await SharedPreferences.getInstance();

    _CurrentAddressController.text =
        Prefrences.getString('address').toString() == "null"
            ? ""
            : Prefrences.getString('address').toString();
    _locationController.text =
        Prefrences.getString('address').toString() == "null"
            ? ""
            : Prefrences.getString('address').toString();
    nameController.text = Prefrences.getString('fullname').toString();
    emailController.text = Prefrences.getString('email').toString();
    Longitude = Prefrences.getString('longitude').toString();
    Latitiude = Prefrences.getString('latitude').toString();
    _getZipCodeFromCoordinates(
      double.parse(Latitiude),
      double.parse(Longitude),
    );
  }

  void initState() {
    _loadData();
    getData();
    profileData(context);
    selectedDate =
        DateTime.now(); //DateTime.parse(widget.pastart).isBefore(DateTime.now()) ? DateTime.now() : DateTime.parse(widget.pastart);
    selectedDate1 = DateTime.now().add(
      Duration(days: 1),
    ); //DateTime.parse(widget.paend);
    pre();
    super.initState();
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
      if (raw.isEmpty || raw.toLowerCase() == 'null') continue;
      urls.add(raw.toLowerCase().startsWith('http') ? raw : AppUrl.baseUrlM + raw);
    }
    return urls;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _lastAllowedDate() {
    final parsed = DateTime.tryParse(widget.paend.toString());
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
                  final disabled = day.isBefore(today) || day.isAfter(lastAllowed);
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
                  if (disabled) {
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
                  if (!disabled && (isStart || isEnd)) {
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

  //  void dispose() {
  //   _locationController.dispose();
  //   super.dispose();
  // }

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
                                'assets/slicing/placeholder.png',
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
                                    'assets/slicing/placeholder.png',
                                    fit: BoxFit.cover,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Image.asset(
                                    'assets/slicing/placeholder.png',
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
                // Container(
                //   width: 391,
                //   height: 223,
                //   decoration:
                //       BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(width: 1, color: Colors.black.withOpacity(0.11))),
                //   child: Padding(
                //     padding: EdgeInsets.symmetric(horizontal: 20),
                //     child: Column(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: [
                //         Row(
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           crossAxisAlignment: CrossAxisAlignment.end,
                //           children: [
                //             Container(
                //               width: 90,
                //               height: 135,
                //               child: Image.asset(
                //                 "assets/slicing/Layer 4@3x.png",
                //                 fit: BoxFit.fill,
                //               ),
                //             ),
                //             Container(
                //               width: 128,
                //               height: 170,
                //               child: Image.asset(
                //                 "assets/slicing/Layer 4@3x.png",
                //                 fit: BoxFit.fill,
                //               ),
                //             ),
                //             Container(
                //               width: 90,
                //               height: 135,
                //               child: Image.asset(
                //                 "assets/slicing/Layer 4@3x.png",
                //                 fit: BoxFit.fill,
                //               ),
                //             ),
                //           ],
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                // SizedBox(
                //   height: 5,
                // ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ApiRepository.shared.getProductsByIdList!.data![0].name
                          .toString(),
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                const SizedBox(height: 12),
                Text(
                  (ApiRepository.shared.getProductsByIdList!.data![0].serviceAgreements ??
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
                // SizedBox(
                //   height: 15,
                // ),
                // Row(
                //   children: [
                //     // SizedBox(
                //     //   height: 10,
                //     // ),
                //     Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                //       Text(
                //         "Shipping Address",
                //         style: TextStyle(fontSize: 17, color: Colors.black),
                //       ),
                //       SizedBox(
                //         height: 5,
                //       ),
                //       Container(
                //         width: 365,
                //         height: 58,
                //         decoration: BoxDecoration(
                //           borderRadius: BorderRadius.circular(16),
                //           border: Border.all(
                //             width: 1,
                //             color: Color(0xffFEB038),
                //           ),
                //         ),
                //         child: TextFormField(
                //           controller: ShippingAddressController,
                //           style: TextStyle(
                //             fontSize: 17,
                //             color: Colors.black,
                //           ),
                //           keyboardType: TextInputType.text,
                //           decoration: InputDecoration(
                //             disabledBorder: InputBorder.none,
                //             errorBorder: InputBorder.none,
                //             border: InputBorder.none,
                //             contentPadding: EdgeInsets.only(left: 10, top: 5),
                //           ),
                //         ),
                //       ),
                //     ]),
                //   ],
                // ),
                // SizedBox(
                //   height: 3,
                // ),
                // TxtfldforLocation("Current Address", _CurrentAddressController),
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: res_height * 0.02),
                      Text(
                        'Current Address',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: _titleDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: res_height * 0.005),
                      Container(
                        // height: 70,
                        width: res_width * 0.89,
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _onChanged2();
                            });
                          },
                          maxLines: 1,
                          controller: _CurrentAddressController,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            // hintText:placholder,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFFE1E1E1),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(15),
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: const BorderSide(
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
                    ],
                  ),
                ),
                SizedBox(
                  // height: res_height * 0.05,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: ScrollPhysics(),
                    itemCount: _placeList1.length,
                    itemBuilder: ((context, index) {
                      String name = _placeList1[index]["description"];

                      if (_CurrentAddressController.text.isEmpty) {
                        return Text("");
                      } else if (name.toLowerCase().contains(
                        _CurrentAddressController.text.toLowerCase(),
                      )) {
                        return ListTile(
                          onTap: () async {
                            _locationController.text =
                                _placeList1[index]["description"];
                            _CurrentAddressController.text =
                                _placeList1[index]["description"];
                            List<Location> location = await locationFromAddress(
                              _placeList1[index]["description"],
                            );
                            setState(() {
                              // _CurrentAddressController.removeListener(() {});
                              Latitiude = location.last.latitude.toString();
                              Longitude = location.last.longitude.toString();
                              _getZipCodeFromCoordinates(
                                location.last.latitude,
                                location.last.longitude,
                              );
                              _placeList1 = [];
                            });
                          },
                          leading: CircleAvatar(
                            child: Icon(Icons.pin_drop, color: Colors.white),
                          ),
                          title: Text(_placeList1[index]["description"]),
                        );
                      } else {
                        return SizedBox.shrink();
                      }
                    }),
                  ),
                ),
                SizedBox(height: 5),
                // TxtfldforLocation("Shipping Address", _locationController),
                // SizedBox(
                //   // height: res_height * 0.05,
                // child:
                // ListView.builder(
                //     shrinkWrap: true,
                //     physics: ScrollPhysics(),
                //     itemCount: _placeList.length,
                //     itemBuilder: ((context, index) {
                //       String name = _placeList[index]["description"];

                //       if (_locationController.text.isEmpty) {
                //         return Text("");
                //       } else if (name.toLowerCase().contains(_locationController.text.toLowerCase())) {
                //         return ListTile(
                //           onTap: () async {
                //             _locationController.text = _placeList[index]["description"];
                //             List<Location> location = await locationFromAddress(_placeList[index]["description"]);
                //             setState(() {
                //               _locationController.removeListener(() {});
                //               Latitiude = location.last.latitude.toString();
                //               Longitude = location.last.longitude.toString();

                //               // Use geocoding to get the ZIP code
                //               _getZipCodeFromCoordinates(location.last.latitude, location.last.longitude);
                //               _placeList = [];
                //             });
                //           },
                //           leading: CircleAvatar(child: Icon(Icons.pin_drop, color: Colors.white)),
                //           title: Text(_placeList[index]["description"]),
                //         );
                //       } else {
                //         return SizedBox.shrink();
                //       }
                //     })),
                // ),
                SizedBox(height: 20),
                Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                SizedBox(height: 20),

                Column(
                  children: [
                    // Text(
                    //   "Owner Info",
                    //   style: TextStyle(fontSize: 24, color: Colors.black, fontFamily: "Inter, Bold"),
                    // ),
                    // SizedBox(
                    //   height: 10,
                    // ),
                    GestureDetector(
                      onTap: () {
                        Get.to(
                          () => RenterProfile(
                            vendorID: widget.vendorID,
                            vendorName: widget.vendorName,
                            vendorImage: widget.vendorImage,
                            vendorAddress: widget.vendorAddress,
                          ),
                        );
                      },
                      child: Row(
                        // mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(shape: BoxShape.circle),
                            child:
                                widget.vendorImage == ""
                                    ? const CircleAvatar(
                                        radius: 33,
                                        backgroundColor: Color(0xFFE6E6E6),
                                        child: Icon(
                                          Icons.person,
                                          color: Color(0xFF9E9E9E),
                                          size: 20,
                                        ),
                                      )
                                    : CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        AppUrl.baseUrlM +
                                            ApiRepository
                                                .shared
                                                .getUserCredentialModelList!
                                                .data![0]
                                                .image
                                                .toString(),
                                        // fit: BoxFit.contain,
                                      ),
                                    ),
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
                              // Text(
                              //   widget.vendorAddress == "" ? "" : widget.vendorAddress,
                              //   style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.53), fontFamily: "Inter, Light"),
                              // ),
                              // Text(
                              //   widget.cell == "" ? "" : widget.cell,
                              //   style: TextStyle(fontSize: 16, color: Colors.black, fontFamily: "Inter, Light"),
                              // )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // SizedBox(
                //   height: 30,
                // ),
                // Row(
                //   children: [
                //     GestureDetector(
                //       onTap: () {
                //         setState(() {
                //           onlinepay = false;
                //           // cod = false;
                //         });
                //       },
                //       child: Container(
                //         height: 19,
                //         width: 19,
                //         decoration: BoxDecoration(
                //             shape: BoxShape.circle, border: Border.all(color: onlinepay == false ? Color(0xff303030) : Colors.black, width: 3)),
                //         child: Icon(
                //           Icons.circle_rounded,
                //           color: onlinepay == false ? Color(0xff303030) : Colors.white,
                //           size: 13,
                //         ),
                //       ),
                //     ),
                //     SizedBox(
                //       width: 20,
                //     ),
                //     Text(
                //       "Online Payment",
                //       style: TextStyle(fontSize: 21, color: Colors.black, fontFamily: "Inter, Regular"),
                //     ),
                //     SizedBox(
                //       width: 20,
                //     ),
                //     // GestureDetector(
                //     //   onTap: () {
                //     //     setState(() {
                //     //       onlinepay = true;
                //     //       // cod = true;
                //     //     });
                //     //   },
                //     //   child: Container(
                //     //     height: 19,
                //     //     width: 19,
                //     //     decoration: BoxDecoration(
                //     //         shape: BoxShape.circle, border: Border.all(color: onlinepay == true ? Color(0xff303030) : Colors.black, width: 3)),
                //     //     child: Icon(
                //     //       Icons.circle_rounded,
                //     //       color: onlinepay == true ? Color(0xff303030) : Colors.white,
                //     //       size: 13,
                //     //     ),
                //     //   ),
                //     // ),
                //     // SizedBox(
                //     //   width: 20,
                //     // ),
                //     // Text(
                //     //   "COD",
                //     //   style: TextStyle(fontSize: 21, color: Colors.black, fontFamily: "Inter, Regular"),
                //     // ),
                //   ],
                // ),
                SizedBox(height: 20),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        DateTime normalizedSelectedDate = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                        );

                        int diff =
                            selectedDate1
                                .difference(normalizedSelectedDate)
                                .inDays +
                            1;
                        // int diff = selectedDate1.difference(selectedDate).inDays;
                        int amount = int.parse(widget.price.toString()) * diff;
                        //         .toString(),);
                        //         .format(selectedDate)
                        //         .toString(),)
                        if (onlinepay == true) {
                          if (DateTime.parse(selectedDate.toString())
                                  .difference(
                                    DateTime.parse(selectedDate1.toString()),
                                  )
                                  .inMilliseconds >=
                              0) {
                            final snackBar = new SnackBar(
                              content: new Text("Please Enter Valid End Date"),
                            );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(snackBar);
                            // Utils.flushBarErrorMessage(
                            //     'Please Enter Valid End Date', context);
                          } else if (emailController.text.isNotEmpty &&
                              _locationController.text.toString().isNotEmpty &&
                              nameController.text.isNotEmpty) {
                            final snackBar = new SnackBar(
                              content: new Text("Please Wait"),
                            );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(snackBar);
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
                              fullname,
                              emailController.text.toString(),
                              _locationController.text.toString(),
                              Latitiude,
                              Longitude,
                              widget.route == "simple" ? 0 : amount,
                              _CurrentAddressController.text.toString(),
                              Latitiude,
                              Longitude,
                            );
                          } else {
                            String message = "Fields Cannot Be Empty";
                            if (_locationController.text.toString().isEmpty) {
                              message = "Please enter location";
                            }
                            final snackBar = new SnackBar(
                              content: new Text(message),
                            );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(snackBar);
                          }
                        } else {
                          if (DateTime.parse(selectedDate.toString())
                                  .difference(
                                    DateTime.parse(selectedDate1.toString()),
                                  )
                                  .inMilliseconds >=
                              0) {
                            final snackBar = new SnackBar(
                              content: new Text("Please Enter Valid End Date"),
                            );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(snackBar);
                            // Utils.flushBarErrorMessage(
                            //     'Please Enter Valid End Date', context);
                          } else if (widget.vendorAccountId == "0" ||
                              widget.vendorAccountId == "" ||
                              widget.vendorAccountId == 0) {
                            final snackBar = new SnackBar(
                              content: new Text("Vendor account not found. Please ensure the vendor has completed Stripe onboarding."),
                            );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(snackBar);
                          } else if (emailController.text.isNotEmpty &&
                              _locationController.text.toString().isNotEmpty &&
                              nameController.text.isNotEmpty) {
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
                                widget.pastart,
                                widget.paend,
                                widget.price,
                                // amount,
                                widget.vendorAccountId,
                                widget.vendorPayPalEmail,
                                fullname,
                                emailController.text.toString(),
                                _locationController.text.toString(),
                                Latitiude,
                                Longitude,
                                widget.route == "simple" ? 0 : amount,
                                widget.delivery_charges,
                                JebbyFee,
                                widget.security_deposit,
                                zipCode,
                                countryCode,
                              ),
                            );
                          } else {
                            String message = "Fields Cannot Be Empty";
                            if (_locationController.text.toString().isEmpty) {
                              message = "Please enter location";
                            }
                            final snackBar = new SnackBar(
                              content: new Text(message),
                            );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(snackBar);
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

  // Future<void> initPaymentSheet() async {
  //     try {
  //       // 1. create payment intent on the server
  //       final data = await _createTestPaymentSheet();

  //       // 2. initialize the payment sheet
  //      await Stripe.instance.initPaymentSheet(
  //         paymentSheetParameters: SetupPaymentSheetParameters(
  //           // Enable custom flow
  //           customFlow: true,
  //           // Main params
  //           merchantDisplayName: 'Flutter Stripe Store Demo',
  //           paymentIntentClientSecret: data['paymentIntent'],
  //           // Customer keys
  //           customerEphemeralKeySecret: data['ephemeralKey'],
  //           customerId: data['customer'],
  //           // Extra options
  //           // testEnv: true,
  //           // applePay: true,
  //           // googlePay: true,
  //           // style: ThemeMode.dark,
  //           // merchantCountryCode: 'DE',
  //         ),
  //       );
  //       setState(() {
  //         _ready = true;
  //       });
  //     } catch (e) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error: $e')),
  //       );
  //       rethrow;
  //     }
  // }

  TxtfldforLocation(txt, _controller) {
    double res_width = MediaQuery.of(context).size.width;
    double res_height = MediaQuery.of(context).size.height;
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: res_height * 0.02),
          Text(txt, style: TextStyle(fontSize: 17, color: Colors.black)),
          SizedBox(height: res_height * 0.005),
          Container(
            // height: 70,
            width: res_width * 0.89,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _onChanged();
                });
              },
              maxLines: 1,
              controller: _locationController,
              decoration: InputDecoration(
                // hintText:placholder,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: const BorderSide(color: kprimaryColor, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: const BorderSide(color: kprimaryColor, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
