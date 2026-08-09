import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:jebby/Services/product_services.dart';
import 'package:jebby/Views/screens/home/SubCategory.dart';
import 'package:jebby/model/sub_category_list_model.dart';

import '../../../res/app_url.dart';
import '../../../view_model/category_get_View_model.dart';
import 'package:jebby/res/color.dart';
import 'package:jebby/Services/analytics_service.dart';

class ElectronicsScreen extends StatefulWidget {
  final String? id;
  final String? categoryname;
  final String? pictureurl;

  const ElectronicsScreen({
    super.key,
    this.categoryname,
    this.id,
    this.pictureurl,
  });

  @override
  State<ElectronicsScreen> createState() => _ElectronicsScreenState();
}

class _ElectronicsScreenState extends State<ElectronicsScreen> {
  final ProductServices _productServices = ProductServices();
  /// Cache Future<int> so FutureBuilder gets the same future on rebuild and shows the count.
  final Map<String, Future<int>> _productCountFutures = {};

  String _categoryDescription(String? rawName) {
    final name = (rawName ?? '').trim();
    if (name.isEmpty) {
      return 'Explore top picks curated for every style and need. Browse subcategories to quickly find the right rental item for you.';
    }
    return 'Discover popular $name rentals curated for quality, comfort, and everyday use. Browse subcategories to find the perfect match for your needs.';
  }

  Future<int> _getProductCount(String subcategoryId) {
    return _productCountFutures.putIfAbsent(
      subcategoryId,
      () async {
        try {
          final result = await _productServices.getProducts(subcategoryId);
          return result?.data?.length ?? 0;
        } catch (_) {
          return 0;
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    GetAPiFromModel getAPiFromModel = GetAPiFromModel();
    double scrimStrength = 0.15;
    double res_width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(350),
        child: Builder(
          builder: (context) {

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image
                    CachedNetworkImage(
                      imageUrl: widget.pictureurl!,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Center(
                            child:
                                CircularProgressIndicator(color: AppColors.primaryColor), // Loading spinner
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
                      padding: const EdgeInsets.only(left: 14, top: 66),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Material(
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      body: Container(
        color: const Color(0xFFF5F5F5),
        width: double.infinity,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Container(
                  child: Text(
                    "${widget.categoryname}",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 6),
                Container(
                  width: res_width * 0.9,
                  child: Text(
                    _categoryDescription(widget.categoryname),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                  ),
                ),

                SizedBox(height: 10),
                SizedBox(
                  height: 600,
                  child: FutureBuilder(
                    future: getAPiFromModel.getSubCategoryList(
                      widget.id.toString(),
                    ),
                    builder: (
                      context,
                      AsyncSnapshot<SubCategoryList> snapshot,
                    ) {
                      final data = snapshot.data?.data;
                      if (!snapshot.hasData) {
                        return Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
                      } else {
                        if (snapshot.data!.data!.length != 0) {

                          return Container(
                            width: res_width,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(6),
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),

                              itemCount: snapshot.data!.data!.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 1.2,
                              ),
                              itemBuilder: (context, index) {
                                final subcategoryId = data![index].id.toString();
                                return FutureBuilder<int>(
                                  future: _getProductCount(subcategoryId),
                                  builder: (context, countSnapshot) {
                                    final count = countSnapshot.hasData
                                        ? countSnapshot.data
                                        : null;
                                    return contBox(
                                      txt: data[index].name,
                                      img: '${AppUrl.baseUrlM}${data[index].image}',
                                      id: subcategoryId,
                                      itemCount: count,
                                    );
                                  },
                                );
                              },
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Text(
                              "No data available",
                              style: TextStyle(fontSize: 14),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  contBox({txt, img, id, int? itemCount}) {
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
            'subcategory_viewed',
            props: {
              'category_id': widget.id,
              'subcategory_id': id,
              'source': 'category',
            },
          );
          Get.to(
                () => Electronics2(
              parentCategoryName: widget.categoryname.toString(),
              subcategoryName: txt.toString(),
              subcategoryId: id.toString(),
            ),
          );
        },
        child: SizedBox(
          width: res_width * 0.45,
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
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
                        Container(
                          width:res_width*0.27,
                          child: Text(
                            "$txt",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              height: 1.1,
                              letterSpacing: -0.2,
                              shadows: [
                                Shadow(blurRadius: 4, color: Colors.black54),
                              ],
                            ),
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
                      itemCount != null
                          ? (itemCount == 1
                              ? '1 item'
                              : '$itemCount items')
                          : '...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
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
}
