import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jebby/constants/app_preferences.dart';
import 'package:jebby/views/screens/agreements/maintenance_and_warranties.dart';
import 'package:jebby/views/screens/agreements/insurance_and_indemnifications.dart';
import 'package:jebby/views/screens/agreements/privacy_policy.dart';
import 'package:jebby/views/screens/agreements/rental_agreement.dart';
import 'package:jebby/views/screens/agreements/copyright_policy.dart';
import 'package:jebby/views/screens/agreements/termination.dart';
import 'package:jebby/views/screens/agreements/terms_and_conditions.dart';
import 'package:jebby/views/screens/agreements/transport_and_installation_policy.dart';
import 'package:jebby/views/screens/agreements/usage_policy_and_limitations.dart';
import 'package:jebby/views/screens/auth/login.dart';
import 'package:jebby/views/screens/home/favourites.dart';
import 'package:jebby/views/screens/home/my_orders.dart';
import 'package:jebby/views/screens/home/my_transactions.dart';
import 'package:jebby/views/screens/shared/chat.dart';
import 'package:jebby/views/screens/navigation/home_main.dart';
import 'package:jebby/views/screens/profile/user_profile.dart';
import 'package:jebby/views/screens/shared/settings.dart';
import 'package:jebby/views/screens/vendors/my_orders.dart';
import 'package:jebby/views/screens/vendors/my_transactions.dart';
import 'package:jebby/views/screens/vendors/vendor_home.dart';
import 'package:jebby/views/screens/onboarding/start_earning_button.dart';
import 'package:jebby/views/widgets/role_switcher_card.dart';
import 'package:jebby/utils/profile_image.dart';
import 'package:jebby/utils/show_snackbar.dart';
import 'package:jebby/views/screens/support/provide_feedback.dart';
import 'package:jebby/constants/app_url.dart';
import 'package:jebby/repositories/auth_repository.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/provider/sign_in_provider.dart';
import '../../../view_models/auth_view_model.dart';
import 'package:jebby/repositories/api_repository.dart';
import '../../../view_models/onboarding_controller.dart';
import '../../../view_models/user_view_model.dart';
import 'package:jebby/views/screens/navigation/bottom_nav_controller.dart';

class AppDrawerScreen extends StatefulWidget {
  final VoidCallback? onCloseDrawer;

  const AppDrawerScreen({super.key, this.onCloseDrawer});

  @override
  State<AppDrawerScreen> createState() => _AppDrawerScreenState();
}

class _AppDrawerScreenState extends State<AppDrawerScreen> {
  bool onboardingCompleted = false;

  final _myRepo = AuthRepository();

  Future<void> _refreshDrawerState() async {
    if (!mounted) return;

    final sp = context.read<SignInProvider>();
    sp.getDataFromSharedPreferences();

    final usp = context.read<UserViewModel>();
    final user = await usp.getUser();

    token = user.token.toString();
    id = user.id.toString();
    fullname = user.name.toString();
    email = user.email.toString();
    role = user.role.toString();
    if (id != null && id!.isNotEmpty) {
      getProductsApi(id!);
    }
    await _loadOnboardingController();

    if (mounted) setState(() {});
  }

  Future<void> _loadOnboardingController() async {
    final userId = id;
    if (userId == null || userId.isEmpty) return;

    final controller = ensureOnboardingController();
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('phoneNumber');

    await controller.loadAndReconcile(
      userId: userId,
      name: fullname,
      email: email,
      phone: phone,
    );

    if (mounted) {
      setState(() {
        onboardingCompleted = prefs.getBool('is_identity_verified') ?? false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    ensureOnboardingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDrawerState();
      _loadOnboardingStatus();
    });
  }

  String? token;
  String? id;
  String? fullname;
  String? email;
  String? role;
  String Url = AppUrl.baseUrlM;

  void _loadOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool newOnboardingCompleted =
        prefs.getBool('is_identity_verified') ?? false;

    setState(() {
      onboardingCompleted = newOnboardingCompleted;
    });
  }

  bool _roleSwitchInProgress = false;

  Future<void> _switchRole(BuildContext context, {required bool toEarn}) async {
    final usp = context.read<UserViewModel>();
    final sp = context.read<SignInProvider>();
    final currentIsEarn = usp.isEarnMode;
    if (currentIsEarn == toEarn || _roleSwitchInProgress) return;

    setState(() => _roleSwitchInProgress = true);
    final role = toEarn ? "1" : "0";

    try {
      final response = await _myRepo.updateRoleApi({
        "role": role,
        "email": usp.email ?? sp.email,
      });
      final status = response["status"];
      final succeeded = status == 200 ||
          status == '200' ||
          response['message']
                  ?.toString()
                  .toLowerCase()
                  .contains('updated successfully') ==
              true;

      if (succeeded) {
        final sharedPreferences = await SharedPreferences.getInstance();
        await sharedPreferences.setString('role', role);
        usp.setRole(role);
        showAppSnackbar(
          'Mode switched',
          toEarn ? 'Switched to Earn Mode' : 'Switched to Rent Mode',
        );
        if (toEarn) {
          Get.offAll(() => const VendorHomeScreen());
        } else {
          Get.offAll(() => const MainScreen());
        }
      } else {
        showAppErrorSnackbar(
          response['message']?.toString() ?? 'Could not switch mode',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        print("Error updating role: $error");
      }
      showAppErrorSnackbar('Could not switch mode. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _roleSwitchInProgress = false);
      }
    }
  }

  Widget _buildRoleModeSection(UserViewModel usp, double resWidth) {
    if (!usp.isEarnMode && !onboardingCompleted) {
      return const StartEarningButton();
    }
    return SizedBox(
      width: resWidth * 0.75,
      child: RoleSwitcherCard(
        isEarnMode: usp.isEarnMode,
        isLoading: _roleSwitchInProgress,
        onModeChanged: (toEarn) => _switchRole(context, toEarn: toEarn),
      ),
    );
  }

  final bottomctrl = Get.put(BottomNavController());

  void _openProviderChat(BuildContext context) {
    Navigator.of(context).pop();
    Get.to(() => const MessagesScreen(showBackButton: true));
  }

  void _openRenterChat(BuildContext context) {
    bottomctrl.navBarChange(5);
    Navigator.of(context).pop();
  }

  /// Space below drawer items so Logout/Settings clear the home footer bar.
  double _drawerBottomSpacing(BuildContext context) {
    const footerClearance = 48.0;
    const extraPadding = 8.0;
    return MediaQuery.paddingOf(context).bottom + footerClearance + extraPadding;
  }

  Widget _drawerMenuRow({
    required double resWidth,
    required double textScaleFactor,
    required String label,
    required VoidCallback onTap,
    String iconAsset = 'assets/images/menu-board.png',
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: resWidth * 0.75,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5, left: 10),
          child: Row(
            children: [
              Image.asset(
                iconAsset,
                color: Colors.black,
                width: 20,
                height: 20,
              ),
              SizedBox(width: 20),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 15 * textScaleFactor,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerSectionTitle(
    String title,
    double resWidth,
    double resHeight,
    double textScaleFactor,
  ) {
    return Container(
      width: resWidth * 0.7,
      height: resHeight * 0.059,
      child: Row(
        children: [
          Text(
            title,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 15 * textScaleFactor,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSupportFeedbackSection(
    double resWidth,
    double resHeight,
    double textScaleFactor,
  ) {
    return [
      Container(
        width: resWidth * 0.7,
        child: Divider(color: Colors.grey.shade300),
      ),
      _drawerSectionTitle('Support', resWidth, resHeight, textScaleFactor),
      SizedBox(height: 15),
      _drawerMenuRow(
        resWidth: resWidth,
        textScaleFactor: textScaleFactor,
        label: 'Provide Feedback',
        iconAsset: 'assets/images/message-text.png',
        onTap: () => Get.to(() => const ProvideFeedbackScreen()),
      ),
      SizedBox(height: 15),
    ];
  }

  List<Widget> _buildLegalMenuSection(
    double resWidth,
    double resHeight,
    double textScaleFactor, {
    bool showTopDivider = false,
  }) {
    final legalItems = <MapEntry<String, VoidCallback>>[
      MapEntry('Terms & Conditions', () => Get.to(() => TermsAndConditionsScreen())),
      MapEntry('Privacy Policy', () => Get.to(() => PrivacyPolicyScreen())),
      MapEntry('Copyright Policy', () => Get.to(CopyrightPolicyScreen())),
      MapEntry('Rental Agreement', () => Get.to(RentalAgreementScreen())),
      MapEntry(
        'Usage Policy & Limitations',
        () => Get.to(UsagePolicyAndLimitationsScreen()),
      ),
      MapEntry(
        'Insurance & Indemnifications Policy',
        () => Get.to(InsuranceAndIndemnificationsScreen()),
      ),
      MapEntry(
        'Transportation & Installation Policy',
        () => Get.to(TransportAndInstallationPolicyScreen()),
      ),
      MapEntry(
        'Maintenance & Warranties',
        () => Get.to(() => const MaintenanceAndWarrantiesScreen()),
      ),
      MapEntry('Termination', () => Get.to(TerminationScreen())),
    ];

    return [
      if (showTopDivider) ...[
        SizedBox(height: 10),
        Container(
          width: resWidth * 0.7,
          child: Divider(color: Colors.grey.shade300),
        ),
      ],
      _drawerSectionTitle('Legal', resWidth, resHeight, textScaleFactor),
      SizedBox(height: 15),
      for (var i = 0; i < legalItems.length; i++) ...[
        _drawerMenuRow(
          resWidth: resWidth,
          textScaleFactor: textScaleFactor,
          label: legalItems[i].key,
          onTap: legalItems[i].value,
        ),
        if (i < legalItems.length - 1) SizedBox(height: 25),
      ],
      SizedBox(height: 15),
    ];
  }

  Widget _buildSettingsMenuItem(double resWidth, double textScaleFactor) {
    return Column(
      children: [
        Container(
          width: resWidth * 0.7,
          child: Divider(color: Colors.grey.shade300),
        ),
        SizedBox(height: 15),
        _drawerMenuRow(
          resWidth: resWidth,
          textScaleFactor: textScaleFactor,
          label: 'Settings',
          iconAsset: 'assets/images/setting-2.png',
          onTap: () {
            Get.back();
            widget.onCloseDrawer?.call();
            Get.to(() => const SettingsScreen(showBackButton: true));
          },
        ),
        SizedBox(height: 25),
      ],
    );
  }

  Future<void> _clearSessionAndNavigateToLogin(SignInProvider sp) async {
    final userPreference = context.read<UserViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState?.isDrawerOpen ?? false) {
      scaffoldState!.closeDrawer();
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences.setBool('time', false);
      await userPreference.remove();
      authViewModel.userName = '';
      await sharedPreferences.clear();
      await AppPreferences.restoreRenterGetStartedFlag();
      try {
        await sp.userSignOut();
      } catch (_) {
        try {
          await sp.clearStoredData();
        } catch (_) {}
      }
    } catch (_) {
      // Still navigate to login even if cleanup partially fails.
    } finally {
      notiTimer().cancelTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAll(() => const LoginScreen());
      });
    }
  }

  Future<void> _performFullLogout(SignInProvider sp) async {
    await _clearSessionAndNavigateToLogin(sp);
  }

  Future<void> _performGuestLogout(SignInProvider sp) async {
    await _clearSessionAndNavigateToLogin(sp);
  }

  Widget _buildLogoutMenuItem(
    double resWidth,
    double textScaleFactor,
    SignInProvider sp, {
    required bool fullClear,
  }) {
    return _drawerMenuRow(
      resWidth: resWidth,
      textScaleFactor: textScaleFactor,
      label: 'Logout',
      iconAsset: 'assets/images/logout.png',
      onTap: () async {
        try {
          if (fullClear) {
            await _performFullLogout(sp);
          } else {
            await _performGuestLogout(sp);
          }
        } catch (e) {
          if (kDebugMode) {}
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Refresh onboarding status when drawer is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOnboardingStatus();
    });

    final usp = context.watch<UserViewModel>();
    final isGuest =
        usp.isGuestUser ||
        fullname == 'Guest' ||
        role == 'Guest';

    double res_width = MediaQuery.of(context).size.width;
    double res_height = MediaQuery.of(context).size.height;
    double baseWidth = 428;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body:
          isGuest
              ? getGuestDrawer(res_width, res_height, ffem)
              : getNormalDrawer(res_width, res_height, ffem),
    );
  }

  Widget getGuestDrawer(double res_width, double res_height, double ffem) {
    final sp = context.watch<SignInProvider>();
    final usp = context.watch<UserViewModel>();
    final textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);

    return Container(
      width: res_width * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: res_height * 0.06),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => Get.back(),
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.asset(
                          'assets/images/close-circle.png',
                          color: Colors.black,
                          width: 30,
                          height: 30,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 0),
                  Padding(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ProfileImage.circularAvatar(
                          radius: 40,
                          baseUrl: Url,
                          imagePath: _drawerAvatarPath(usp),
                          isLoading: _drawerAvatarLoading(usp),
                        ),
                        SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guest',
                              style: TextStyle(
                                fontSize: 26 * textScaleFactor,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Browse without signing in',
                              style: TextStyle(
                                fontSize: 15 * textScaleFactor,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: res_height * 0.04),
              GestureDetector(
                onTap: () {
                  if (bottomctrl.navigationBarIndexValue != 0) {
                    bottomctrl.navBarChange(0);
                  } else {
                    Get.back();
                  }
                },
                child: Container(
                  width: res_width * 0.75,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 5, left: 10),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/images/home.png',
                          color: Colors.black,
                          width: 20,
                          height: 20,
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            "Home",
                            style: TextStyle(
                              fontSize: 15 * textScaleFactor,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ..._buildLegalMenuSection(
                res_width,
                res_height,
                textScaleFactor,
                showTopDivider: true,
              ),
              Container(
                width: res_width * 0.7,
                child: Divider(color: Colors.grey.shade300),
              ),
              SizedBox(height: 15),
              _buildLogoutMenuItem(
                res_width,
                textScaleFactor,
                sp,
                fullClear: false,
              ),
              SizedBox(height: _drawerBottomSpacing(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget getNormalDrawer(double res_width, double res_height, double ffem) {
    final sp = context.watch<SignInProvider>();
    final usp = context.watch<UserViewModel>();
    // Retrieve the current text scale factor from the MediaQuery
    final textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);

    return Container(
      width: res_width * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: SingleChildScrollView(
        child:
            usp.isEarnMode
                ? Padding(
                  padding: const EdgeInsets.only(left: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: res_height * 0.06),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: () {
                                Get.back();
                                widget.onCloseDrawer?.call();
                              },
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.asset(
                                  'assets/images/close-circle.png',
                                  color: Colors.black,
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileImage.circularAvatar(
                            radius: 40,
                            baseUrl: Url,
                            imagePath: _drawerAvatarPath(usp),
                            isLoading: _drawerAvatarLoading(usp),
                          ),
                          SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: res_width * 0.55,
                                child: Text(
                                  getText(usp, sp),
                                  style: TextStyle(
                                    fontSize: 26 * textScaleFactor,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Builder(
                                builder: (_) {
                                  final email = UserViewModel.displayEmail(
                                    usp.email,
                                  );
                                  if (email == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return SizedBox(
                                    width: res_width * 0.55,
                                    child: Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: 15 * textScaleFactor,
                                        color: Colors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildRoleModeSection(usp, res_width),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          if (bottomctrl.navigationBarIndexValue != 0) {
                            bottomctrl.navBarChange(0);
                          } else {
                            Get.back();
                            widget.onCloseDrawer?.call();
                          }
                        },
                        child: Container(
                          width: res_width * 0.75,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5, left: 10),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/home.png',
                                  color: Colors.black,
                                  width: 20,
                                  height: 20,
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    "Home",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 15 * textScaleFactor,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: res_width * 0.7,
                        child: Divider(color: Colors.grey.shade300),
                      ),
                      Container(
                        width: res_width * 0.7,
                        height: res_height * 0.059,
                        child: Row(
                          children: [
                            Text(
                              "Account",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 15 * textScaleFactor,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Get.to(() => UserProfileScreen());
                        },
                        child: Container(
                          width: res_width * 0.75,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5, left: 10),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/frame.png',
                                  color: Colors.black,
                                  width: 20,
                                  height: 20,
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    "Profile",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 15 * textScaleFactor,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 25),
                      GestureDetector(
                        onTap: () {
                          _openProviderChat(context);
                        },
                        child: Container(
                          width: res_width * 0.75,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5, left: 10),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/messages.png',
                                  color: Colors.black,
                                  width: 20,
                                  height: 20,
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    "Chat",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 15 * textScaleFactor,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 25),
                      GestureDetector(
                        onTap: () {
                          Get.to(const VendorMyOrdersScreen());
                        },
                        child: Container(
                          width: res_width * 0.75,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5, left: 10),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/book.png',
                                  color: Colors.black,
                                  width: 20,
                                  height: 20,
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    "My Orders",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 15 * textScaleFactor,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 25),
                      GestureDetector(
                        onTap: () {
                          Get.to(VendorMyTransactionsScreen());
                        },
                        child: Container(
                          width: res_width * 0.75,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5, left: 10),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/dollar-circle.png',
                                  color: Colors.black,
                                  width: 20,
                                  height: 20,
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    "My Transactions",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 15 * textScaleFactor,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      ..._buildSupportFeedbackSection(
                        res_width,
                        res_height,
                        textScaleFactor,
                      ),
                      ..._buildLegalMenuSection(
                        res_width,
                        res_height,
                        textScaleFactor,
                      ),
                      _buildSettingsMenuItem(res_width, textScaleFactor),
                      _buildLogoutMenuItem(
                        res_width,
                        textScaleFactor,
                        sp,
                        fullClear: true,
                      ),
                      SizedBox(height: _drawerBottomSpacing(context)),
                    ],
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.only(left: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: res_height * 0.06),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: () {
                                Get.back();
                              },
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.asset(
                                  'assets/images/close-circle.png',
                                  color: Colors.black,
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 20),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileImage.circularAvatar(
                            radius: 40,
                            baseUrl: Url,
                            imagePath: _drawerAvatarPath(usp),
                            isLoading: _drawerAvatarLoading(usp),
                          ),
                          SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: res_width * 0.55,
                                child: Text(
                                  getText(usp, sp),
                                  style: TextStyle(
                                    fontSize: 26 * textScaleFactor,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Builder(
                                builder: (_) {
                                  final email = UserViewModel.displayEmail(
                                    usp.email,
                                  );
                                  if (email == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return SizedBox(
                                    width: res_width * 0.55,
                                    child: Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: 15 * textScaleFactor,
                                        color: Colors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildRoleModeSection(usp, res_width),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () {
                          if (bottomctrl.navigationBarIndexValue != 0) {
                            bottomctrl.navBarChange(0);
                          } else {
                            Get.back();
                            widget.onCloseDrawer?.call();
                          }
                        },
                        child: Container(
                          width: res_width * 0.75,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10, bottom: 5),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/home.png',
                                  color: Colors.black,
                                  width: 20,
                                  height: 20,
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    "Home",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 15 * textScaleFactor,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: res_width * 0.7,
                        child: Divider(color: Colors.grey.shade300),
                      ),
                      Container(
                        width: res_width * 0.7,
                        height: res_height * 0.059,
                        child: Row(
                          children: [
                            Text(
                              "Account",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 15 * textScaleFactor,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Get.to(() => UserProfileScreen());
                        },
                        child: Container(
                          width: res_width * 0.75,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5, left: 10),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/frame.png',
                                  color: Colors.black,
                                  width: 20,
                                  height: 20,
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    "Profile",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 15 * textScaleFactor,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 25),

                      GestureDetector(
                        onTap: () {
                          _openRenterChat(context);
                        },
                        child: Container(
                          width: res_width * 0.75,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5, left: 10),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/messages.png',
                                  color: Colors.black,
                                  width: 20,
                                  height: 20,
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    "Chat",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 15 * textScaleFactor,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 25),
                      GestureDetector(
                        onTap: () {
                          Get.to(() => MyOrdersScreen());
                        },
                        child: Container(
                          width: res_width * 0.75,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5, left: 10),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/book.png',
                                  color: Colors.black,
                                  width: 20,
                                  height: 20,
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    "My Orders",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 15 * textScaleFactor,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 25),
                      GestureDetector(
                        onTap: () {
                          Get.to(() => FavouritesScreen());
                        },
                        child: Container(
                          width: res_width * 0.75,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5, left: 10),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/heart-edit.png',
                                  color: Colors.black,
                                  width: 20,
                                  height: 20,
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    "My Wishlist",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 15 * textScaleFactor,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 25),
                      GestureDetector(
                        onTap: () {
                          Get.to(() => MyTransactionsScreen());
                        },
                        child: Container(
                          width: res_width * 0.75,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5, left: 10),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/dollar-circle.png',
                                  color: Colors.black,
                                  width: 20,
                                  height: 20,
                                ),
                                SizedBox(width: 20),
                                Expanded(
                                  child: Text(
                                    "My Transactions",
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 15 * textScaleFactor,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 15),
                      ..._buildSupportFeedbackSection(
                        res_width,
                        res_height,
                        textScaleFactor,
                      ),
                      ..._buildLegalMenuSection(
                        res_width,
                        res_height,
                        textScaleFactor,
                      ),
                      _buildSettingsMenuItem(res_width, textScaleFactor),
                      _buildLogoutMenuItem(
                        res_width,
                        textScaleFactor,
                        sp,
                        fullClear: true,
                      ),
                      SizedBox(height: _drawerBottomSpacing(context)),
                    ],
                  ),
                ),
      ),
    );
  }

  var imagesapi = "";
  bool isLoadingImage = true;

  String _drawerAvatarPath(UserViewModel usp) {
    if (ProfileImage.isValidPath(usp.profileImage)) {
      return usp.profileImage!;
    }
    return imagesapi;
  }

  bool _drawerAvatarLoading(UserViewModel usp) {
    return isLoadingImage && !ProfileImage.isValidPath(usp.profileImage);
  }

  Future getProductsApi(id) async {
    try {
      final row = await ApiRepository.shared.fetchUserProfileRow(id.toString());
      if (row == null) {
        if (mounted) setState(() => isLoadingImage = false);
        return "No data";
      }

      if (mounted) {
        setState(() {
          imagesapi = ProfileImage.sanitizePath(row['profile_image']?.toString());
          isLoadingImage = false;
        });
      }
      return {'data': [row]};
    } catch (error) {
      if (mounted) setState(() => isLoadingImage = false);
      return "No data";
    }
  }
}

String getText(usp, sp) {
  if (usp.isGuestUser) {
    return 'Guest';
  }
  final uspName = usp.name?.toString().trim() ?? '';
  if (uspName.isNotEmpty && uspName != 'null') {
    return uspName;
  }
  final spName = sp.name?.toString().trim() ?? '';
  if (spName.isNotEmpty && spName != 'null') {
    return spName;
  }
  final phone = sp.phoneNumber?.toString().trim() ?? '';
  if (phone.isNotEmpty && phone != 'null') {
    return phone;
  }
  return '';
}
