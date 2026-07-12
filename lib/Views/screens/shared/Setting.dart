import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/Views/screens/agreements/JebbyAbout.dart';
import 'package:jebby/Views/screens/agreements/privacyPolicy.dart';
import 'package:jebby/Views/screens/auth/createnewpassword.dart';
import 'package:jebby/view_model/onboarding_controller.dart';
import 'package:jebby/Views/screens/profile/editprofile.dart';
import 'package:jebby/Views/support/FAQs.dart';
import 'package:jebby/Views/support/contactsupport.dart';
import 'package:jebby/Views/widgets/earn_member_banner.dart';
import 'package:jebby/res/color.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Services/provider/sign_in_provider.dart';
import '../../../model/user_model.dart';
import '../../../view_model/user_view_model.dart';
import '../agreements/termsAndConditions.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  static const Color _bgColor = Color(0xFFF2F4F7);
  static const Color _primaryOrange = Color(0xFFFFB020);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _verifiedGreen = Color(0xFF16A34A);

  bool _identityVerified = false;

  Future getData() async {
    final sp = context.read<SignInProvider>();
    sp.getDataFromSharedPreferences();
  }

  Future getProductsApi(id) async {
    try {
      final response = await http.get(
        Uri.parse('${Url}/UserProfileGetById/${id}'),
      );
      var data = jsonDecode(response.body.toString());
      datalength = data["data"].length;

      if (data["data"].length != 0) {
        if (mounted) {
          setState(() {
            imagesapi = data["data"][0]["image"].toString();
            nameapi = data["data"][0]["name"].toString();
            emailapi = data["data"][0]["email"].toString();
            isLoadingImage = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingImage = false;
          });
        }
      }

      if (response.statusCode == 200) {
        return data;
      } else {
        if (mounted) {
          setState(() {
            isLoadingImage = false;
          });
        }
        return "No data";
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoadingImage = false;
        });
      }
      return "No data";
    }
  }

  var imagesapi = "null";
  var nameapi = "null";
  var emailapi = "user email";
  var datalength;
  bool isLoadingImage = true;

  String? token;
  String? id;
  String? fullname;
  String? email;
  String? role;
  String Url = dotenv.env['baseUrlM'] ?? 'No url found';

  Future<UserModel> getUserDate() => UserViewModel().getUser();

  void profileData(BuildContext context) async {
    getUserDate()
        .then((value) async {
          token = value.token.toString();
          id = value.id.toString();
          fullname = value.name.toString();
          email = value.email.toString();
          getProductsApi(id);
          role = value.role.toString();

          final usp = context.read<UserViewModel>();
          if (usp.role != value.role.toString()) {
            usp.setRole(value.role.toString());
          }

          await _loadVerificationStatus();

          if (mounted) {
            setState(() {});
          }
        })
        .onError((error, stackTrace) {});
  }

  Future<void> _loadVerificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    var verified = prefs.getBool('identity_verified') ?? false;

    final controller = ensureOnboardingController();
    if (controller.userId.isEmpty && id != null && id!.isNotEmpty) {
      await controller.loadAndReconcile(
        userId: id!,
        name: fullname,
        email: email,
        phone: prefs.getString('phoneNumber'),
      );
    }
    if (await controller.isStripeIdentityVerified()) {
      verified = true;
    }

    if (mounted) {
      setState(() => _identityVerified = verified);
    }
  }

  @override
  void initState() {
    super.initState();
    ensureOnboardingController();
    getData();
    profileData(context);
  }

  String getText(usp, sp) {
    if (usp.name == "null") {
      if (sp.name.toString() == "null") {
        return "user name";
      } else if (sp.phoneNumber.toString() != "null") {
        return sp.phoneNumber.toString();
      } else {
        return sp.name.toString();
      }
    } else {
      if (usp.name.toString() == "") {
        return usp.phoneNumber.toString();
      } else {
        return usp.name.toString();
      }
    }
  }

  String _getEmailText(usp) {
    if (usp.email.toString() == "null" ||
        usp.email.toString().contains("Phone")) {
      return usp.phoneNumber.toString();
    }
    return usp.email.toString();
  }

  void _openChangePassword(usp) {
    final ue = usp.email.toString();
    String? pwdEmail;
    if (ue != 'null' && !ue.contains('Phone')) {
      pwdEmail = ue;
    } else if (emailapi != 'user email' && emailapi.trim().isNotEmpty) {
      pwdEmail = emailapi.trim();
    }
    if (pwdEmail == null || pwdEmail.isEmpty) {
      Get.snackbar(
        'Change Password',
        'Add or fix your email in Edit Profile before changing password.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.to(() => CreatePasswordScreen(email: pwdEmail));
  }

  void _openVerification() {
    if (_identityVerified) return;
    final controller = ensureOnboardingController();
    controller.startOrResume();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SignInProvider>();
    final usp = context.watch<UserViewModel>();
    final isProvider = usp.role == "1" || role == "1";
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    // Clear homemain footer (64px bar + 22px spacing) plus breathing room.
    const footerClearance = 86.0;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading:
            isProvider && Navigator.of(context).canPop()
                ? InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(50),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.black,
                    size: 20,
                  ),
                )
                : null,
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, footerClearance + bottomSafe),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHeader(usp, sp),
            const SizedBox(height: 24),
            if (!isProvider) _buildEarnMemberBanner(),
            if (!isProvider) const SizedBox(height: 24),
            _buildSectionHeader('ACCOUNT'),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _SettingsTileData(
                icon: Icons.person_outline,
                label: 'Edit Profile',
                onTap: () => Get.to(() => EditProfile()),
              ),
              _SettingsTileData(
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: () => _openChangePassword(usp),
              ),
              _SettingsTileData(
                icon: Icons.verified_user_outlined,
                label: 'Verification',
                trailingLabel:
                    _identityVerified ? 'Verified' : null,
                trailingLabelColor: _verifiedGreen,
                onTap: _openVerification,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('SUPPORT & INFO'),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _SettingsTileData(
                icon: Icons.info_outline,
                label: 'About App',
                onTap: () => Get.to(() => AboutScreen()),
              ),
              _SettingsTileData(
                icon: Icons.help_outline,
                label: 'FAQs',
                onTap: () => Get.to(() => const FAQs()),
              ),
              _SettingsTileData(
                icon: Icons.headset_mic_outlined,
                label: 'Support',
                onTap: () => Get.to(() => ContactSupport()),
              ),
              _SettingsTileData(
                icon: Icons.description_outlined,
                label: 'Terms & Conditions',
                onTap: () => Get.to(() => TermsAndCondition()),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('LEGAL'),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _SettingsTileData(
                icon: Icons.shield_outlined,
                label: 'Privacy Policy',
                onTap: () => Get.to(() => PrivacyPolicy()),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(usp, sp) {
    final displayName = getText(usp, sp);
    final showEmail = !displayName.contains('+');

    return Column(
      children: [
        GestureDetector(
          onTap: () => Get.to(() => EditProfile()),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              isLoadingImage
                  ? CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.grey[200],
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  )
                  : imagesapi != "null" && imagesapi.isNotEmpty
                  ? CachedNetworkImage(
                    imageUrl: "${Url}${imagesapi}",
                    imageBuilder:
                        (context, imageProvider) => CircleAvatar(
                          radius: 44,
                          backgroundImage: imageProvider,
                        ),
                    placeholder:
                        (context, url) => CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.grey[200],
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                    errorWidget:
                        (context, url, error) => CircleAvatar(
                          radius: 44,
                          backgroundImage: const AssetImage(
                            "assets/slicing/blankuser.jpeg",
                          ),
                        ),
                  )
                  : const CircleAvatar(
                    radius: 44,
                    backgroundImage: AssetImage(
                      "assets/slicing/blankuser.jpeg",
                    ),
                  ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: _primaryOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
        if (showEmail) ...[
          const SizedBox(height: 4),
          Text(
            _getEmailText(usp),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildEarnMemberBanner() {
    return GetBuilder<OnboardingController>(
      builder: (controller) {
        if (controller.isLoading || controller.state.isComplete) {
          return const SizedBox.shrink();
        }

        return EarnMemberBanner(
          onTap: () => controller.startOrResume(),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: _textSecondary,
      ),
    );
  }

  Widget _buildSettingsCard(List<_SettingsTileData> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              _SettingsTile(
                icon: item.icon,
                label: item.label,
                trailingLabel: item.trailingLabel,
                trailingLabelColor: item.trailingLabelColor,
                onTap: item.onTap,
              ),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade100,
                  indent: 68,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsTileData {
  final IconData icon;
  final String label;
  final String? trailingLabel;
  final Color? trailingLabelColor;
  final VoidCallback onTap;

  const _SettingsTileData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingLabel,
    this.trailingLabelColor,
  });
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingLabel;
  final Color? trailingLabelColor;
  final VoidCallback onTap;

  static const Color _primaryOrange = Color(0xFFFFB020);
  static const Color _iconBg = Color(0xFFFFF3E0);
  static const Color _textPrimary = Color(0xFF0F172A);

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingLabel,
    this.trailingLabelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primaryOrange, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: _textPrimary,
                  ),
                ),
              ),
              if (trailingLabel != null) ...[
                Text(
                  trailingLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: trailingLabelColor ?? _textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
