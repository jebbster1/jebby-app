import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/Views/screens/home/ProductDetails.dart';
import 'package:jebby/res/app_url.dart';
import 'package:jebby/view_model/apiServices.dart';
import 'package:provider/provider.dart';

import '../../../Services/provider/sign_in_provider.dart';
import '../../../model/user_model.dart';
import '../../../view_model/user_view_model.dart';
import 'package:jebby/res/color.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({Key? key}) : super(key: key);

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  bool isLoading = true;
  bool isError = false;
  bool isEmpty = false;

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

  void profileData(BuildContext context) async {
    getUserDate()
        .then((value) async {
          token = value.token.toString();
          sourceId = value.id.toString();
          fullname = value.name.toString();
          email = value.email.toString();
          role = value.role.toString();
          getFavourites();
        })
        .onError((error, stackTrace) {
          if (kDebugMode) {}
        });
  }

  void getFavourites() {
    ApiRepository.shared.getFavourites(
      sourceId,
      (List) {
        if (!mounted) return;
        if (List.data!.length == 0) {
          setState(() {
            isLoading = false;
            isEmpty = true;
            isError = false;
          });
        } else {
          setState(() {
            isLoading = false;
            isEmpty = false;
            isError = false;
          });
        }
      },
      (error) {
        if (error != null && mounted) {
          setState(() {
            isLoading = false;
            isEmpty = false;
            isError = true;
          });
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getData();
    profileData(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
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
          'My Wishlist',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'An error occurred while loading your wishlist.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
    }
    if (isEmpty) {
      return Center(
        child: Text(
          'No items added yet',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      );
    }

    final list = ApiRepository.shared.getFavouriteProductsModelList!.data!;

    // Match products grid in `SubCategory.dart` / vendor `MyProducts.dart`.
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
        mainAxisExtent: 225,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final data = list[index];
        final id = data.id.toString();
        final userID = data.userId.toString();
        final servAgreement = data.description.toString();
        final img = data.image.toString();
        final name = data.name.toString();
        final specs = data.specifications.toString();
        final priceInt = data.price ?? 0;
        final stars = data.stars.toString();
        final delivery_charges = data.delivery_charges.toString();

        return _WishlistProductCard(
          imageUrl: AppUrl.baseUrlM + img,
          title: name,
          price: priceInt,
          rating: double.tryParse(stars) ?? 0,
          onTap: () {
            Get.to(
              routeName: 'PD',
              () => ProductDetailScreen(
                id,
                name,
                priceInt,
                stars,
                AppUrl.baseUrlM + img,
                specs,
                userID,
                servAgreement,
                delivery_charges,
              ),
            );
          },
        );
      },
    );
  }
}

class _WishlistProductCard extends StatelessWidget {
  const _WishlistProductCard({
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.rating,
    required this.onTap,
  });

  final String imageUrl;
  final String title;
  final int price;
  final double rating;
  final VoidCallback onTap;

  /// Same as `_ProductTile` in `SubCategory.dart`.
  static const double _radius = 16;
  static const double _imageHeight = 118;

  String get _priceLabel => '\$${price.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final filledStars = rating.round().clamp(0, 5);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_radius),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(_radius),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: _imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (_, __) => Container(
                          height: _imageHeight,
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
                          height: _imageHeight,
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
                Positioned(
                  left: 10,
                  top: 10,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red.shade600,
                    size: 24,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
                    _priceLabel,
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
}
