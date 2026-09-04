import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/repositories/api_repository.dart';

import '../../../constants/app_url.dart';
import 'product_details.dart';
import 'package:jebby/constants/color.dart';

class FilteredDataScreen extends StatefulWidget {
  final dynamic subCatname;

  const FilteredDataScreen({super.key, this.subCatname});

  @override
  State<FilteredDataScreen> createState() => _FilteredDataScreenState();
}

class _FilteredDataScreenState extends State<FilteredDataScreen> {
  static const Color _starAccent = Color(0xFFF6AE02);
  static const Color _starInactive = Color(0xFFC6C8CF);
  static const Color _titleDark = Color(0xFF1B1B1F);
  static const Color _labelGrey = Color(0xFF72747A);

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

  @override
  Widget build(BuildContext context) {
    final products = ApiRepository.shared.getFilteredProductDataList?.data ?? [];
    final title = (widget.subCatname?.toString().trim().isNotEmpty ?? false)
        ? widget.subCatname.toString()
        : 'Filtered Results';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: InkWell(
          onTap: () => Get.back(),
          borderRadius: BorderRadius.circular(50),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
        ),
      ),
      body: products.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 52,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No products found',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _titleDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Try adjusting your filters and search again.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
              child: GridView.builder(
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 225,
                ),
                itemBuilder: (context, index) {
                  final data = products[index];
                  final stars =
                      (double.tryParse(data.stars.toString()) ?? 0).clamp(0, 5).toDouble();

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Get.to(
                        routeName: "PD",
                        () => ProductDetailScreen(
                          data.id,
                          data.name,
                          data.price,
                          data.stars,
                          AppUrl.baseUrlM + data.image.toString(),
                          data.specifications,
                          data.userId,
                          data.description,
                          data.delivery_charges,
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: AppUrl.baseUrlM + data.image.toString(),
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => ColoredBox(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryColor),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => ColoredBox(
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              data.name.toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _titleDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${data.price}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _labelGrey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _myProductsStyleStars(stars, size: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
