import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:jebby/Views/screens/home/Category.dart';
import 'package:jebby/Views/screens/shared/Notification.dart';
import 'package:jebby/Views/screens/profile/userprofile.dart';
import 'package:jebby/res/color.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../model/categoryList_model.dart';
import '../../../model/sub_category_list_model.dart';
import '../../../res/app_url.dart';
import '../../../view_model/category_get_View_model.dart';
import 'package:jebby/Services/analytics_service.dart';

/// Featured categories grid. Designed to sit inside [MainScreen] (index 2) so the
/// shell bottom navigation stays visible—do not push this with `Get.to`; call
/// `BottomController.navBarChange(2)` on the shell instead.
class FeaturedCategoriesScreen extends StatefulWidget {
  const FeaturedCategoriesScreen({super.key});

  @override
  State<FeaturedCategoriesScreen> createState() =>
      _FeaturedCategoriesScreenState();
}

class _FeaturedCategoriesScreenState extends State<FeaturedCategoriesScreen> {
  String? _role;

  final GetAPiFromModel _categoryApi = GetAPiFromModel();
  late Future<CategoryList> _categoryFuture = _categoryApi.getCategoryList();
  final Map<String, Future<SubCategoryList>> _subcategoryFutures = {};

  Future<SubCategoryList> _getSubcategoryFuture(String categoryId) {
    return _subcategoryFutures.putIfAbsent(
      categoryId,
      () => _categoryApi.getSubCategoryList(categoryId),
    );
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() => _role = p.getString('role'));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const headerHeight = 140.0;
    const radius = 26.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(headerHeight),
        child: Builder(
          builder: (context) {
            final top = MediaQuery.of(context).padding.top;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: headerHeight,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(radius),
                      bottomRight: Radius.circular(radius),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(16, top + 12, 16, 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 12),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Featured Categories',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Visibility(
                            visible: _role != null && _role != 'Guest',
                            child: _CircleAction(
                              onTap: () {
                                Get.to(() => NotificationsScreen());
                              },
                              image: const AssetImage(
                                'assets/slicing/notificationnew.png',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Visibility(
                            visible: _role != null && _role != 'Guest',
                            child: _CircleAction(
                              onTap: () {
                                Get.to(() => MyProfileScreen());
                              },
                              image: const AssetImage(
                                'assets/slicing/personnew.png',
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
          },
        ),
      ),
      body: FutureBuilder<CategoryList>(
        future: _categoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
          }
          if (!snapshot.hasData || snapshot.data?.data == null) {
            return const Center(child: Text("No categories found"));
          }

          final data = snapshot.data!.data!;
          final bottomPad = MediaQuery.of(context).padding.bottom + 10;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  GridView.builder(
                    padding: const EdgeInsets.all(6),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: data.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.2,
                        ),
                    itemBuilder: (_, index) {
                      final category = data[index];
                      final categoryId = category.id.toString();
                      return FutureBuilder<SubCategoryList>(
                        future: _getSubcategoryFuture(categoryId),
                        builder: (context, subSnapshot) {
                          final count =
                              subSnapshot.hasData &&
                                      subSnapshot.data?.data != null
                                  ? subSnapshot.data!.data!.length
                                  : null;
                          return _categoryCard(
                            txt: category.name,
                            img: '${AppUrl.baseUrlM}${category.image}',
                            id: categoryId,
                            subcategoryCount: count,
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: bottomPad),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryCard({txt, img, id, int? subcategoryCount}) {
    return GestureDetector(
      onTap: () {
        AnalyticsService.instance.track(
          'category_viewed',
          props: {
            'category_id': id,
            'source': 'featured_categories',
          },
        );
        Get.to(
          () => ElectronicsScreen(categoryname: txt, id: id, pictureurl: img),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: '$img',
              fit: BoxFit.cover,
              placeholder:
                  (context, url) => Container(color: Colors.grey.shade300),
              errorWidget:
                  (context, url, error) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.35, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "$txt",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                        ),
                        const Icon(
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
            ),
          ],
        ),
      ),
    );
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
