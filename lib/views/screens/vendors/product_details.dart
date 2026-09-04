import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jebby/views/screens/agreements/insurance_and_indemnifications.dart';
import 'package:jebby/views/screens/agreements/rental_agreement.dart';
import 'package:jebby/views/screens/agreements/terms_and_conditions.dart';
import 'package:jebby/views/screens/agreements/transport_and_installation_policy.dart';
import 'package:jebby/views/screens/vendors/edit_product.dart';
import 'package:jebby/views/screens/vendors/my_products.dart';
import 'package:jebby/views/screens/shared/reviews.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/constants/app_url.dart';
import 'package:jebby/constants/color.dart';
import 'package:jebby/utils/overlay_support.dart';
import 'package:jebby/utils/show_snackbar.dart';
import '../../../models/get_reviews_by_product_id_model.dart' as review_model;

import 'package:jebby/repositories/api_repository.dart';

class VendorProductDetailScreen extends StatefulWidget {
  final dynamic id;

  VendorProductDetailScreen({this.id});

  @override
  State<VendorProductDetailScreen> createState() => _VendorProductDetailScreenState();
}

class _VendorProductDetailScreenState extends State<VendorProductDetailScreen> {
  static const Color _accent = Color(0xFFF6AE02);
  static const Color _pageBg = Color(0xFFF3F3F5);
  static const Color _labelGrey = Color(0xFF72747A);
  static const Color _bodyGrey = Color(0xFF6D6D75);
  static const Color _titleDark = Color(0xFF1B1B1F);

  /// Inactive star tint — same as `MyProducts` `productCard` (My products).
  static const Color _starInactive = Color(0xFFC6C8CF);

  final PageController _pageController = PageController();
  int _carouselIndex = 0;

  String dropdownValue = 'One';
  bool isLoading = true;
  bool isError = false;
  bool emptyProdData = false;
  late var prodID;
  List imagesList = [];
  List imagesListID = [];
  var categoryID = null;
  var subCategoryID = null;
  var name = null;
  var price = null;
  var specifications = null;
  var description = null;
  var product_id = null;
  var images = null;
  var imageID = null;
  bool editVisibility = false;
  var length = "";
  var stars = "";
  var delivery_charges = null;
  int _reviewTotalFromApi = -1;
  Map<int, double> _ratingDistribution = const {
    5: 0.0,
    4: 0.0,
    3: 0.0,
    2: 0.0,
    1: 0.0,
  };

  @override
  void initState() {
    super.initState();
    getProducts(widget.id.toString());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDeleteProduct() async {
    final listingName = name?.toString().trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete listing?',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _titleDark,
            ),
          ),
          content: Text(
            listingName != null && listingName.isNotEmpty
                ? 'Are you sure you want to delete "$listingName"? This cannot be undone.'
                : 'Are you sure you want to delete this listing? This cannot be undone.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _bodyGrey,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: _labelGrey,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    Loader.show();
    try {
      final error = await ApiRepository.shared.deleteProductsById(prodID);
      if (!mounted) return;
      if (error == null) {
        Get.offAll(() => MyProductsScreen(side: false));
      } else {
        showAppErrorSnackbar(error);
      }
    } finally {
      Loader.hide();
    }
  }

  void getProducts(id) {
    setState(() {
      isLoading = true;
      isError = false;
      emptyProdData = false;
      imagesList = [];
      imagesListID = [];
    });

    ApiRepository.shared.getProductsById(
      (list) => {
        if (this.mounted)
          {
            if (list.data!.length == 0)
              {
                setState(() {
                  isLoading = false;
                  isError = false;
                  prodID =
                      ApiRepository
                          .shared
                          .getProductsByIdList
                          ?.data![0]
                          .productId
                          .toString();
                }),
              }
            else
              {
                setState(() {
                  isLoading = false;
                  isError = false;
                  prodID =
                      ApiRepository
                          .shared
                          .getProductsByIdList
                          ?.data![0]
                          .productId
                          .toString();
                }),
                for (
                  int i = 0;
                  i <
                      ApiRepository
                          .shared
                          .getProductsByIdList!
                          .data![1]
                          .images!
                          .length;
                  i++
                )
                  {
                    imagesList.add(
                      ApiRepository
                          .shared
                          .getProductsByIdList
                          ?.data?[1]
                          .images?[i]
                          .path,
                    ),
                    imagesListID.add(
                      ApiRepository
                          .shared
                          .getProductsByIdList
                          ?.data?[1]
                          .images?[i]
                          .id,
                    ),
                  },
                categoryID =
                    ApiRepository
                        .shared
                        .getProductsByIdList
                        ?.data![0]
                        .categoryId,
                subCategoryID =
                    ApiRepository
                        .shared
                        .getProductsByIdList
                        ?.data![0]
                        .subcategoryId,
                name = ApiRepository.shared.getProductsByIdList?.data![0].name,
                price =
                    ApiRepository.shared.getProductsByIdList!.data![0].price
                        .toString(),
                specifications =
                    ApiRepository
                        .shared
                        .getProductsByIdList
                        ?.data![0]
                        .specifications,
                description =
                    ApiRepository
                        .shared
                        .getProductsByIdList
                        ?.data![0]
                        .description,
                product_id =
                    ApiRepository
                        .shared
                        .getProductsByIdList
                        ?.data![0]
                        .productId,
                length =
                    ApiRepository.shared.getProductsByIdList!.data![0].length
                        .toString(),
                stars =
                    ApiRepository.shared.getProductsByIdList!.data![0].stars
                        .toString(),
                delivery_charges =
                    ApiRepository
                        .shared
                        .getProductsByIdList!
                        .data![0]
                        .delivery_charges
                        .toString(),
                _loadRatingDistribution(widget.id.toString()),
                images = imagesList,
                imageID = imagesListID,
                setState(() {
                  editVisibility = true;
                }),
              },
          },
      },
      (error) => {
        if (error != null)
          {
            setState(() {
              isLoading = false;
              isError = true;
            }),
          },
      },
      id,
    );
  }

  double get _avgRating => double.tryParse(stars.toString())?.clamp(0, 5) ?? 0;

  int get _reviewCount =>
      _reviewTotalFromApi >= 0
          ? _reviewTotalFromApi
          : (int.tryParse(length.toString()) ?? 0);

  String _normalizedSpecificationsRaw() {
    final raw = specifications?.toString().trim() ?? '';
    if (raw.isEmpty) return '';
    return raw;
  }

  List<MapEntry<String, String>> _parseSpecificationsString(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const [];

    final commaSeparated = RegExp(r'(?:^|, )([^:]+):\s*(.*?)(?=, [^:]+:|$)');
    final commaMatches = commaSeparated.allMatches(text).toList();
    if (commaMatches.isNotEmpty) {
      return commaMatches
          .map((match) {
            final key = match.group(1)?.trim() ?? '';
            final value = match.group(2)?.trim() ?? '';
            if (key.isEmpty) return null;
            return MapEntry(key, value);
          })
          .whereType<MapEntry<String, String>>()
          .toList();
    }

    final out = <MapEntry<String, String>>[];
    for (final line in text.split(RegExp(r'\r?\n'))) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final idx = t.indexOf(':');
      if (idx > 0) {
        out.add(
          MapEntry(t.substring(0, idx).trim(), t.substring(idx + 1).trim()),
        );
      }
    }
    return out;
  }

  List<MapEntry<String, String>> _parsedSpecs() =>
      _parseSpecificationsString(_normalizedSpecificationsRaw());

  void _loadRatingDistribution(String productId) {
    ApiRepository.shared.reviewsByProductId(productId, (
      review_model.GetAllReviewsByProductId list,
    ) {
      final data = list.data ?? const <review_model.Data>[];
      final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final r in data) {
        final s = r.stars ?? 0;
        if (s >= 1 && s <= 5) counts[s] = counts[s]! + 1;
      }
      final distribution = data.isEmpty
          ? const {5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0}
          : {
              5: counts[5]! / data.length,
              4: counts[4]! / data.length,
              3: counts[3]! / data.length,
              2: counts[2]! / data.length,
              1: counts[1]! / data.length,
            };
      if (!mounted) return;
      setState(() {
        _reviewTotalFromApi = list.totalreviews ?? data.length;
        _ratingDistribution = distribution;
      });
    }, (_) {});
  }

  /// Same as `MyProducts.productCard`: `Icons.star` / `Icons.star_border`,
  /// `_accent` / `_starInactive`, rounded fill count.
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
            color: active ? _accent : _starInactive,
            size: size,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final specs = _parsedSpecs();
    final carouselCount = imagesList.isEmpty ? 1 : imagesList.length;

    return Scaffold(
      backgroundColor: _pageBg,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
              : isError
              ? Center(
                child: Text(
                  'Error Loading Product',
                  style: GoogleFonts.inter(),
                ),
              )
              : Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildImageHeader(height, carouselCount),
                      ),
                      SliverToBoxAdapter(
                        child: Transform.translate(
                          offset: const Offset(0, -22),
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                40,
                                20,
                                120,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name.toString(),
                                          style: GoogleFonts.inter(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: _titleDark,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                      _myProductsStyleStars(
                                        _avgRating,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Rental Price',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: _labelGrey,
                                        ),
                                      ),
                                      Text(
                                        '\$$price',
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: _accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    description.toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      color: _bodyGrey,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Product Specifications',
                                    style: GoogleFonts.inter(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: _titleDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (specs.isEmpty)
                                    Text(
                                      'No specifications listed.',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                        color: _bodyGrey,
                                      ),
                                    )
                                  else
                                    ...specs.map(
                                      (e) => _specDividerRow(e.key, e.value),
                                    ),
                                  const SizedBox(height: 8),
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent,
                                    ),
                                    child: ExpansionTile(
                                      tilePadding: EdgeInsets.zero,
                                      initiallyExpanded: false,
                                      title: Text(
                                        'Service Agreements',
                                        style: GoogleFonts.inter(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: _titleDark,
                                        ),
                                      ),
                                      iconColor: _titleDark,
                                      collapsedIconColor: _titleDark,
                                      children: [
                                        _agreementRow(
                                          'Rental Agreement',
                                          () => Get.to(() => RentalAgreementScreen()),
                                        ),
                                        _agreementRow(
                                          'Terms & Conditions',
                                          () =>
                                              Get.to(() => TermsAndConditionsScreen()),
                                        ),
                                        _agreementRow(
                                          'Insurance & Indemnifications Policy',
                                          () => Get.to(
                                            () => InsuranceAndIndemnificationsScreen(),
                                          ),
                                        ),
                                        _agreementRow(
                                          'Transportation & Installation Policy',
                                          () => Get.to(
                                            () =>
                                                TransportAndInstallationPolicyScreen(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      dividerColor: Colors.transparent,
                                    ),
                                    child: ExpansionTile(
                                      tilePadding: EdgeInsets.zero,
                                      initiallyExpanded: true,
                                      controlAffinity:
                                          ListTileControlAffinity.trailing,
                                      title: Text(
                                        'Ratings & Reviews',
                                        style: GoogleFonts.inter(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: _titleDark,
                                        ),
                                      ),
                                      iconColor: _titleDark,
                                      collapsedIconColor: _titleDark,
                                      children: [
                                        const SizedBox(height: 4),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.fromLTRB(
                                            0,
                                            8,
                                            0,
                                            8,
                                          ),
                                          color: Colors.white,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    width: 108,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          _avgRating.toStringAsFixed(
                                                            _avgRating ==
                                                                    _avgRating
                                                                        .roundToDouble()
                                                                ? 0
                                                                : 2,
                                                          ),
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 40,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color:
                                                                    _titleDark,
                                                                height: 1,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Text(
                                                          '$_reviewCount Reviews',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w400,
                                                                color:
                                                                    _labelGrey,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        _myProductsStyleStars(
                                                          _avgRating,
                                                          size: 16,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      children: List.generate(5, (
                                                        i,
                                                      ) {
                                                        final star = 5 - i;
                                                        final w =
                                                            (_ratingDistribution[star] ??
                                                                    0.0)
                                                                .clamp(0.0, 1.0);
                                                        final pct =
                                                            (w * 100).round();
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                bottom: 8,
                                                              ),
                                                          child: Row(
                                                            children: [
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Text(
                                                                    '$star',
                                                                    style: GoogleFonts.inter(
                                                                      fontSize:
                                                                          13,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color:
                                                                          _titleDark,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 4,
                                                                  ),
                                                                  Icon(
                                                                    Icons
                                                                        .star_rounded,
                                                                    size: 14,
                                                                    color:
                                                                        _accent,
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Expanded(
                                                                child: ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        999,
                                                                      ),
                                                                  child: LinearProgressIndicator(
                                                                    value: w,
                                                                    minHeight:
                                                                        8,
                                                                    backgroundColor:
                                                                        Colors
                                                                            .grey
                                                                            .shade200,
                                                                    valueColor:
                                                                        const AlwaysStoppedAnimation<
                                                                          Color
                                                                        >(
                                                                          _accent,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              SizedBox(
                                                                width: 38,
                                                                child: Text(
                                                                  '$pct%',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .right,
                                                                  style: GoogleFonts.inter(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                    color:
                                                                        _labelGrey,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: TextButton(
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: _accent,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 28,
                                                          vertical: 12,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            28,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    if (prodID != null &&
                                                        stars
                                                            .toString()
                                                            .isNotEmpty) {
                                                      Get.to(
                                                        () => ReviewsScreen(
                                                          stars: stars,
                                                          reviewsLenght:
                                                              length.toString(),
                                                          prodID: prodID,
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: Text(
                                                    'Read More',
                                                    style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Material(
                      elevation: 12,
                      shadowColor: Colors.black26,
                      color: Colors.white,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: _confirmAndDeleteProduct,
                                  child: Text(
                                    'Delete',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () {
                                    Get.to(
                                      () => EditProductScreen(
                                        category_id: categoryID,
                                        sub_category_id: subCategoryID,
                                        name: name,
                                        price: price,
                                        specifications: specifications,
                                        description: description,
                                        product_id: product_id,
                                        images: images,
                                        imageID: imageID,
                                        delivery_charges: delivery_charges,
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Edit Product',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildImageHeader(double screenHeight, int carouselCount) {
    final h = screenHeight * 0.36;
    return SizedBox(
      height: h,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _carouselIndex = i),
            itemCount: carouselCount,
            itemBuilder: (context, index) {
              if (imagesList.isEmpty) {
                return ColoredBox(
                  color: Colors.grey.shade300,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: Colors.grey.shade600,
                  ),
                );
              }
              return CachedNetworkImage(
                imageUrl: AppUrl.baseUrlM + imagesList[index].toString(),
                fit: BoxFit.cover,
                width: double.infinity,
                height: h,
              );
            },
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
            left: 0,
            right: 0,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(carouselCount, (i) {
                final active = _carouselIndex == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 8 : 6,
                  height: active ? 8 : 6,
                  decoration: BoxDecoration(
                    color: active ? _accent : Colors.white.withOpacity(0.75),
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

  Widget _specDividerRow(String title, String value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: _labelGrey,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _titleDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _agreementRow(String title, VoidCallback onTap) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: _titleDark,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 20,
        color: Colors.grey.shade500,
      ),
      onTap: onTap,
    );
  }

  itmBox({img, tx, dx, rt, rv, id}) {
    double res_width = MediaQuery.of(context).size.width;
    double res_height = MediaQuery.of(context).size.height;
    return InkWell(
      onTap: () {},
      child: Container(
        width: res_width * 0.44,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 244, 244, 244),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(13.0),
          child: Column(
            children: [
              Container(
                height: res_height * 0.2,
                decoration: BoxDecoration(),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  child: CachedNetworkImage(
                    imageUrl: '$img',
                    fit: BoxFit.fill,
                    placeholder:
                        (context, url) =>
                            Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
                    errorWidget:
                        (context, url, error) =>
                            Center(child: Icon(Icons.error)),
                  ),
                ),
              ),
              SizedBox(height: res_height * 0.005),
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$tx', style: TextStyle(fontSize: 11)),
                    SizedBox(height: res_height * 0.006),
                    Text(
                      '$dx',
                      style: TextStyle(fontSize: 11),
                      textAlign: TextAlign.left,
                    ),
                    GestureDetector(
                      child: Row(
                        children: [
                          _myProductsStyleStars(
                            double.tryParse(rt.toString()) ?? 0,
                            size: 16,
                          ),
                          Text(
                            '($rv) Reviews',
                            style: TextStyle(fontSize: 9, color: Colors.grey),
                          ),
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
}
