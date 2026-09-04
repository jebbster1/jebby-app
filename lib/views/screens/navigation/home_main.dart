import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jebby/views/screens/home/filter.dart';
import 'package:jebby/views/screens/shared/chat.dart';
import 'package:jebby/constants/color.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bottom_nav_controller.dart';
import 'package:jebby/views/screens/home/featured_categories.dart';
import 'package:jebby/views/screens/home/home.dart';
import 'package:http/http.dart' as http;
import 'package:jebby/utils/api_headers.dart';

import 'package:jebby/views/screens/shared/settings.dart';
import 'package:jebby/views/screens/vendors/my_products.dart';
import 'package:jebby/views/screens/shared/notifications.dart';
import 'package:jebby/views/screens/vendors/vendor_home.dart';
import 'package:jebby/constants/app_url.dart';
import 'package:jebby/repositories/api_repository.dart';
import 'package:jebby/utils/profile_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/provider/sign_in_provider.dart';
import '../../../models/user_model.dart';
import '../../../view_models/auth_view_model.dart';
import '../../../view_models/user_view_model.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final bottomctrl = Get.put(BottomNavController());
  num activeIndex = 0;


  var screens = [
    HomeScreen(),
    FilterScreen(),
    FeaturedCategoriesScreen(),
    NotificationsScreen(),
    SettingsScreen(),
    MessagesScreen(),
  ];

  var screensVendor = [
    VendorHomeScreen(),
    MyProductsScreen(side: true),
    MyProductsScreen(side: true),
    NotificationsScreen(isVendor: true),
    SettingsScreen(),
    MessagesScreen(),
  ];

  Future<UserModel> getUserDate() => UserViewModel().getUser();
  String? ids;

  Future getData() async {
    final sp = context.read<SignInProvider>();
    sp.getDataFromSharedPreferences();
  }

  bool isNotific = true;

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

  @override
  void initState() {
    func();
    getData();
    profileData(context);
    super.initState();
  }

  @override
  void dispose() {
    cancelTimer();
    super.dispose();
  }

  void func() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("time", true);
    check();
  }

  String? token;
  String? id;
  String? fullname;
  String? email;
  String? role;

  void profileData(BuildContext context) async {
    final usp = context.read<UserViewModel>();
    usp
        .getUser()
        .then((value) async {
          token = value.token.toString();
          id = value.id.toString();
          getProductsApi(id.toString());
          fullname = value.name.toString();
          email = value.email.toString();
          role = value.role.toString();
        })
        .onError((error, stackTrace) {});
  }

  bool isLoading = true;
  bool isError = false;
  bool isEmpty = false;

  getNotifications() {
    ApiRepository.shared.notifications(
      id,
      (List) {
        if (this.mounted) {
          if (List.data!.length == 0) {
            setState(() {
              isEmpty = true;
              isLoading = false;
              isError = false;
            });
          } else {
            setState(() {
              isEmpty = false;
              isLoading = false;
              isError = false;
            });
          }
        }
      },
      (error) {
        if (error != null && mounted) {
          setState(() {
            isEmpty = false;
            isLoading = true;
            isError = true;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthViewModel>();
    final userViewModel = context.watch<UserViewModel>();
    final isProviderMode = userViewModel.isEarnMode;


    Future.delayed(const Duration(seconds: 1), () {});

    return Scaffold(
      extendBody: true,
      body: GetBuilder<BottomNavController>(
        init: bottomctrl,
        builder: (_) {
          activeIndex = bottomctrl.navigationBarIndexValue;
          return isProviderMode
              ? screensVendor[bottomctrl.navigationBarIndexValue]
              : screens[bottomctrl.navigationBarIndexValue];
        },
      ),
      bottomNavigationBar:
          isProviderMode
              ? null
              : (userViewModel.isGuestUser
                    ? bottomForGuest()
                    : bottomForUser(userName)),
    );
  }

  static const double _footerBarHeight = 64;
  static const double _footerFabSize = 60;
  static const double _footerNavIconSize = 28;
  static const double _footerLabelFontSize = 12.5;
  static const Color _footerInactive = Color(0xFFB5B5B5);
  static const Color _footerLabelActive = Color(0xFF2C2C2C);

  TextStyle _footerTextStyle(bool selected) => GoogleFonts.inter(
        fontSize: _footerLabelFontSize,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        height: 1.15,
        color: selected ? _footerLabelActive : _footerInactive,
      );

  Color _footerIconColor(bool selected) =>
      selected ? AppColors.primaryColor : _footerInactive;

  Widget _footerNavTap({
    required Widget icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 4),
            Text(label, style: _footerTextStyle(selected)),
          ],
        ),
      ),
    );
  }

  Widget _footerSearchSlot() {
    return _footerNavTap(
      icon: Image.asset(
        'assets/images/searchnew_tab.png',
        width: _footerNavIconSize,
        height: _footerNavIconSize,
        color: _footerIconColor(activeIndex == 1),
      ),
      label: 'Search',
      selected: activeIndex == 1,
      onTap: () {
        bottomctrl.navBarChange(1);
        setState(() => activeIndex = 1);
      },
    );
  }

  Widget _footerDockedFab() {
    return Material(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      color: AppColors.primaryColor,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          bottomctrl.navBarChange(2);
          setState(() => activeIndex = 2);
        },
        child: const SizedBox(
          width: _footerFabSize,
          height: _footerFabSize,
          child: Icon(
            Icons.grid_view_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget bottomForUser(userName) {
    final size = MediaQuery.sizeOf(context);
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final paintHeight = _footerBarHeight + bottomPad;

    return SizedBox(
      height: _footerBarHeight + 22 + bottomPad,
      width: size.width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: paintHeight,
            child: CustomPaint(
              painter: JebbyFooterBarPainter(),
              size: Size(size.width, paintHeight),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPad,
            height: _footerBarHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _footerNavTap(
                        icon: Image.asset(
                          'assets/images/home_footer.png',
                          width: _footerNavIconSize,
                          height: _footerNavIconSize,
                          color: _footerIconColor(activeIndex == 0),
                        ),
                        label: 'Home',
                        selected: activeIndex == 0,
                        onTap: () {
                          bottomctrl.navBarChange(0);
                          setState(() => activeIndex = 0);
                        },
                      ),
                    ),
                    Expanded(child: _footerSearchSlot()),
                    const SizedBox(width: _footerFabSize + 4),
                    Expanded(
                      child: _footerNavTap(
                        icon: Image.asset(
                          'assets/images/chaticon.png',
                          width: _footerNavIconSize,
                          height: _footerNavIconSize,
                          color: _footerIconColor(activeIndex == 5),
                        ),
                        label: 'Chat',
                        selected: activeIndex == 5,
                        onTap: () {
                          setState(() => activeIndex = 5);
                          bottomctrl.navBarChange(5);
                        },
                      ),
                    ),
                    Expanded(
                      child: _footerNavTap(
                        icon: Image.asset(
                          'assets/images/settingicon.png',
                          width: _footerNavIconSize,
                          height: _footerNavIconSize,
                          color: _footerIconColor(activeIndex == 4),
                        ),
                        label: 'Settings',
                        selected: activeIndex == 4,
                        onTap: () {
                          setState(() => activeIndex = 4);
                          bottomctrl.navBarChange(4);
                        },
                      ),
                    ),
                  ],
                ),
            ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPad + _footerBarHeight - (_footerFabSize * 0.75),
              child: Center(child: _footerDockedFab()),
            ),
          ],
        ),
    );
  }

  Widget bottomForGuest() {
    final size = MediaQuery.sizeOf(context);
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final paintHeight = _footerBarHeight + bottomPad;

    return SizedBox(
      height: _footerBarHeight + 22 + bottomPad,
      width: size.width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: paintHeight,
            child: CustomPaint(
              painter: JebbyFooterBarPainter(),
              size: Size(size.width, paintHeight),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPad,
            height: _footerBarHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                  children: [
                    Expanded(
                      child: _footerNavTap(
                        icon: Icon(
                          Icons.home_rounded,
                          size: _footerNavIconSize,
                          color: _footerIconColor(activeIndex == 0),
                        ),
                        label: 'Home',
                        selected: activeIndex == 0,
                        onTap: () {
                          bottomctrl.navBarChange(0);
                          setState(() => activeIndex = 0);
                        },
                      ),
                    ),
                    const SizedBox(width: _footerFabSize + 4),
                    Expanded(
                      child: _footerNavTap(
                        icon: Icon(
                          Icons.search_rounded,
                          size: _footerNavIconSize,
                          color: _footerIconColor(activeIndex == 1),
                        ),
                        label: 'Search',
                        selected: activeIndex == 1,
                        onTap: () {
                          bottomctrl.navBarChange(1);
                          setState(() => activeIndex = 1);
                        },
                      ),
                    ),
                  ],
              ),
            ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPad + _footerBarHeight - (_footerFabSize * 0.75),
              child: Center(child: _footerDockedFab()),
            ),
          ],
        ),
    );
  }

  var imagesapi = "";
  var nameapi = "";
  var locationapi = "";
  var emailapi = "";
  String Url = dotenv.env['baseUrlM'] ?? 'No url found';

  Future getProductsApi(String ids) async {
    final response = await http.get(
      Uri.parse('${Url}/UserProfileGetById/${ids}'),
      headers: await ApiHeaders.json(),
    );
    var data = jsonDecode(response.body.toString());

    if (data["data"].length != 0) {}

    if (data["data"].length != 0 && mounted) {
      setState(() {
        imagesapi = ProfileImage.sanitizePath(
          data["data"][0]["profile_image"]?.toString(),
        );
        nameapi = data["data"][0]["name"].toString();
        emailapi = data["data"][0]["email"].toString();
        locationapi = data["data"][0]["address"].toString();
      });
    }
    if (response.statusCode == 200) {
      SharedPreferences updatePrefrences =
          await SharedPreferences.getInstance();
      if (data["data"].length != 0 && mounted) {
        setState(() {
          updatePrefrences.setString(
            'fullname',
            data["data"][0]["name"].toString(),
          );
          updatePrefrences.setString(
            'email',
            data["data"][0]["email"].toString(),
          );
          updatePrefrences.setString(
            'profileImage',
            ProfileImage.sanitizePath(
              data["data"][0]["profile_image"]?.toString(),
            ),
          );
          updatePrefrences.setString(
            'address',
            data["data"][0]["address"].toString(),
          );
          updatePrefrences.setString(
            'latitude',
            data["data"][0]["latitude"].toString(),
          );
          updatePrefrences.setString(
            'longitude',
            data["data"][0]["longitude"].toString(),
          );
          updatePrefrences.setString(
            'phoneNumber',
            data["data"][0]['phone_number'].toString(),
          );
        });
      }

      return data;
    } else {
      return "No data";
    }
  }

  Future getCategoryList() async {
    final response = await http.get(
      Uri.parse(AppUrl.categoryGetUrl),
      headers: await ApiHeaders.json(),
    );
    var data = jsonDecode(response.body.toString());

    if (response.statusCode == 200) {
      return data;
    } else {
      return "No data";
    }
  }
}

/// White bar with a subtle top shadow and convex center bump for the docked FAB.
class JebbyFooterBarPainter extends CustomPainter {
  JebbyFooterBarPainter({
    this.topFlatY = 5,
    this.bumpPeakY = -30,
  });

  final double topFlatY;
  final double bumpPeakY;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    path.moveTo(0, topFlatY);
    path.lineTo(w * 0.36, topFlatY);
    path.quadraticBezierTo(w * 0.40, topFlatY, w * 0.44, topFlatY - 20);
    path.quadraticBezierTo(w * 0.50, bumpPeakY, w * 0.56, topFlatY - 20);
    path.quadraticBezierTo(w * 0.60, topFlatY, w * 0.64, topFlatY);
    path.lineTo(w, topFlatY);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    canvas.drawShadow(path, const Color(0x33000000), 6, false);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant JebbyFooterBarPainter oldDelegate) =>
      oldDelegate.topFlatY != topFlatY || oldDelegate.bumpPeakY != bumpPeakY;
}
