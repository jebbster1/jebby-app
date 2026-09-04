import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:jebby/services/provider/sign_in_provider.dart';
import 'package:jebby/views/screens/home/product_details.dart';
import 'package:jebby/views/screens/navigation/bottom_nav_controller.dart';
import 'package:jebby/views/screens/home/category.dart';
import 'package:http/http.dart' as http;
import '../../../models/get_featured_products_model.dart' as datamodel;

import 'package:jebby/views/screens/shared/notifications.dart';
import 'package:jebby/views/screens/navigation/app_drawer.dart';
import 'package:jebby/views/screens/profile/user_profile.dart';
import 'package:intl/intl.dart';
import 'package:jebby/views/screens/home/search_data.dart';
import 'package:jebby/services/analytics_service.dart';
import 'package:jebby/models/category_list_model.dart';
import 'package:jebby/models/sub_category_list_model.dart';
import 'package:jebby/constants/color.dart';
import 'package:jebby/repositories/api_repository.dart';
import 'package:jebby/view_models/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:jebby/views/widgets/rentals_coming_soon_banner.dart';
import 'package:jebby/views/widgets/reservation_action_card.dart';
import '../../../models/user_model.dart';
import '../../../constants/app_url.dart';

import '../../../view_models/user_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, num? activeIndex}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

TextEditingController searchController = TextEditingController();

class _HomeScreenState extends State<HomeScreen> {
  var fromdate;
  var todate;

  DateTime selectedDate = DateTime.now();
  DateTime selectedDate1 = DateTime.now();

  Future getData() async {
    final sp = context.read<SignInProvider>();
    final usp = context.read<UserViewModel>();
    usp.getUser();
    sp.getDataFromSharedPreferences();
  }

  Future<UserModel> getUserDate() => UserViewModel().getUser();

  String? token;
  String sourceId = "";
  String? fullname;
  String? email;
  String? role;
  String? address;

  String? _normalizeOptionalText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  void profileData(BuildContext context) async {
    getUserDate()
        .then((value) async {
          if (!mounted) return;
          setState(() {
            token = value.token?.toString();
            sourceId = value.id?.toString() ?? '';
            fullname = value.name?.toString();
            email = value.email?.toString();
            role = value.role?.toString();
            address = _normalizeOptionalText(value.address);
          });
        })
        .onError((error, stackTrace) {
          if (kDebugMode) {}
        });
  }

  bool isLoading = true;
  bool isError = false;
  bool isEmpty = false;

  getFeaturedProducts() {
    ApiRepository.shared.featuredProducts(
      (List) {
        if (this.mounted) {
          if (List.data!.length == 0) {
            setState(() {
              isLoading = false;
              isError = false;
              isEmpty = true;
            });
          } else {
            setState(() {
              isLoading = false;
              isError = false;
              isEmpty = false;
            });
            unawaited(_primeCategorySubcategoryNames(List.data!));
            unawaited(_primeFeaturedLocations(List.data!));
          }
        }
      },
      (error) {
        setState(() {
          isLoading = true;
          isError = false;
          isEmpty = true;
        });
      },
    );
  }

  bool isLoading1 = true;
  bool isError1 = false;
  bool isEmpty1 = false;

  getNotifications() {
    ApiRepository.shared.notifications(
      sourceId,
      (List) {
        if (this.mounted) {
          if (List.data!.length == 0) {
            setState(() {
              isEmpty1 = true;
              isLoading1 = false;
              isError1 = false;
            });
          } else {
            setState(() {
              isEmpty1 = false;
              isLoading1 = false;
              isError1 = false;
            });
          }
        }
      },
      (error) {
        if (error != null) {
          setState(() {
            isEmpty1 = false;
            isLoading1 = true;
            isError1 = true;
          });
        }
      },
    );
  }

  seenNotification() {
    ApiRepository.shared.seenNotification(sourceId);
  }

  void check() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('time') == false) {
      cancelTimer();
      return;
    }

    cancelTimer();
    notiTimer().timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (token == null ||
          token == "" ||
          role == "" ||
          role == null ||
          prefs.getBool('time') != true) {
        cancelTimer();
      } else {
        prefs.getBool('notifiction') == true
            ? getNotifications()
            : prefs.getBool('notifiction') == null
            ? getNotifications()
            : null;
      }
    });
  }

  cancelTimer() {
    notiTimer().cancelTimer();
  }

  void dispose() {
    super.dispose();

    // timer.cancel();
  }

  void func() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setBool("time", true);
    if (role != "Guest") {
      check();
    }
  }

  @override
  void initState() {
    super.initState();
    getFeaturedProducts();
    getData();
    profileData(context);
    func();
  }

  var myFormat = DateFormat('MM/dd/yyyy');

  double starss = 0.0;
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  /// Cached so the category future is not recreated on every build (avoids repeated loading).
  /// Lazy init so it works after hot reload (initState may not run again).
  late Future<CategoryList> _categoryListFuture =
      ApiRepository.shared.fetchCategoryList();

  final Map<String, Future<SubCategoryList>> _subcategoryFutures = {};
  final Map<String, String> _categoryNameMap = {};
  final Map<String, String> _subcategoryNameMap = {};
  final Map<String, String> _productLocationTextById = {};

  Future<SubCategoryList> _getSubcategoryFuture(String categoryId) {
    return _subcategoryFutures.putIfAbsent(
      categoryId,
      () => ApiRepository.shared.fetchSubCategoryList(categoryId),
    );
  }

  String _categorySubcategoryLabel(dynamic categoryId, dynamic subcategoryId) {
    final categoryKey = categoryId?.toString() ?? '';
    final subcategoryKey = subcategoryId?.toString() ?? '';
    final categoryName = _categoryNameMap[categoryKey] ?? categoryKey;
    final subcategoryName =
        _subcategoryNameMap['$categoryKey-$subcategoryKey'] ?? subcategoryKey;

    if (categoryName.isEmpty && subcategoryName.isEmpty) {
      return 'Category - Sub Category';
    }
    return '$categoryName - $subcategoryName';
  }

  String _formatLocationText(dynamic address, dynamic latitude, dynamic longitude) {
    final rawAddress = address?.toString().trim() ?? '';
    final lat = double.tryParse(latitude?.toString() ?? '');
    final lng = double.tryParse(longitude?.toString() ?? '');

    final coordRegex = RegExp(r'^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$');
    final looksLikeCoords = rawAddress.isNotEmpty && coordRegex.hasMatch(rawAddress);

    if (rawAddress.isNotEmpty && !looksLikeCoords) {
      return rawAddress;
    }

    if (lat != null && lng != null) {
      return 'Lat ${lat.toStringAsFixed(4)}, Lng ${lng.toStringAsFixed(4)}';
    }

    if (looksLikeCoords) {
      return rawAddress;
    }

    return 'Location unavailable';
  }

  String _resolveProductLocation(datamodel.Data item) {
    final productId = item.id?.toString() ?? '';
    if (productId.isNotEmpty && _productLocationTextById.containsKey(productId)) {
      return _productLocationTextById[productId]!;
    }
    return _formatLocationText(item.address, item.latitude, item.longitude);
  }

  Future<void> _primeCategorySubcategoryNames(
    List<datamodel.Data> featuredItems,
  ) async {
    try {
      final categoryList = await _categoryListFuture;
      for (final category in categoryList.data ?? <dynamic>[]) {
        final id = category.id?.toString();
        final name = category.name?.toString() ?? '';
        if (id != null && id.isNotEmpty && name.isNotEmpty) {
          _categoryNameMap[id] = name;
        }
      }

      final categoryIds =
          featuredItems
              .map((e) => e.categoryId?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toSet();

      for (final categoryId in categoryIds) {
        final subCategoryList = await _getSubcategoryFuture(categoryId);
        for (final subCategory in subCategoryList.data ?? <dynamic>[]) {
          final subId = subCategory.id?.toString();
          final subName = subCategory.name?.toString() ?? '';
          if (subId != null && subId.isNotEmpty && subName.isNotEmpty) {
            _subcategoryNameMap['$categoryId-$subId'] = subName;
          }
        }
      }

      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _primeFeaturedLocations(List<datamodel.Data> featuredItems) async {
    try {
      for (final item in featuredItems) {
        final productId = item.id?.toString() ?? '';
        if (productId.isEmpty || _productLocationTextById.containsKey(productId)) {
          continue;
        }

        final initial = _formatLocationText(item.address, item.latitude, item.longitude);
        if (initial != 'Location unavailable') {
          _productLocationTextById[productId] = initial;
          continue;
        }

        final detail = await ApiRepository.shared.getProductsById((_) {}, (_) {}, productId);
        final detailItem =
            (detail.data != null && detail.data!.isNotEmpty) ? detail.data!.first : null;
        if (detailItem == null) continue;

        final detailText = _formatLocationText(
          detailItem.address,
          detailItem.latitude?.toString(),
          detailItem.longitude?.toString(),
        );
        if (detailText != 'Location unavailable') {
          _productLocationTextById[productId] = detailText;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthViewModel>();
    double res_width = MediaQuery.of(context).size.width;
    double res_height = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      child: Scaffold(
        key: _key,
        drawer: Consumer<UserViewModel>(
          builder: (context, usp, _) => AppDrawerScreen(
            key: ValueKey('drawer-guest-${usp.isGuestUser}-${usp.role}'),
          ),
        ),

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(220),
          child: Builder(
            builder: (context) {
              final top = MediaQuery.of(context).padding.top;
              const radius = 26.0;

              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: Material(
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      // Orange curved header
                      Container(
                        height: 220,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(radius),
                            bottomRight: Radius.circular(radius),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(16, top + 12, 16, 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RoundIconButton(
                              onTap: () {
                                _key.currentState!.openDrawer();
                              },
                              bg: Colors.transparent,
                              image: const AssetImage(
                                'assets/images/mingcute_menu-fill.png',
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullname ?? 'Welcome to Jebby',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      height: address != null ? 1.1 : 1.8,
                                    ),
                                  ),
                                  if (address != null) ...[
                                    SizedBox(height: 6),
                                    Text(
                                      address!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            Row(
                              children: [
                                Visibility(
                                  visible: role != null && role != "Guest",
                                  child: _CircleAction(
                                    onTap: () {
                                      seenNotification();
                                      Get.to(() => NotificationsScreen());
                                    },
                                    image: const AssetImage(
                                      'assets/images/notificationnew.png',
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),
                                Visibility(
                                  visible: role != null && role != "Guest",
                                  child: _CircleAction(
                                    onTap: () {
                                      Get.to(() => UserProfileScreen());
                                    },
                                    image: const AssetImage(
                                      'assets/images/personnew.png',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ✅ Search bar floating at bottom
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 26,
                        child: _SearchField(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        backgroundColor: const Color(0xFFF5F5F5),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: res_height * 0.02),
                RentalsComingSoonBanner(),
                ReservationActionCard(),
                SizedBox(height: res_height * 0.02),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        child: Text(
                          'Featured Items',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      //   width: 120,
                      // ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                isLoading
                    ? Text("")
                    : isEmpty
                    ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("No items available currently"),
                )
                    : SizedBox(
                  height: res_height * 0.31,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    itemCount:
                        ApiRepository
                            .shared
                            .getFeaturedProductsModelList!
                            .data!
                            .length,
                    itemBuilder: (context, int index) {
                      var data =
                          ApiRepository
                              .shared
                              .getFeaturedProductsModelList!
                              .data![index];
                      var price = data.price;
                      var reviews = (data.length ?? '0').toString();
                      var name = data.name.toString();
                      var id = data.id.toString();
                      var specs = data.specifications.toString();
                      var desc = data.description.toString();
                      var userId = data.userId.toString();
                      var image = data.image.toString();
                      var stars = data.stars.toString();
                      var delivery_charges = data.delivery_charges.toString();
                      return SizedBox(
                        width: res_width * 0.92,
                        child: itmBox(
                          img: image,
                          dx: price,
                          rv: '(${reviews} Reveiws)',
                          tx: '$name',
                          categoryText: _categorySubcategoryLabel(
                            data.categoryId,
                            data.subcategoryId,
                          ),
                          locationText: _resolveProductLocation(data),
                          rt: stars,
                          id: id,
                          specs: specs,
                          userId: userId,
                          desc: desc,
                          delivery_charges: delivery_charges,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: res_height * 0.01),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Text(
                          'Discover',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          )
                        ),
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Get.find<BottomNavController>().navBarChange(2);
                        },
                        child: Container(
                          child: Text(
                            "See All",
                            style: TextStyle(
                              color: AppColors.darkBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: res_height * 0.01),
                FutureBuilder<CategoryList>(
                  future: _categoryListFuture,
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<CategoryList> snapshot,
                  ) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'Could not load categories',
                                style: TextStyle(color: Colors.grey),
                              ),
                              SizedBox(height: 4),
                              Text(
                                snapshot.error.toString().replaceFirst('Exception: ', ''),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
                      );
                    }
                    final list = snapshot.data!.data;
                    if (list == null || list.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No categories available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    return Container(
                      width: res_width,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(6),
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.2,
                        ),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final categoryId = item.id.toString();
                          return FutureBuilder<SubCategoryList>(
                            future: _getSubcategoryFuture(categoryId),
                            builder: (context, subSnapshot) {
                              final count = subSnapshot.hasData &&
                                      subSnapshot.data!.data != null
                                  ? subSnapshot.data!.data!.length
                                  : null;
                              return contBox(
                                txt: item.name,
                                img: '${AppUrl.baseUrlM}${item.image}',
                                id: categoryId,
                                subcategoryCount: count,
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
                SizedBox(height: res_height * 0.13),
              ],
            ),
          ),
        ),
      ),
    );
  }

  contBox({txt, img, id, int? subcategoryCount}) {
    double res_width = MediaQuery.of(context).size.width;
    double borderRadius = 20;
    double scrimStrength = 0.05;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AnalyticsService.instance.track(
            'category_viewed',
            props: {
              'category_id': id,
              'source': 'home',
            },
          );
          Get.to(
            () => CategoryScreen(categoryname: txt, id: id, pictureurl: img),
          );
        },
        child: SizedBox(
          width: res_width * 0.45,
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: '$img',
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Center(
                      child: CircularProgressIndicator(color: AppColors.primaryColor), // Loading spinner
                    ),
                errorWidget:
                    (context, url, error) => Icon(
                      Icons.error,
                      color: Colors.red,
                    ), // Display an error icon
              ),

              // Universal darken layer (ensures white text works on any image)
              Container(color: Colors.black.withOpacity(scrimStrength)),

              // Extra bottom gradient for stronger contrast near text
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black54,
                      Colors.black87,
                    ],
                    stops: [0.3, 0.7, 1.0],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$txt",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            height: 1.1,
                            letterSpacing: -0.2,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black54),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subcategoryCount != null
                          ? (subcategoryCount == 1
                              ? '1 Subcategory'
                              : '$subcategoryCount Subcategories')
                          : '...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        shadows: const [
                          Shadow(blurRadius: 3, color: Colors.black45),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  itmBox({
    img,
    tx,
    categoryText,
    locationText,
    dx,
    rt,
    rv,
    id,
    specs,
    userId,
    desc,
    delivery_charges,
  }) {
    double res_height = MediaQuery.of(context).size.height;
    final ratingValue = double.tryParse(rt?.toString() ?? '') ?? 0;
    final showRatingBadge = ratingValue > 0;

    return GestureDetector(
      onTap: () {
        Get.to(
          routeName: "PD",
          () => ProductDetailScreen(
            id,
            tx,
            int.parse(dx.toString()),
            rt,
            img,
            specs,
            userId,
            desc,
            delivery_charges,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 5, bottom: 0, left: 5, right: 5),
        child: Column(
          children: [
            Container(
              height: res_height * 0.27,
              width: double.infinity,
              decoration: BoxDecoration(),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(25)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: id == "1" ? img : AppUrl.baseUrlM + img,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder:
                            (context, url) => const Center(
                              child: CircularProgressIndicator(color: AppColors.primaryColor),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.grey.shade300,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.white70,
                              ),
                            ),
                      ),
                    ),

                    // Dark gradient overlay (bottom)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Rating badge (top-left) — only when the listing has reviews
                    if (showRatingBadge)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Color(0xFFF6AE02), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                rt.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Price badge (top-right)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A623),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "\$${dx.toString()} per day",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Bottom text content
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${(categoryText != null && categoryText.toString().trim().isNotEmpty) ? categoryText : 'Category - Sub Category'}",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "$tx",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: res_height * 0.001),
          ],
        ),
      ),
    );
  }

  Future<CategoryList> getCategoryList() async {
    dynamic response = await http.get(Uri.parse(AppUrl.categoryGetUrl));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return CategoryList.fromJson(data);
    } else {
      throw Exception("Error");
    }
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.onTap,
    required this.image,
  });

  final VoidCallback onTap;
  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 36,
          width: 36,
          child: Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: Image(
                image: image,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.onTap,
    this.bg = Colors.white,
    required this.image,
  });

  final VoidCallback onTap;
  final Color bg;
  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.transparent, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 36,
          width: 36,
          child: Center(
            child: Image(
              image: image,
              height: 22,
              width: 22,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(28),
      child: TextField(
        controller: searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search by Product Name',

          prefixIcon: InkWell(
            onTap: () {
              if (searchController.text.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => SearchDataScreen(word: searchController.text),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(
                'assets/images/searchnew.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
              ),
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
