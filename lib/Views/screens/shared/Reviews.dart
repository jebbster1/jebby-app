import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:jebby/res/app_url.dart';
import 'package:jebby/utils/profile_image.dart';
import 'package:jebby/res/color.dart';
import 'package:jebby/view_model/apiServices.dart';

/// Product reviews list (renter + vendor). Opened from product detail flows.
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({
    super.key,
    this.stars,
    this.reviewsLenght,
    this.prodID,
  });

  final dynamic stars;
  final dynamic reviewsLenght;
  final dynamic prodID;

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  static const Color _accent = Color(0xFFF6AE02);
  /// Inactive stars — same as `MyProducts.productCard`.
  static const Color _starInactive = Color(0xFFC6C8CF);
  static const Color _textDark = Color(0xFF1B1B1F);
  static const Color _textGrey = Color(0xFF72747A);

  bool isLoading = true;
  bool isError = false;
  bool isEmpty = false;

  /// Same as `MyProducts.productCard` star row.
  Widget _myProductsStyleStars(double rating, {double size = 18}) {
    final filled =
        (rating.isNaN ? 0.0 : rating).round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final active = index < filled;
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

  void getReviews() {
    ApiRepository.shared.reviewsByProductId(
      widget.prodID.toString(),
      (list) {
        if (mounted) {
          setState(() {
            isEmpty = list.data?.isEmpty ?? true;
            isLoading = false;
            isError = false;
          });
        }
      },
      (error) {
        if (mounted && error != null) {
          setState(() {
            isEmpty = false;
            isLoading = false;
            isError = true;
          });
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getReviews();
  }

  @override
  Widget build(BuildContext context) {
    final reviews = ApiRepository.shared.getReviewsByProductIdModelList?.data ?? [];
    final double avgRating =
        (double.tryParse(widget.stars.toString()) ?? 0).clamp(0, 5);
    final int totalReviews =
        int.tryParse(widget.reviewsLenght.toString()) ?? reviews.length;
    final Map<int, int> starCount = _buildStarCountMap(reviews);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        title: Text(
          'Reviews',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.black,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
          style: IconButton.styleFrom(foregroundColor: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                avgRating.toStringAsFixed(
                  avgRating == avgRating.roundToDouble() ? 0 : 1,
                ),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 58,
                  color: _textDark,
                ),
              ),
              Center(child: _myProductsStyleStars(avgRating, size: 22)),
              const SizedBox(height: 8),
              Text(
                "$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}",
                style: GoogleFonts.inter(
                  color: _textGrey,
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 28),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE8E8E8)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ratingBarRow(
                        label: "Excellent",
                        value: _share(starCount[5] ?? 0, totalReviews),
                        color: const Color(0xFF1CAA16),
                      ),
                      const SizedBox(height: 25),
                      _ratingBarRow(
                        label: "Good",
                        value: _share(starCount[4] ?? 0, totalReviews),
                        color: const Color(0xFF84D01E),
                      ),
                      const SizedBox(height: 25),
                      _ratingBarRow(
                        label: "Average",
                        value: _share(starCount[3] ?? 0, totalReviews),
                        color: const Color(0xFFEACB1D),
                      ),
                      const SizedBox(height: 25),
                      _ratingBarRow(
                        label: "Below Average",
                        value: _share(starCount[2] ?? 0, totalReviews),
                        color: const Color(0xFFF07A18),
                      ),
                      const SizedBox(height: 25),
                      _ratingBarRow(
                        label: "Poor",
                        value: _share(starCount[1] ?? 0, totalReviews),
                        color: const Color(0xFFF0322D),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: isError
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          "Some error occurred while loading reviews.",
                          style: GoogleFonts.inter(color: _textGrey),
                        ),
                      )
                    : isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor),
                            ),
                          )
                        : isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  "No reviews yet.",
                                  style: GoogleFonts.inter(color: _textGrey),
                                ),
                              )
                            : ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: reviews.length,
                                separatorBuilder: (_, __) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                itemBuilder: (context, int index) {
                                  final data = reviews[index];
                                  final date = DateFormat('yyyy-MM-dd').format(
                                    DateTime.parse(data.createdAt.toString()),
                                  );
                                  final stars = data.stars;
                                  final desc = data.description.toString();
                                  final name = data.userName.toString();
                                  return _card(
                                    data.image?.toString(),
                                    date,
                                    stars,
                                    desc,
                                    name,
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ratingBarRow({
    required String label,
    required double value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            maxLines: 2,
            softWrap: true,
            style: GoogleFonts.inter(
              color: _textDark,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 10, color: const Color(0xFFD9D9D9)),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value,
                    child: Container(height: 10, color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<int, int> _buildStarCountMap(List reviews) {
    final map = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in reviews) {
      final s = int.tryParse(r.stars.toString()) ?? 0;
      if (map.containsKey(s)) {
        map[s] = (map[s] ?? 0) + 1;
      }
    }
    return map;
  }

  double _share(int count, int total) {
    if (total <= 0) return 0;
    return (count / total).clamp(0.0, 1.0);
  }

  Widget _reviewerAvatar(String? imagePath) {
    return ProfileImage.circularAvatar(
      radius: 23,
      baseUrl: AppUrl.baseUrlM,
      imagePath: ProfileImage.sanitizePath(imagePath),
    );
  }

  Widget _card(String? imagePath, date, stars, desc, name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _reviewerAvatar(imagePath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _textGrey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _myProductsStyleStars(
            (double.tryParse(stars.toString()) ?? 0).clamp(0, 5),
            size: 17,
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _textDark,
              fontWeight: FontWeight.w400,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
