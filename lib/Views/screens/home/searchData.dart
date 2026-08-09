import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/model/getAllProductsModel.dart';
import 'package:jebby/view_model/apiServices.dart';

import '../../../res/app_url.dart';
import 'package:jebby/Views/screens/home/ProductDetails.dart';
import 'package:jebby/res/color.dart';

class SearchData extends StatefulWidget {
  final dynamic word;

  const SearchData({super.key, this.word});

  @override
  State<SearchData> createState() => _SearchDataState();
}

class _SearchDataState extends State<SearchData> {
  bool isLoading = true;
  bool isError = false;
  bool emptyData = false;

  List<Data> results = [];
  GetAllProductsModel? _getAllProducts;

  void getProducts() {
    ApiRepository.shared.allProducts(
      (List) => {
        if (this.mounted)
          {
            if (List.data!.length == 0)
              {
                setState(() {
                  isLoading = false;
                  isError = false;
                  emptyData = true;
                  _getAllProducts = List;
                }),
              }
            else
              {
                setState(() {
                  _getAllProducts = List;
                  runFilter(widget.word.toString());
                  isLoading = false;
                  isError = false;
                  emptyData = false;
                }),
              },
          },
      },
      (error) => {
        if (this.mounted)
          {
            if (error != null)
              {
                setState(() {
                  isError = true;
                  isLoading = false;
                  emptyData = false;
                }),
              },
          },
      },
    );
  }

  void runFilter(String keyWord) {
    if (keyWord.isEmpty) {
      results = _getAllProducts!.data!;
    } else {
      results =
          _getAllProducts!.data!
              .where(
                (product) =>
                    product.name!.toLowerCase().contains(keyWord.toLowerCase()),
              )
              .toList();
    }
  }

  @override
  void initState() {
    super.initState();
    getProducts();
  }

  Widget _queryBanner(String query) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 22, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Results for',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  query.isEmpty ? 'All products' : query,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stateMessage({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _productCard(Data item) {
    // Match `SubCategory` `_ProductTile`: grid `mainAxisExtent: 225`, image height 118, radius 16.
    final imagePath = item.image?.toString() ?? '';
    final imageUrl =
        imagePath.startsWith('http') ? imagePath : AppUrl.baseUrlM + imagePath;
    final price = item.price;
    final priceStr =
        price != null
            ? '\$${price.toDouble().toStringAsFixed(2)}'
            : '\$—';
    final stars = double.tryParse(item.stars?.toString() ?? '0') ?? 0.0;
    final int filledStars = stars.round().clamp(0, 5);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.to(
            routeName: "PD",
            () => ProductDetailScreen(
              item.id,
              item.name,
              item.price,
              item.stars,
              imageUrl,
              item.specifications,
              item.userId,
              item.description,
              item.delivery_charges,
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 118,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder:
                    (_, __) => Container(
                      color: const Color(0xFFF0EDE8),
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: Color(0xFFE0B878),
                          size: 40,
                        ),
                      ),
                    ),
                errorWidget:
                    (_, __, ___) => Container(
                      height: 118,
                      color: const Color(0xFFF0EDE8),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 15.5,
                      color: const Color(0xFF2A2A2E),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    priceStr,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                      color: const Color(0xFF1D1D21),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: List.generate(5, (index) {
                      final active = index < filledStars;
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          active ? Icons.star : Icons.star_border,
                          color:
                              active
                                  ? const Color(0xFFF6AE02)
                                  : const Color(0xFFC6C8CF),
                          size: 18,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = widget.word?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leadingWidth: 56,
        leading: InkWell(
          onTap: () => Get.back(),
          borderRadius: BorderRadius.circular(50),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
        ),
        title: Text(
          'Search',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            sliver: SliverToBoxAdapter(child: _queryBanner(query)),
          ),
          if (isError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _stateMessage(
                icon: Icons.cloud_off_outlined,
                title: 'Something went wrong',
                subtitle: 'Could not load products. Try again later.',
              ),
            )
          else if (isLoading)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Searching…',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            )
          else if (emptyData)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _stateMessage(
                icon: Icons.inventory_2_outlined,
                title: 'No products yet',
                subtitle: 'There are no products to search.',
              ),
            )
          else if (results.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _stateMessage(
                icon: Icons.search_off_rounded,
                title: 'No matches',
                subtitle:
                    'No products matched "${query.isEmpty ? 'your search' : query}".',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 225,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _productCard(results[index]),
                  childCount: results.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
