// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:jebby/Views/screens/agreements/insuranceAndIndemnifications.dart';
import 'package:jebby/Views/screens/agreements/rentalAgreement.dart';
import 'package:jebby/Views/screens/agreements/termsAndConditions.dart';
import 'package:jebby/Views/screens/agreements/transportAndInstallationPolicy.dart';
import 'package:jebby/Views/screens/home/RentNow.dart';
import 'package:jebby/Views/screens/profile/userprofile.dart';
import 'package:jebby/Views/screens/home/Messages.dart';
import 'package:jebby/Views/screens/shared/Reviews.dart';

import '../../../model/getProductsByProductId.dart';
import '../../../model/getReviewsByProductId.dart' as review_model;
import '../../../model/product_chat_context.dart';
import '../../../model/user_model.dart';
import '../../../res/app_url.dart';
import '../../../view_model/apiServices.dart';
import '../../../view_model/user_view_model.dart';
import 'package:jebby/res/color.dart';

class ProductDetailScreen extends StatefulWidget {
  final dynamic id;
  final dynamic name;
  final dynamic price;
  final dynamic stars;
  final dynamic image;
  final dynamic specs;
  final dynamic userID;
  final dynamic desc;
  final dynamic messageStatus;
  final dynamic delivery_charges;
  final dynamic sourceId;

  const ProductDetailScreen(
    this.id,
    this.name,
    this.price,
    this.stars,
    this.image,
    this.specs,
    this.userID,
    this.desc,
    this.messageStatus,
    this.delivery_charges, {
    this.sourceId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const Color _accent = Color(0xFFF6AE02);
  static const Color _pageBg = Color(0xFFF3F3F5);
  static const Color _labelGrey = Color(0xFF72747A);
  static const Color _bodyGrey = Color(0xFF6D6D75);
  static const Color _titleDark = Color(0xFF1B1B1F);

  bool fav = false;
  String? role;
  String sourceId = "";

  String vendorName = "Vendor";
  String vendorAddress = "";
  String vendorImage = "";
  String vendorBackImage = "";

  final PageController _pageController = PageController();
  int _imageIndex = 0;
  List<String> _galleryUrls = [];
  bool _galleryLoading = true;

  int _reviewTotal = 0;
  review_model.Data? _firstReview;
  Map<int, double> _ratingDistribution = const {
    5: 0.0,
    4: 0.0,
    3: 0.0,
    2: 0.0,
    1: 0.0,
  };

  /// Product availability window (API: pastart / paend).
  DateTime? _availStart;
  DateTime? _availEnd;

  /// Blocked / booked window (API: dastart / daend). Shown red when it differs from availability.
  DateTime? _blockedStart;
  DateTime? _blockedEnd;
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isProductOwner =>
      sourceId.isNotEmpty && sourceId == widget.userID.toString();

  @override
  void initState() {
    super.initState();
    _galleryUrls = [AppUrl.baseUrlM + widget.image.toString()];
    profileData();
    getVendor();
    _loadGallery();
    _loadReviews();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<UserModel> getUserDate() => UserViewModel().getUser();

  void profileData() async {
    getUserDate().then((value) {
      setState(() {
        role = value.role;
        sourceId = value.id.toString();
      });
      getFavourites();
    });
  }

  void getVendor() {
    ApiRepository.shared.userCredential(
      (_) {
        if (ApiRepository.shared.getUserCredentialModelList!.data!.isNotEmpty) {
          final v = ApiRepository.shared.getUserCredentialModelList!.data![0];
          setState(() {
            vendorName = v.name.toString();
            vendorAddress = v.address.toString();
            vendorImage = v.image.toString();
            vendorBackImage = v.backImage.toString();
          });
        }
      },
      (_) {},
      widget.userID.toString(),
    );
  }

  void _loadGallery() {
    ApiRepository.shared.getProductsById(
      (GetProductsByProductId list) {
        final urls = _extractImageUrls(list);
        DateTime? a0;
        DateTime? a1;
        DateTime? b0;
        DateTime? b1;
        if (list.data != null && list.data!.isNotEmpty) {
          final p = list.data!.first;
          a0 = _parseDateOnly(p.pastart);
          a1 = _parseDateOnly(p.paend);
          b0 = _parseDateOnly(p.dastart);
          b1 = _parseDateOnly(p.daend);
        }
        if (mounted) {
          setState(() {
            _galleryUrls = urls;
            _galleryLoading = false;
            _availStart = a0;
            _availEnd = a1;
            _blockedStart = b0;
            _blockedEnd = b1;
            // Always open on the current month — never jump to a past availability start month.
            _calendarMonth = DateTime(
              DateTime.now().year,
              DateTime.now().month,
            );
          });
        }
      },
      (_) {
        if (mounted) {
          setState(() {
            _galleryUrls = [AppUrl.baseUrlM + widget.image.toString()];
            _galleryLoading = false;
          });
        }
      },
      widget.id.toString(),
    );
  }

  DateTime? _parseDateOnly(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    final d = DateTime.tryParse(s);
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day);
  }

  bool _sameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _blockedMatchesAvailability() {
    if (_availStart == null ||
        _availEnd == null ||
        _blockedStart == null ||
        _blockedEnd == null) {
      return true;
    }
    return _sameCalendarDay(_availStart!, _blockedStart!) &&
        _sameCalendarDay(_availEnd!, _blockedEnd!);
  }

  bool _isInsideRange(DateTime day, DateTime start, DateTime end) {
    return !day.isBefore(start) && !day.isAfter(end);
  }

  bool _isInAvailability(DateTime day) {
    if (_availStart == null || _availEnd == null) return false;
    return _isInsideRange(day, _availStart!, _availEnd!);
  }

  bool _isBookedDay(DateTime day) {
    if (_blockedStart == null || _blockedEnd == null) return false;
    if (_availStart == null || _availEnd == null) return false;
    if (_blockedMatchesAvailability()) return false;
    if (!_isInsideRange(day, _blockedStart!, _blockedEnd!)) return false;
    return _isInAvailability(day);
  }

  /// True when [day] is strictly before today (date-only). Past days are never "available" UI.
  bool _isPastCalendarDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    return d.isBefore(today);
  }

  void _shiftCalendarMonth(int delta) {
    final now = DateTime.now();
    final earliestMonth = DateTime(now.year, now.month);

    if (_availStart == null || _availEnd == null) {
      setState(() {
        final next = DateTime(
          _calendarMonth.year,
          _calendarMonth.month + delta,
        );
        if (delta < 0 && next.isBefore(earliestMonth)) return;
        _calendarMonth = next;
      });
      return;
    }
    final next = DateTime(_calendarMonth.year, _calendarMonth.month + delta);
    final lastAvail = DateTime(_availEnd!.year, _availEnd!.month);
    if (next.isAfter(lastAvail)) return;
    if (next.isBefore(earliestMonth)) return;
    setState(() => _calendarMonth = next);
  }

  String _formatApiDate(DateTime? d) =>
      d == null ? '' : DateFormat('yyyy-MM-dd').format(d);

  List<String> _extractImageUrls(GetProductsByProductId list) {
    final urls = <String>[];
    final data = list.data;
    if (data == null || data.isEmpty) {
      return [AppUrl.baseUrlM + widget.image.toString()];
    }
    final List<Images> imageEntries = [];
    if (data.length >= 2 && data[1].images != null) {
      imageEntries.addAll(data[1].images!);
    } else if (data[0].images != null) {
      imageEntries.addAll(data[0].images!);
    }
    for (final im in imageEntries) {
      final p = im.path?.toString() ?? '';
      if (p.isNotEmpty) {
        urls.add(AppUrl.baseUrlM + p);
      }
    }
    if (urls.isEmpty) {
      urls.add(AppUrl.baseUrlM + widget.image.toString());
    }
    return urls;
  }

  void _loadReviews() {
    ApiRepository.shared.reviewsByProductId(widget.id.toString(), (
      review_model.GetAllReviewsByProductId list,
    ) {
      final total = list.totalreviews ?? list.data?.length ?? 0;
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
      final first =
          (list.data != null && list.data!.isNotEmpty)
              ? list.data!.first
              : null;
      if (mounted) {
        setState(() {
          _reviewTotal = total;
          _firstReview = first;
          _ratingDistribution = distribution;
        });
      }
    }, (_) {});
  }

  void getFavourites() {
    if (sourceId.isEmpty) return;
    ApiRepository.shared.getFavourites(sourceId, (_) {
      final favs =
          ApiRepository.shared.getFavouriteProductsModelList?.data ?? [];
      for (final f in favs) {
        if (f.id.toString() == widget.id.toString()) {
          setState(() => fav = true);
          break;
        }
      }
    }, (_) {});
  }

  void addFavorite(int val) {
    ApiRepository.shared.addFavorite(
      sourceId.toString(),
      widget.id.toString(),
      val.toString(),
    );
  }

  void rentClicked(BuildContext context) async {
    Get.to(
      () => RentnowScreen(
        vendorName,
        vendorAddress,
        "",
        vendorImage,
        widget.userID,
        widget.id,
        _formatApiDate(_availStart),
        _formatApiDate(_availEnd),
        widget.price,
        "",
        "",
        "simple",
        widget.delivery_charges,
        "",
      ),
    );
  }

  double get _avgRating =>
      double.tryParse(widget.stars.toString())?.clamp(0, 5) ?? 0;

  List<MapEntry<String, String>> _parsedSpecs() {
    final raw = widget.specs?.toString() ?? '';
    final out = <MapEntry<String, String>>[];
    for (final line in raw.split(RegExp(r'\r?\n'))) {
      final t = line.trim();
      if (t.isEmpty) continue;
      final idx = t.indexOf(':');
      if (idx > 0) {
        out.add(
          MapEntry(t.substring(0, idx).trim(), t.substring(idx + 1).trim()),
        );
      }
    }
    if (out.isEmpty) {
      return const [
        MapEntry('Material', 'Wooden'),
        MapEntry('Condition', 'New'),
        MapEntry('Finish', 'Simple Finish'),
        MapEntry('Style', 'Minimal'),
      ];
    }
    return out;
  }

  String _relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inDays >= 30) {
      final m = (diff.inDays / 30).floor();
      return '$m month${m == 1 ? '' : 's'} ago';
    }
    if (diff.inDays >= 7) {
      final w = diff.inDays ~/ 7;
      return '$w week${w == 1 ? '' : 's'} ago';
    }
    if (diff.inDays >= 1)
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return 'Recently';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: _pageBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildImageHeader(size)),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -22),
                  child: _buildContentSheet(),
                ),
              ),
            ],
          ),
          if (!_isProductOwner)
            Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomBar()),
        ],
      ),
    );
  }

  Widget _buildImageHeader(Size size) {
    final h = size.height * 0.36;
    return SizedBox(
      height: h,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_galleryLoading)
            Container(
              color: Colors.grey.shade300,
              child: const Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
            )
          else
            PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _imageIndex = i),
              itemCount: _galleryUrls.length,
              itemBuilder:
                  (_, i) => CachedNetworkImage(
                    imageUrl: _galleryUrls[i],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: h,
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
            left: 0,
            right: 0,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_galleryUrls.length, (i) {
                final active = _imageIndex == i;
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

  Widget _buildContentSheet() {
    final specs = _parsedSpecs();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 38, 20, _isProductOwner ? 28 : 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    widget.name.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _titleDark,
                      height: 1.2,
                    ),
                  ),
                ),
                if (role != "Guest" && !_isProductOwner)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    icon: Icon(
                      fav ? Icons.favorite : Icons.favorite_border,
                      color: fav ? Colors.red : _labelGrey,
                      size: 26,
                    ),
                    onPressed: () {
                      setState(() {
                        fav = !fav;
                        addFavorite(fav ? 1 : 0);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rental Price',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF494A50),
                  ),
                ),
                Text(
                  '\$${widget.price}',
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
              widget.desc.toString(),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: _bodyGrey,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Get.to(
                  () => RenterProfile(
                    vendorID: widget.userID.toString(),
                    vendorName: vendorName,
                    vendorImage: vendorImage,
                    vendorBackImage: vendorBackImage,
                    vendorAddress: vendorAddress,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          vendorImage.isEmpty
                              ? const AssetImage(
                                    'assets/slicing/blankuser.jpeg',
                                  )
                                  as ImageProvider
                              : NetworkImage(AppUrl.baseUrlM + vendorImage),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        vendorName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _titleDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
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
            ...specs.map((e) => _specDividerRow(e.key, e.value)),
            if (!_galleryLoading) ...[
              const SizedBox(height: 16),
              _buildAvailabilitySection(),
            ],
            const SizedBox(height: 8),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
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
                    () => Get.to(() => RentalAgreement()),
                  ),
                  _agreementRow(
                    'Terms & Conditions',
                    () => Get.to(() => TermsAndCondition()),
                  ),
                  _agreementRow(
                    'Insurance & Indemnifications Policy',
                    () => Get.to(() => InsuranceAndIndemnification()),
                  ),
                  _agreementRow(
                    'Transportation & Installation Policy',
                    () => Get.to(() => TransportAndInstallationPolicy()),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: true,
                controlAffinity: ListTileControlAffinity.trailing,
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
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 108,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _avgRating.toStringAsFixed(
                                      _avgRating == _avgRating.roundToDouble()
                                          ? 0
                                          : 2,
                                    ),
                                    style: GoogleFonts.inter(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w700,
                                      color: _titleDark,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$_reviewTotal Reviews',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: _labelGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  RatingBarIndicator(
                                    rating: _avgRating,
                                    itemCount: 5,
                                    itemSize: 16,
                                    itemBuilder:
                                        (_, __) => const Icon(
                                          Icons.star_rounded,
                                          color: _accent,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: List.generate(5, (i) {
                                  final star = 5 - i;
                                  final w =
                                      (_ratingDistribution[star] ?? 0.0)
                                          .clamp(0.0, 1.0);
                                  final pct = (w * 100).round();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '$star',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: _titleDark,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.star_rounded,
                                              size: 14,
                                              color: _accent,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: w,
                                              minHeight: 8,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(_accent),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 38,
                                          child: Text(
                                            '$pct%',
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: _labelGrey,
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
                        if (_firstReview != null) ...[
                          const SizedBox(height: 25),
                          // Divider(
                          //   height: 1,
                          //   thickness: 1,
                          //   color: Colors.grey.shade300,
                          // ),
                          _reviewPreviewCard(_firstReview!),
                        ],
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: () {
                              Get.to(
                                () => ReviewsScreen(
                                  stars: widget.stars,
                                  reviewsLenght: _reviewTotal.toString(),
                                  prodID: widget.id,
                                ),
                              );
                            },
                            child: Text(
                              'Read More',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
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
    );
  }

  static const Color _availCardBorder = Color(0xFFE5E5EA);
  static const Color _availCardBg = Color(0xFFF7F7F9);
  static const Color _bookedRed = Color(0xFFE53935);

  Widget _buildAvailabilitySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _availCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _availCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Availability',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _titleDark,
            ),
          ),
          const SizedBox(height: 10),
          _availabilityLegendRow(),
          const SizedBox(height: 12),
          if (_availStart == null || _availEnd == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Rental availability dates are not set for this listing yet.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _labelGrey,
                  height: 1.35,
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _availCardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _calendarNavButton(
                        Icons.chevron_left,
                        () => _shiftCalendarMonth(-1),
                      ),
                      Expanded(
                        child: Text(
                          DateFormat('MMMM yyyy').format(_calendarMonth),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: _titleDark,
                          ),
                        ),
                      ),
                      _calendarNavButton(
                        Icons.chevron_right,
                        () => _shiftCalendarMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _calendarWeekdayRow(),
                  const SizedBox(height: 4),
                  _calendarGridForMonth(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _availabilityLegendRow() {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        _legendDot(
          fill: const Color(0xFFC8C8CE),
          label: 'Available',
          outlined: false,
        ),
        _legendDot(
          fill: Colors.transparent,
          label: 'Unavailable',
          outlined: true,
        ),
        _legendDot(fill: _bookedRed, label: 'Booked', outlined: false),
      ],
    );
  }

  Widget _legendDot({
    required Color fill,
    required String label,
    required bool outlined,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: outlined ? Colors.transparent : fill,
            border: Border.all(
              color: outlined ? const Color(0xFFD0D0D6) : fill,
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _labelGrey,
          ),
        ),
      ],
    );
  }

  Widget _calendarNavButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFF0F0F2),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 22, color: _labelGrey),
        ),
      ),
    );
  }

  Widget _calendarWeekdayRow() {
    const labels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    return Row(
      children:
          labels
              .map(
                (e) => Expanded(
                  child: Center(
                    child: Text(
                      e,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _labelGrey,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _calendarGridForMonth() {
    final y = _calendarMonth.year;
    final m = _calendarMonth.month;
    final first = DateTime(y, m, 1);
    final daysInMonth = DateTime(y, m + 1, 0).day;
    final leading = first.weekday % 7;
    final prevDays = DateTime(y, m, 0).day;
    final rowCount = ((leading + daysInMonth + 6) ~/ 7);
    final rows = <Widget>[];

    for (int r = 0; r < rowCount; r++) {
      final cells = <Widget>[];
      for (int c = 0; c < 7; c++) {
        final i = r * 7 + c;
        late DateTime day;
        var outside = false;
        if (i < leading) {
          final d = prevDays - (leading - 1 - i);
          day = DateTime(y, m - 1, d);
          outside = true;
        } else if (i < leading + daysInMonth) {
          day = DateTime(y, m, i - leading + 1);
          outside = false;
        } else {
          final d = i - leading - daysInMonth + 1;
          day = DateTime(y, m + 1, d);
          outside = true;
        }
        cells.add(
          Expanded(child: _calendarDayCell(day, outsideMonth: outside)),
        );
      }
      rows.add(Row(children: cells));
      if (r < rowCount - 1) {
        rows.add(const SizedBox(height: 2));
      }
    }
    return Column(children: rows);
  }

  Widget _calendarDayCell(DateTime day, {required bool outsideMonth}) {
    const double h = 30;
    final isPast = !outsideMonth && _isPastCalendarDay(day);
    final booked = !outsideMonth && !isPast && _isBookedDay(day);
    final inWindow = !outsideMonth && _isInAvailability(day);
    final showAvailableGrey = inWindow && !booked && !isPast;

    Color textColor;
    if (outsideMonth) {
      textColor = const Color(0xFFD8D8DC);
    } else if (isPast) {
      textColor = const Color(0xFFB8B8BE);
    } else if (!inWindow) {
      textColor = const Color(0xFFB8B8BE);
    } else {
      textColor = _titleDark;
    }

    Widget inner = Text(
      '${day.day}',
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
    );

    if (booked) {
      inner = Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFFEBEE),
        ),
        child: Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _bookedRed,
          ),
          child: Text(
            '${day.day}',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (showAvailableGrey) {
      inner = Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE4E4E8),
        ),
        child: Text(
          '${day.day}',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _titleDark,
          ),
        ),
      );
    }

    return SizedBox(height: h, child: Center(child: inner));
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

  Widget _reviewPreviewCard(review_model.Data r) {
    final name = r.userName?.toString() ?? 'User';
    final img = r.image?.toString() ?? '';
    final starsVal = (r.stars ?? 0).toDouble().clamp(0, 5);
    final desc = r.description?.toString() ?? '';
    final snippet = desc.length > 120 ? '${desc.substring(0, 120)}…' : desc;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade300,
          backgroundImage:
              img.isNotEmpty
                  ? NetworkImage(AppUrl.baseUrlM + img)
                  : const AssetImage('assets/slicing/blankuser.jpeg')
                      as ImageProvider,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: _titleDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _relativeTime(r.createdAt?.toString()),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: _labelGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: _accent, size: 18),
                      const SizedBox(width: 2),
                      Text(
                        starsVal.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _titleDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                snippet,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _titleDark,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (role != "Guest")
                Material(
                  color: Colors.black,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Get.to(
                      () => Chat(
                        widget.userID,
                        productContext: ProductChatContext(
                          productId: widget.id.toString(),
                          name: widget.name.toString(),
                          price: widget.price.toString(),
                          image: widget.image.toString(),
                          vendorUserId: widget.userID.toString(),
                          recipientId: widget.userID.toString(),
                        ),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              if (role != "Guest") const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kprimaryColor,
                    // TODO: remove following two lines when rentals are ready
                    disabledBackgroundColor: Colors.grey.shade400,
                    disabledForegroundColor: Colors.white,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  // TODO: re-enable when rentals are ready
                  // onPressed: () => rentClicked(context),
                  onPressed: null,
                  child: Text(
                    'Rent Now',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
