import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jebby/constants/color.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:jebby/views/screens/vendors/my_products.dart';
import 'package:jebby/views/screens/vendors/listing_success.dart';
import 'package:jebby/views/screens/vendors/vendor_home.dart';
import 'package:jebby/views/widgets/address_autocomplete_field.dart';
import 'package:jebby/utils/google_places_address.dart';
import 'package:jebby/utils/show_snackbar.dart';
import 'package:jebby/repositories/api_repository.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/provider/sign_in_provider.dart';
import '../../../models/user_model.dart';
import 'package:dio/dio.dart' as d;
import 'package:provider/provider.dart';
import '../../../view_models/user_view_model.dart';
import 'package:jebby/services/analytics_service.dart';
import 'package:jebby/views/widgets/transport_options_section.dart';
import 'package:jebby/models/handoff_window.dart';
class AddProductScreen extends StatefulWidget {
  /// When true, step-1 back replaces the stack with [MyProductsScreen].
  final bool popToProductsOnBack;

  /// When true, step-1 back replaces the stack with [VendorHomeScreen].
  final bool popToHomeOnBack;

  const AddProductScreen({
    Key? key,
    this.popToProductsOnBack = false,
    this.popToHomeOnBack = false,
  }) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  static const int _totalSteps = 5;
  static const Color _primaryGold = Color(0xFFFBA104);
  static const Color _formAccentBlue = AppColors.darkBlue;

  String Url = dotenv.env['baseUrlM'] ?? 'No url found';
  bool addBtn = false;
  final ImagePicker imagePicker = ImagePicker();
  List<XFile> imageFileList = [];
  List imagesPath = [];
  bool isError = false;
  bool isLoading = true;
  bool sub_categoryLoader = true;
  bool sub_categoryError = false;
  late var sub_length;
  late var sub_name;
  late var sub_id;
  late var name_length;
  late var category_name;
  late var category_id;
  late String dropdownValue = "Select";
  String sub_dropdownvalue = "Sub Category";
  List<String> sub_items = [];
  List sub_items_id = [];
  List<String> items = [];
  List items_id = [];
  late var selected_id;
  late var selected_sub_id;
  bool subCategoryVisibility = false;

  final TextEditingController productController = TextEditingController();
  final TextEditingController specsController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController rentPriceController = TextEditingController();
  final TextEditingController SecurityDepositeController =
      TextEditingController();
  final TextEditingController deliveryChargesController =
      TextEditingController();
  final TextEditingController _deliveryRadiusController = TextEditingController();

  List<dynamic> image_document = [];

  int _currentStep = 1;
  late final PageController _pageController;

  bool _offersPickup = true;
  bool _offersDelivery = false;
  List<HandoffWindow> _handoffWindows = [];
  int _activeImageIndex = 0;

  String pasd = DateFormat('yyyy-MM-dd').format(DateTime.now());
  String paed = DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime.now().add(const Duration(days: 7)));
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isSelectingEnd = false;

  final TextEditingController _locationController = TextEditingController();
  ParsedUsAddress? _resolvedLocation;
  String? locationLat;
  String? locationLng;

  void _clearResolvedLocation() {
    setState(() {
      _resolvedLocation = const ParsedUsAddress();
      locationLat = null;
      locationLng = null;
    });
  }

  Future<void> _applySelectedLocation(ParsedUsAddress address) async {
    setState(() {
      _resolvedLocation = address;
      _locationController.text = address.displayLine;
      if (address.hasCoordinates) {
        locationLat = address.latitude!.toString();
        locationLng = address.longitude!.toString();
      } else {
        locationLat = null;
        locationLng = null;
      }
    });
  }

  InputDecoration get _listingLocationDecoration => InputDecoration(
        hintText: 'Enter address',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _formAccentBlue, width: 1.5),
        ),
      );

  String materialValue = "Wooden";
  String conditionValue = "New";
  String finishValue = "Simple Finish";
  String styleValue = "Minimal";
  String yearMadeValue = "2025";

  final List<String> _materialOptions = ["Wooden", "Plastic", "Metal", "Other"];
  final List<String> _conditionOptions = ["New", "Used", "Refurbished"];
  final List<String> _finishOptions = ["Simple Finish", "Glossy", "Matte"];
  final List<String> _styleOptions = ["Minimal", "Classic", "Modern"];
  final List<String> _yearOptions = [
    "2018",
    "2019",
    "2020",
    "2021",
    "2022",
    "2023",
    "2024",
    "2025",
  ];

  String? token;
  String? id;
  String? fullname;
  String? email;
  String? role;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _syncSpecsFromDropdowns();
    setState(() {
      isLoading = true;
      getCategory();
    });
    getData();
    profileData(context);
    AnalyticsService.instance.track('listing_started');
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeResumeDraft());
  }

  void _syncSpecsFromDropdowns() {
    specsController.text =
        "Material: $materialValue, Condition: $conditionValue, Finish: $finishValue, Style: $styleValue, Year Made: $yearMadeValue";
  }

  final DateFormat _rangeTitleFormat = DateFormat('MMM d');

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _availabilityStart() =>
      DateTime.tryParse(pasd) ?? DateTime.now();
  DateTime _availabilityEnd() =>
      DateTime.tryParse(paed) ?? DateTime.now();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isWithinSelectedRange(DateTime day) {
    final dayOnly = _dateOnly(day);
    final start = _dateOnly(_availabilityStart());
    final end = _dateOnly(_availabilityEnd());
    return !dayOnly.isBefore(start) && !dayOnly.isAfter(end);
  }

  DateTime _lastAllowedDate() {
    final now = DateTime.now();
    return DateTime(now.year + 5, now.month, now.day);
  }

  void _selectAvailabilityDay(DateTime day) {
    final today = _dateOnly(DateTime.now());
    final last = _dateOnly(_lastAllowedDate());
    if (day.isBefore(today) || day.isAfter(last)) return;

    final start = _availabilityStart();
    setState(() {
      if (!_isSelectingEnd) {
        pasd = DateFormat('yyyy-MM-dd').format(day);
        paed = DateFormat('yyyy-MM-dd').format(day);
        _isSelectingEnd = true;
        return;
      }
      if (day.isBefore(_dateOnly(start))) {
        pasd = DateFormat('yyyy-MM-dd').format(day);
        paed = DateFormat('yyyy-MM-dd').format(day);
      } else {
        paed = DateFormat('yyyy-MM-dd').format(day);
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

  Future getData() async {
    final sp = context.read<SignInProvider>();
    final usp = context.read<UserViewModel>();
    usp.getUser();
    sp.getDataFromSharedPreferences();
  }

  Future<UserModel> getUserDate() => UserViewModel().getUser();

  void profileData(BuildContext context) async {
    getUserDate().then((value) async {
      token = value.token.toString();
      id = value.id.toString();
      fullname = value.name.toString();
      email = value.email.toString();
      role = value.role.toString();
    }).onError((error, stackTrace) {
      if (kDebugMode) {}
    });
  }

  getSubCategory(catId) {
    ApiRepository.shared.getSubCategoryList(
      (list) => {
        if (mounted)
          {
            if (list.status == 0)
              {sub_items.add("No Category Found")}
            else
              {
                sub_items = [],
                sub_items_id = [],
                sub_length = ApiRepository.shared.subCategoryList?.data?.length,
                for (int i = 0; i < sub_length!; i++)
                  {
                    sub_name =
                        ApiRepository.shared.subCategoryList?.data?[i].name,
                    sub_id = ApiRepository.shared.subCategoryList?.data?[i].id,
                    sub_items.add(sub_name),
                    sub_items_id.add(sub_id),
                  },
                selected_sub_id = sub_items_id[0],
                setState(() {
                  sub_dropdownvalue = sub_items.first;
                  sub_categoryLoader = false;
                  sub_categoryError = false;
                  subCategoryVisibility = true;
                }),
              },
          },
      },
      (error) => {
        if (error != null)
          {
            setState(() {
              sub_categoryError = true;
            }),
          },
      },
      catId.toString(),
    );
  }

  getCategory() {
    ApiRepository.shared.getCategoryList(
      (List) => {
        if (mounted)
          {
            if (List.status == 0)
              {
                name_length = ApiRepository.shared.categoryList?.data?.length,
                for (int i = 0; i <= name_length; i++)
                  {
                    category_name =
                        ApiRepository.shared.categoryList?.data?[i].name,
                    category_id =
                        ApiRepository.shared.categoryList?.data?[i].id,
                    items.add(category_name.toString()),
                    items_id.add(category_id),
                  },
                selected_id = items_id[0],
                setState(() {
                  dropdownValue = items.first;
                  isLoading = false;
                  isError = true;
                }),
              }
            else
              {
                name_length = ApiRepository.shared.categoryList?.data?.length,
                for (int i = 0; i < name_length; i++)
                  {
                    category_name =
                        ApiRepository.shared.categoryList?.data?[i].name,
                    category_id =
                        ApiRepository.shared.categoryList?.data?[i].id,
                    items.add(category_name.toString()),
                    items_id.add(category_id),
                  },
                selected_id = items_id[0],
                setState(() {
                  dropdownValue = items.first;
                  isLoading = false;
                }),
                getSubCategory(selected_id),
              },
          },
      },
      (error) => {
        if (mounted)
          {
            if (error != null)
              {
                setState(() {
                  isLoading = false;
                  isError = true;
                }),
              },
          },
      },
    );
    ApiRepository.shared.checkApiStatus(true, "categoryList");
  }

  void addOneImage() async {
    try {
      const int maxImages = 4;
      if (imageFileList.length >= maxImages) return;
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image == null) return;
      final tempImage = File(image.path);
      final fileSize = await tempImage.length();
      if (fileSize > 7 * 1024 * 1024) {
        _showFileSizeAlert(
          'Selected file is larger than 7MB. Please select a smaller file.',
        );
        return;
      }
      setState(() {
        imagesPath.add(tempImage);
        imageFileList.add(image);
        _activeImageIndex = imageFileList.length - 1;
      });
    } catch (_) {}
  }

  void replaceFirstImage() async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image == null) return;
      final tempImage = File(image.path);
      final fileSize = await tempImage.length();
      if (fileSize > 7 * 1024 * 1024) {
        _showFileSizeAlert(
          'Selected file is larger than 7MB. Please select a smaller file.',
        );
        return;
      }
      setState(() {
        if (imageFileList.isEmpty || imagesPath.isEmpty) {
          imagesPath = [tempImage];
          imageFileList = [image];
          _activeImageIndex = 0;
        } else {
          final idx = _activeImageIndex.clamp(0, imageFileList.length - 1);
          imagesPath[idx] = tempImage;
          imageFileList[idx] = image;
        }
      });
    } catch (_) {}
  }

  bool _savingDraft = false;

  // --- Draft persistence (local only) ---

  Future<void> _saveDraft({
    bool showToast = false,
    bool exitAfterSave = false,
  }) async {
    if (_savingDraft) return;
    _savingDraft = true;
    var leavingScreen = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('listing_draft_active', true);
      await prefs.setString('listing_draft_product', productController.text);
    await prefs.setString(
      'listing_draft_description',
      descriptionController.text,
    );
    await prefs.setString('listing_draft_rent', rentPriceController.text);
    await prefs.setString(
      'listing_draft_security',
      SecurityDepositeController.text,
    );
    await prefs.setString(
      'listing_draft_delivery',
      deliveryChargesController.text,
    );
    await prefs.setString('listing_draft_category', dropdownValue);
    await prefs.setString('listing_draft_subcategory', sub_dropdownvalue);
    await prefs.setString('listing_draft_pasd', pasd);
    await prefs.setString('listing_draft_paed', paed);
    await prefs.setString('listing_draft_location', _locationController.text);
    await prefs.setString('listing_draft_lat', locationLat ?? '');
    await prefs.setString('listing_draft_lng', locationLng ?? '');
    await prefs.setString('listing_draft_material', materialValue);
    await prefs.setString('listing_draft_condition', conditionValue);
    await prefs.setString(
      'listing_draft_handoff_windows',
      jsonEncode(_handoffWindows.map((w) => w.toJson()).toList()),
    );
    await prefs.setBool('listing_draft_offers_pickup', _offersPickup);
    await prefs.setBool('listing_draft_offers_delivery', _offersDelivery);
    await prefs.setString('listing_draft_delivery_radius', _deliveryRadiusController.text);
    await prefs.setString('listing_draft_finish', finishValue);
    await prefs.setString('listing_draft_style', styleValue);
    await prefs.setString('listing_draft_year', yearMadeValue);
    await prefs.setInt('listing_draft_step', _currentStep);
      await prefs.setStringList(
        'listing_draft_images',
        imageFileList.map((f) => f.path).toList(),
      );

      if (exitAfterSave) {
        leavingScreen = true;
        Get.back();
        if (showToast) {
          Future.microtask(() {
            showAppSnackbar(
              'Draft saved',
              'Your listing progress was saved on this device.',
            );
          });
        }
        return;
      }

      if (showToast && mounted) {
        showAppSnackbar(
          'Draft saved',
          'Your listing progress was saved on this device.',
        );
      }
    } finally {
      if (!leavingScreen && mounted) {
        setState(() => _savingDraft = false);
      } else if (!leavingScreen) {
        _savingDraft = false;
      }
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('listing_draft_active');
    await prefs.remove('listing_draft_product');
    await prefs.remove('listing_draft_description');
    await prefs.remove('listing_draft_rent');
    await prefs.remove('listing_draft_security');
    await prefs.remove('listing_draft_delivery');
    await prefs.remove('listing_draft_category');
    await prefs.remove('listing_draft_subcategory');
    await prefs.remove('listing_draft_pasd');
    await prefs.remove('listing_draft_paed');
    await prefs.remove('listing_draft_group');
    await prefs.remove('listing_draft_fulfillment_pickup');
    await prefs.remove('listing_draft_fulfillment_delivery');
    await prefs.remove('listing_draft_offers_pickup');
    await prefs.remove('listing_draft_offers_delivery');
    await prefs.remove('listing_draft_delivery_radius');
    await prefs.remove('listing_draft_handoff_windows');
    await prefs.remove('listing_draft_location');
    await prefs.remove('listing_draft_lat');
    await prefs.remove('listing_draft_lng');
    await prefs.remove('listing_draft_material');
    await prefs.remove('listing_draft_condition');
    await prefs.remove('listing_draft_finish');
    await prefs.remove('listing_draft_style');
    await prefs.remove('listing_draft_year');
    await prefs.remove('listing_draft_step');
    await prefs.remove('listing_draft_images');
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('listing_draft_active') != true) return;

    productController.text = prefs.getString('listing_draft_product') ?? '';
    descriptionController.text =
        prefs.getString('listing_draft_description') ?? '';
    rentPriceController.text = prefs.getString('listing_draft_rent') ?? '';
    SecurityDepositeController.text =
        prefs.getString('listing_draft_security') ?? '';
    deliveryChargesController.text =
        prefs.getString('listing_draft_delivery') ?? '';
    dropdownValue = prefs.getString('listing_draft_category') ?? dropdownValue;
    sub_dropdownvalue =
        prefs.getString('listing_draft_subcategory') ?? sub_dropdownvalue;
    pasd = prefs.getString('listing_draft_pasd') ?? pasd;
    paed = prefs.getString('listing_draft_paed') ?? paed;
    _offersPickup = prefs.getBool('listing_draft_offers_pickup') ?? true;
    _offersDelivery = prefs.getBool('listing_draft_offers_delivery') ?? false;
    _deliveryRadiusController.text =
        prefs.getString('listing_draft_delivery_radius') ?? '';
    final windowsJson = prefs.getString('listing_draft_handoff_windows');
    if (windowsJson != null && windowsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(windowsJson) as List<dynamic>;
        _handoffWindows = decoded
            .map(
              (entry) => HandoffWindow.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList();
      } catch (_) {
        _handoffWindows = [];
      }
    } else {
      _handoffWindows = [];
    }
    _locationController.text = prefs.getString('listing_draft_location') ?? '';
    final lat = prefs.getString('listing_draft_lat');
    final lng = prefs.getString('listing_draft_lng');
    locationLat = lat != null && lat.isNotEmpty ? lat : null;
    locationLng = lng != null && lng.isNotEmpty ? lng : null;
    if (_locationController.text.isNotEmpty) {
      _resolvedLocation = ParsedUsAddress(
        formattedAddress: _locationController.text,
        latitude: double.tryParse(locationLat ?? ''),
        longitude: double.tryParse(locationLng ?? ''),
      );
    }
    materialValue = prefs.getString('listing_draft_material') ?? materialValue;
    conditionValue = prefs.getString('listing_draft_condition') ?? conditionValue;
    finishValue = prefs.getString('listing_draft_finish') ?? finishValue;
    styleValue = prefs.getString('listing_draft_style') ?? styleValue;
    yearMadeValue = prefs.getString('listing_draft_year') ?? yearMadeValue;
    _syncSpecsFromDropdowns();

    final paths = prefs.getStringList('listing_draft_images') ?? [];
    imageFileList = [];
    imagesPath = [];
    for (final path in paths) {
      if (File(path).existsSync()) {
        final file = XFile(path);
        imageFileList.add(file);
        imagesPath.add(File(path));
      }
    }
    if (imageFileList.isNotEmpty) _activeImageIndex = 0;

    if (items.contains(dropdownValue)) {
      selected_id = items_id[items.indexOf(dropdownValue)];
      getSubCategory(selected_id);
    }

    final step = prefs.getInt('listing_draft_step') ?? 1;
    if (mounted) {
      setState(() {});
      _goToStep(step.clamp(1, _totalSteps));
    }
  }

  Future<void> _maybeResumeDraft() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('listing_draft_active') != true) return;
    if (!mounted) return;

    final resume = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resume draft?',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1B1F),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You have an unfinished listing saved on this device. Would you like to continue where you left off?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF72747A),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'Start fresh',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF72747A),
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _primaryGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Resume',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (resume == true) {
      await _loadDraft();
    } else {
      await _clearDraft();
    }
  }

  // --- Validation & navigation ---

  void _showError(String message) =>
      showAppErrorSnackbar(message, title: 'Required');

  void _showFileSizeAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'File Size Exceeded',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(fontWeight: FontWeight.w400),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  bool _validateStep1() {
    if (imageFileList.isEmpty) {
      _showError('Please add at least one photo');
      return false;
    }
    if (productController.text.trim().isEmpty) {
      _showError('Please enter a product title');
      return false;
    }
    return true;
  }

  bool _isValidIntPrice(String value, {required bool required}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return !required;
    final parsed = int.tryParse(trimmed);
    return parsed != null && parsed >= 0;
  }

  bool _validateStep2() {
    if (!_isValidIntPrice(rentPriceController.text, required: true)) {
      _showError('Please enter a valid rent price');
      return false;
    }
    if (!_isValidIntPrice(SecurityDepositeController.text, required: true)) {
      _showError('Please enter a valid security deposit');
      return false;
    }
    if (deliveryChargesController.text.trim().isNotEmpty &&
        !_isValidIntPrice(deliveryChargesController.text, required: false)) {
      _showError('Please enter a valid delivery fee');
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    if (selected_id == null || dropdownValue == 'Select') {
      _showError('Please select a category');
      return false;
    }
    if (!subCategoryVisibility || selected_sub_id == null) {
      _showError('Please select a subcategory');
      return false;
    }
    if (_availabilityEnd().isBefore(_availabilityStart())) {
      _showError('End date must be on or after start date');
      return false;
    }
    if (_locationController.text.trim().isEmpty ||
        _resolvedLocation?.hasResolvedMapLocation != true) {
      _showError(ParsedUsAddress.selectFromSuggestionsMessage);
      return false;
    }
    if (!_offersPickup && !_offersDelivery) {
      _showError('Enable pickup and/or delivery');
      return false;
    }
    if (_offersDelivery) {
      final radius = int.tryParse(_deliveryRadiusController.text.trim());
      if (radius == null || radius <= 0) {
        _showError('Please enter a delivery radius (miles)');
        return false;
      }
    }
    if (_handoffWindows.isEmpty) {
      _showError('Please add at least one handoff window');
      return false;
    }
    return true;
  }

  bool _validateStep4() {
    _syncSpecsFromDropdowns();
    if (specsController.text.trim().isEmpty) {
      _showError('Please complete product specifications');
      return false;
    }
    return true;
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleBack() {
    if (_currentStep > 1) {
      _goToStep(_currentStep - 1);
    } else if (widget.popToHomeOnBack) {
      Get.offAll(() => VendorHomeScreen());
    } else if (widget.popToProductsOnBack) {
      Get.offAll(() => MyProductsScreen(side: false));
    } else if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    } else {
      Get.offAll(() => MyProductsScreen(side: false));
    }
  }

  Future<void> _handleContinue() async {
    if (_currentStep == 1 && !_validateStep1()) return;
    if (_currentStep == 2 && !_validateStep2()) return;
    if (_currentStep == 3 && !_validateStep3()) return;
    if (_currentStep == 4 && !_validateStep4()) return;

    await _saveDraft();

    if (_currentStep < _totalSteps) {
      AnalyticsService.instance.track(
        'listing_step_completed',
        props: {'step': _currentStep},
      );
      _goToStep(_currentStep + 1);
    }
  }

  addProduct() async {
    if (!_validateStep1() ||
        !_validateStep2() ||
        !_validateStep3() ||
        !_validateStep4()) {
      _showError('Please complete all required fields');
      return;
    }

    setState(() => addBtn = true);
    image_document = [];

    if (descriptionController.text.trim().isEmpty) {
      descriptionController.text = productController.text.trim();
    }

    try {
      for (int i = 0; i < imagesPath.length; i++) {
        final uniqueName = DateTime.now().millisecondsSinceEpoch.toString();
        image_document.add(
          await d.MultipartFile.fromFile(
            imageFileList[i].path,
            filename: uniqueName,
          ),
        );
      }

      final data = {
        "user_id": id.toString(),
        "category_id": selected_id.toString(),
        "subcategory_id": selected_sub_id.toString(),
        "name": productController.text.toString(),
        "price": rentPriceController.text.toString(),
        "delivery_charges":
            deliveryChargesController.text.toString().isEmpty
                ? "0"
                : deliveryChargesController.text.toString(),
        "specifications": specsController.text.toString(),
        "description": descriptionController.text.toString(),
        "offers_pickup": _offersPickup ? 1 : 0,
        "offers_delivery": _offersDelivery ? 1 : 0,
        "delivery_radius_miles": _deliveryRadiusController.text.trim().isEmpty
            ? null
            : _deliveryRadiusController.text.trim(),
        "handoff_windows": jsonEncode(_handoffWindows.map((w) => w.toJson()).toList()),
        "available_from": pasd,
        "available_to": paed,
        "address": _locationController.text.trim(),
        "latitude": locationLat ?? "",
        "longitude": locationLng ?? "",
        "security_deposit": SecurityDepositeController.text.toString(),
        "file": image_document,
      };

      final formData = d.FormData.fromMap(data);
      final response = await ApiRepository.shared.insertProductMultipart(formData);

      if (response.toString() == 'Your files uploaded.') {
        await _clearDraft();
        AnalyticsService.instance.track('listing_published');
        if (mounted) {
          setState(() => addBtn = false);
          Get.off(() => const ListingSuccessScreen());
        }
      } else {
        if (mounted) {
          setState(() => addBtn = false);
          showAppErrorSnackbar(response.toString());
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => addBtn = false);
        showAppErrorSnackbar('Failed to publish listing');
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _locationController.dispose();
    productController.dispose();
    specsController.dispose();
    descriptionController.dispose();
    rentPriceController.dispose();
    SecurityDepositeController.dispose();
    deliveryChargesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: InkWell(
          onTap: _handleBack,
          borderRadius: BorderRadius.circular(50),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
        ),
        title: Text(
          'Create Your Listing',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildStepHeader(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1PhotosDetails(),
                _buildStep2Pricing(),
                _buildStep3CategoryAvailability(),
                _buildStep4Specifications(),
                _buildStep5Review(),
              ],
            ),
          ),
          if (_currentStep < _totalSteps) _buildContinueBar(),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    const labels = [
      'Photos',
      'Pricing',
      'Category',
      'Specs',
      'Review',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Text(
            'Step $_currentStep of $_totalSteps',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int index = 0; index < _totalSteps; index++) ...[
                Expanded(
                  flex: 3,
                  child: _buildStepHeaderItem(
                    stepNum: index + 1,
                    label: labels[index],
                    isActive: index + 1 == _currentStep,
                    isComplete: index + 1 < _currentStep,
                  ),
                ),
                if (index < _totalSteps - 1)
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Container(
                        height: 2,
                        color:
                            index + 1 < _currentStep
                                ? _primaryGold
                                : Colors.grey.shade300,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeaderItem({
    required int stepNum,
    required String label,
    required bool isActive,
    required bool isComplete,
  }) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color:
                isActive || isComplete ? _primaryGold : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$stepNum',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color:
                  isActive || isComplete ? Colors.white : Colors.black54,
            ),
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? Colors.black87 : Colors.black45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _handleContinue,
            style: FilledButton.styleFrom(
              backgroundColor: _primaryGold,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIntro(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep1PhotosDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIntro(
            'Add photos & basic details',
            'Show renters what makes your item great.',
          ),
          GestureDetector(
            onTap: addOneImage,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child:
                  imageFileList.isEmpty
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 40,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add Photos',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      )
                      : Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(imageFileList[_activeImageIndex].path),
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: GestureDetector(
                              onTap: replaceFirstImage,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Replace',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
            ),
          ),
          if (imageFileList.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount:
                    imageFileList.length < 4
                        ? imageFileList.length + 1
                        : imageFileList.length,
                itemBuilder: (context, index) {
                  if (index == imageFileList.length) {
                    return GestureDetector(
                      onTap: addOneImage,
                      child: Container(
                        width: 72,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.add, color: Colors.grey.shade500),
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () => setState(() => _activeImageIndex = index),
                    child: Container(
                      width: 72,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _activeImageIndex == index
                                  ? _primaryGold
                                  : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(imageFileList[index].path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
          _fieldLabel('Product Title'),
          const SizedBox(height: 8),
          _textField(
            controller: productController,
            hint: 'e.g. Wooden Chair',
            maxLength: 80,
          ),
          const SizedBox(height: 16),
          _fieldLabel('Description'),
          const SizedBox(height: 8),
          _textField(
            controller: descriptionController,
            hint: 'Describe your item...',
            maxLines: 4,
            maxLength: 250,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Pricing() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIntro(
            'Set your pricing',
            'Set a fair price and help renters know the total upfront.',
          ),
          _fieldLabel('Rent Price (per day)'),
          const SizedBox(height: 8),
          _textField(
            controller: rentPriceController,
            hint: '0',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.attach_money,
          ),
          const SizedBox(height: 16),
          _fieldLabel('Security Deposit'),
          const SizedBox(height: 4),
          Text(
            'Refundable after the rental.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.black45),
          ),
          const SizedBox(height: 8),
          _textField(
            controller: SecurityDepositeController,
            hint: '0',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.lock_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3CategoryAvailability() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIntro(
            'Add category & availability',
            'Help renters find your item and know when it\'s available.',
          ),
          _fieldLabel('Category'),
          const SizedBox(height: 8),
          _dropdownField<String>(
            value: dropdownValue,
            isLoading: isLoading,
            items: items,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                dropdownValue = value;
                selected_id = items_id[items.indexOf(dropdownValue)];
                sub_categoryLoader = true;
                subCategoryVisibility = false;
                sub_items = [];
                getSubCategory(selected_id);
              });
            },
          ),
          const SizedBox(height: 16),
          _fieldLabel('Subcategory'),
          const SizedBox(height: 8),
          _dropdownField<String>(
            value: sub_dropdownvalue,
            isLoading: sub_categoryLoader,
            loadingText: 'Select a category first',
            items: sub_items,
            onChanged:
                subCategoryVisibility
                    ? (value) {
                      if (value == null) return;
                      setState(() {
                        sub_dropdownvalue = value;
                        selected_sub_id =
                            sub_items_id[sub_items.indexOf(sub_dropdownvalue)];
                      });
                    }
                    : null,
          ),
          const SizedBox(height: 16),
          TransportOptionsSection(
            pickupEnabled: _offersPickup,
            deliveryEnabled: _offersDelivery,
            deliveryFeeController: deliveryChargesController,
            radiusController: _deliveryRadiusController,
            windows: _handoffWindows,
            onPickupChanged: (value) => setState(() {
              _offersPickup = value;
              if (!value && !_offersDelivery) _offersDelivery = true;
            }),
            onDeliveryChanged: (value) => setState(() {
              _offersDelivery = value;
              if (!value && !_offersPickup) _offersPickup = true;
            }),
            onWindowsChanged: (windows) => setState(() => _handoffWindows = windows),
          ),
          const SizedBox(height: 16),
          _fieldLabel('Listing location'),
          const SizedBox(height: 4),
          Text(
            'Where renters can pick up this item, or where you deliver from.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          AddressAutocompleteField(
            controller: _locationController,
            resolvedAddress: _resolvedLocation,
            onEditingStarted: _clearResolvedLocation,
            onAddressSelected: _applySelectedLocation,
            hint: 'Enter address',
            decoration: _listingLocationDecoration,
          ),
          const SizedBox(height: 16),
          _buildAvailabilityCalendar(),
        ],
      ),
    );
  }

  Widget _buildStep4Specifications() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIntro(
            'Product specifications',
            'Help renters understand the details of your item.',
          ),
          _specDropdown("Material", materialValue, _materialOptions, (v) {
            setState(() {
              materialValue = v!;
              _syncSpecsFromDropdowns();
            });
          }),
          const SizedBox(height: 12),
          _specDropdown("Condition", conditionValue, _conditionOptions, (v) {
            setState(() {
              conditionValue = v!;
              _syncSpecsFromDropdowns();
            });
          }),
          const SizedBox(height: 12),
          _specDropdown("Finish", finishValue, _finishOptions, (v) {
            setState(() {
              finishValue = v!;
              _syncSpecsFromDropdowns();
            });
          }),
          const SizedBox(height: 12),
          _specDropdown("Style", styleValue, _styleOptions, (v) {
            setState(() {
              styleValue = v!;
              _syncSpecsFromDropdowns();
            });
          }),
          const SizedBox(height: 12),
          _specDropdown("Year Made", yearMadeValue, _yearOptions, (v) {
            setState(() {
              yearMadeValue = v!;
              _syncSpecsFromDropdowns();
            });
          }),
        ],
      ),
    );
  }

  Widget _buildStep5Review() {
    final transportParts = <String>[];
    if (_offersPickup) transportParts.add('Pickup & Return');
    if (_offersDelivery) transportParts.add('Delivery & Retrieval');
    final deliveryLabel = transportParts.join(' · ');
    final handoffWindowsLabel = _handoffWindows.isEmpty
        ? 'None added'
        : _handoffWindows.map((window) => window.displayRange).join(', ');
    final dateRange =
        '${DateFormat('MMM d, yyyy').format(_availabilityStart())} – ${DateFormat('MMM d, yyyy').format(_availabilityEnd())}';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIntro(
            'Review & publish',
            'Almost there! Review your details before listing.',
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                if (imageFileList.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(imageFileList.first.path),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade200,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productController.text.isEmpty
                            ? 'Untitled'
                            : productController.text,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$dropdownValue · $sub_dropdownvalue',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _goToStep(1),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.inter(
                      color: _primaryGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _reviewSection('Pricing', [
            _reviewRow(
              'Rent Price',
              '\$${rentPriceController.text.isEmpty ? '0' : rentPriceController.text}/day',
            ),
            _reviewRow(
              'Security Deposit',
              '\$${SecurityDepositeController.text.isEmpty ? '0' : SecurityDepositeController.text}',
            ),
          ]),
          const SizedBox(height: 12),
          _reviewSection('Availability', [
            _reviewRow('Dates', dateRange),
          ]),
          const SizedBox(height: 12),
          _reviewSection('Specifications', [
            _reviewRow('Material', materialValue),
            _reviewRow('Condition', conditionValue),
            _reviewRow('Finish', finishValue),
            _reviewRow('Style', styleValue),
            _reviewRow('Year Made', yearMadeValue),
          ]),
          const SizedBox(height: 12),
          _reviewSection('Transport', [
            _reviewRow('Options', deliveryLabel),
            if (_offersDelivery) ...[
              _reviewRow(
                'Delivery fee',
                '\$${deliveryChargesController.text.isEmpty ? '0' : deliveryChargesController.text}',
              ),
              _reviewRow(
                'Delivery radius',
                _deliveryRadiusController.text.trim().isEmpty
                    ? '—'
                    : '${_deliveryRadiusController.text.trim()} mi',
              ),
            ],
            if (_offersPickup || _offersDelivery)
              _reviewRow('Handoff windows', handoffWindowsLabel),
            if (_locationController.text.trim().isNotEmpty)
              _reviewRow('Listing location', _locationController.text.trim()),
          ]),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: addBtn ? null : addProduct,
              style: FilledButton.styleFrom(
                backgroundColor: _primaryGold,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child:
                  addBtn
                      ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : Text(
                        'Publish Listing',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed:
                  _savingDraft
                      ? null
                      : () async {
                        await _saveDraft(
                          showToast: true,
                          exitAfterSave: true,
                        );
                      },
              child: Text(
                _savingDraft ? 'Saving...' : 'Save as Draft',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    IconData? prefixIcon,
    ValueChanged<String>? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.sentences,
  }) {
    final isNumericField =
        keyboardType == TextInputType.number ||
        keyboardType == const TextInputType.numberWithOptions(decimal: true);

    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      inputFormatters:
          isNumericField ? [FilteringTextInputFormatter.digitsOnly] : null,
      textCapitalization:
          isNumericField ? TextCapitalization.none : textCapitalization,
      autocorrect: !isNumericField,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        counterText: maxLength != null ? null : '',
        filled: true,
        fillColor: Colors.white,
        prefixIcon:
            prefixIcon != null ? Icon(prefixIcon, color: _formAccentBlue, size: 20) : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryGold),
        ),
      ),
      style: GoogleFonts.inter(fontSize: 15),
    );
  }

  Widget _dropdownField<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?>? onChanged,
    bool isLoading = false,
    String loadingText = 'Loading...',
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child:
          isLoading
              ? Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loadingText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8F9098),
                  ),
                ),
              )
              : DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: items.contains(value) ? value : items.firstOrNull,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: onChanged == null
                        ? const Color(0xFFBDBEC6)
                        : const Color(0xFF8F9098),
                  ),
                  onChanged: onChanged,
                  style: GoogleFonts.inter(
                    color: onChanged == null
                        ? const Color(0xFF8F9098)
                        : const Color(0xFF1B1B1F),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  items:
                      items
                          .map(
                            (v) => DropdownMenuItem<T>(
                              value: v,
                              child: Text(
                                v.toString(),
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF1B1B1F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
    );
  }

  Widget _specDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF8F9098),
              ),
              items:
                  options
                      .map(
                        (v) => DropdownMenuItem<String>(
                          value: v,
                          child: Text(
                            v,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1B1B1F),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: onChanged,
              style: GoogleFonts.inter(
                color: const Color(0xFF1B1B1F),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityCalendar() {
    final today = _dateOnly(DateTime.now());
    final lastAllowed = _lastAllowedDate();
    final start = _dateOnly(_availabilityStart());
    final end = _dateOnly(_availabilityEnd());
    final isSingleDaySelection = _isSameDay(start, end);
    final monthFirst = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final int leadingEmpty = monthFirst.weekday % 7;
    final int daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rental Period',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: const Color(0xFF1B1B1F),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: Color(0xFF0A143D),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_rangeTitleFormat.format(start)} - ${_rangeTitleFormat.format(end)}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0A143D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _monthButton(
                        Icons.chevron_left,
                        () => _shiftCalendarMonth(-1),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            DateFormat('MMMM yyyy').format(_calendarMonth),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      _monthButton(
                        Icons.chevron_right,
                        () => _shiftCalendarMonth(1),
                      ),
                    ],
                  ),
                  Row(
                    children:
                        const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                            .map(
                              (d) => Expanded(
                                child: Center(
                                  child: Text(
                                    d,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Color(0xFF59689A),
                                    ),
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 0,
                          childAspectRatio: 1.3,
                        ),
                    itemBuilder: (context, index) {
                      if (index < leadingEmpty) {
                        return const SizedBox.shrink();
                      }
                      final dayNum = index - leadingEmpty + 1;
                      final day = DateTime(
                        _calendarMonth.year,
                        _calendarMonth.month,
                        dayNum,
                      );
                      final disabled =
                          day.isBefore(today) || day.isAfter(lastAllowed);
                      final isStart = _isSameDay(day, start);
                      final isEnd = _isSameDay(day, end);
                      final inRange = _isWithinSelectedRange(day);
                      final row = index ~/ 7;

                      bool hasLeftInRange = false;
                      if (index > 0 && (index - 1) ~/ 7 == row) {
                        final prev = dayNum - 1;
                        if (prev >= 1) {
                          final prevDay = DateTime(
                            _calendarMonth.year,
                            _calendarMonth.month,
                            prev,
                          );
                          final prevDisabled =
                              prevDay.isBefore(today) ||
                              prevDay.isAfter(lastAllowed);
                          hasLeftInRange =
                              !prevDisabled && _isWithinSelectedRange(prevDay);
                        }
                      }

                      bool hasRightInRange = false;
                      if ((index + 1) ~/ 7 == row) {
                        final next = dayNum + 1;
                        if (next <= daysInMonth) {
                          final nextDay = DateTime(
                            _calendarMonth.year,
                            _calendarMonth.month,
                            next,
                          );
                          final nextDisabled =
                              nextDay.isBefore(today) ||
                              nextDay.isAfter(lastAllowed);
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
                            bottomLeft:
                                Radius.circular(hasLeftInRange ? 0 : 10),
                            topRight: Radius.circular(hasRightInRange ? 0 : 10),
                            bottomRight:
                                Radius.circular(hasRightInRange ? 0 : 10),
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
                        onTap:
                            disabled ? null : () => _selectAvailabilityDay(day),
                        child: Container(
                          decoration: rangeDeco,
                          alignment: dayAlignment,
                          child: Container(
                            width: dayExtent,
                            height: dayExtent,
                            decoration: dayDeco,
                            alignment: Alignment.center,
                            child: Text(
                              '$dayNum',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight:
                                    (isStart || isEnd)
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isSelectingEnd
                        ? 'Select an end date'
                        : 'Select a start date to adjust your range',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF72747A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'From: ${DateFormat('MM/dd/yyyy').format(_availabilityStart())}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF72747A),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'To: ${DateFormat('MM/dd/yyyy').format(_availabilityEnd())}',
                    textAlign: TextAlign.end,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF72747A),
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

  Widget _monthButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 22, color: const Color(0xFF0A143D)),
        ),
      ),
    );
  }

  Widget _reviewSection(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
