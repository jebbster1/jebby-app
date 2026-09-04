import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jebby/utils/api_headers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/views/screens/agreements/jebby_about.dart';
import 'package:jebby/views/screens/agreements/privacy_policy.dart';
import 'package:jebby/view_models/auth_view_model.dart';
import 'package:jebby/view_models/onboarding_controller.dart';
import 'package:jebby/utils/profile_image.dart';
import 'package:jebby/utils/show_snackbar.dart';
import 'package:jebby/views/screens/profile/edit_profile.dart';
import 'package:jebby/views/screens/support/faqs.dart';
import 'package:jebby/views/screens/support/contact_support.dart';
import 'package:jebby/views/widgets/earn_member_banner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/provider/sign_in_provider.dart';
import '../../../models/user_model.dart';
import '../../../view_models/user_view_model.dart';
import '../agreements/terms_and_conditions.dart';

class SettingsScreen extends StatefulWidget {
  /// When true (drawer push), shows a back button. Null/false for bottom nav tab.
  final bool? showBackButton;

  const SettingsScreen({Key? key, this.showBackButton}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
        headers: await ApiHeaders.json(),
      );
      var data = jsonDecode(response.body.toString());
      datalength = data["data"].length;

      if (data["data"].length != 0) {
        if (mounted) {
          setState(() {
            imagesapi = ProfileImage.sanitizePath(
              data["data"][0]["profile_image"]?.toString(),
            );
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

  var imagesapi = "";
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
          await usp.getUser();

          await _loadVerificationStatus();

          if (mounted) {
            setState(() {});
          }
        })
        .onError((error, stackTrace) {});
  }

  Future<void> _loadVerificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    var verified = prefs.getBool('is_identity_verified') ?? false;

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
    final uspName = usp.name?.toString().trim() ?? '';
    if (uspName.isNotEmpty) {
      return uspName;
    }
    final spName = sp.name?.toString().trim() ?? '';
    if (spName.isNotEmpty) {
      return spName;
    }
    final phone = sp.phoneNumber?.toString().trim() ?? '';
    if (phone.isNotEmpty) {
      return phone;
    }
    return "user name";
  }

  String _getEmailText(usp) {
    return usp.email.toString().trim();
  }

  void _openChangePassword(usp) {
    if (context.read<AuthViewModel>().signUpLoading) return;

    if (UserViewModel.isSocialAuthSource(usp.source)) {
      showAppSnackbar(
        'Change Password',
        UserViewModel.socialAuthPasswordMessage(usp.source),
      );
      return;
    }

    final ue = usp.email.toString().trim();
    String? pwdEmail;
    if (ue.isNotEmpty) {
      pwdEmail = ue;
    } else if (emailapi != 'user email' && emailapi.trim().isNotEmpty) {
      pwdEmail = emailapi.trim();
    }
    if (pwdEmail == null || pwdEmail.isEmpty) {
      showAppSnackbar(
        'Change Password',
        'Add or fix your email in Edit Profile before changing password.',
      );
      return;
    }
    context.read<AuthViewModel>().forgetPasswordApi(
      {'email': pwdEmail},
      context,
      'forgot',
    );
  }

  void _openVerification() {
    if (_identityVerified) return;
    final controller = ensureOnboardingController();
    controller.startOrResume();
  }

  Future<void> _openAccountDeletionRequest(usp, sp) async {
    if (context.read<AuthViewModel>().accountDeletionLoading) return;

    final userRole = usp.role?.toString() ?? role ?? '';
    if (userRole == 'Guest') {
      showAppSnackbar(
        'Account Deletion',
        'Please sign in to request account deletion.',
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final contactNumber =
        (usp.phoneNumber?.toString().trim().isNotEmpty == true
                ? usp.phoneNumber.toString()
                : prefs.getString('phoneNumber'))
            ?.trim() ??
        '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Request account deletion?',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _textPrimary,
            ),
          ),
          content: Text(
            'This submits a request for our team to review. Your account is not deleted immediately.',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: _textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Submit request',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await context.read<AuthViewModel>().requestAccountDeletion(
      context: context,
      contactNumber: contactNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SignInProvider>();
    final usp = context.watch<UserViewModel>();
    final auth = context.watch<AuthViewModel>();
    final isProvider = usp.role == "1" || role == "1";
    final isSocialAccount = UserViewModel.isSocialAuthSource(usp.source);
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
            (widget.showBackButton ?? false)
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
                onTap: () => Get.to(() => EditProfileScreen()),
              ),
              if (!isSocialAccount)
                _SettingsTileData(
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  isLoading: auth.signUpLoading,
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
              if (usp.role != 'Guest' && role != 'Guest')
                _SettingsTileData(
                  icon: Icons.delete_outline,
                  label: 'Request Account Deletion',
                  isLoading: auth.accountDeletionLoading,
                  onTap: () => _openAccountDeletionRequest(usp, sp),
                ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('SUPPORT & INFO'),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _SettingsTileData(
                icon: Icons.info_outline,
                label: 'About App',
                onTap: () => Get.to(() => JebbyAboutScreen()),
              ),
              _SettingsTileData(
                icon: Icons.help_outline,
                label: 'FAQs',
                onTap: () => Get.to(() => const FaqsScreen()),
              ),
              _SettingsTileData(
                icon: Icons.headset_mic_outlined,
                label: 'Support',
                onTap: () => Get.to(() => ContactSupportScreen()),
              ),
              _SettingsTileData(
                icon: Icons.description_outlined,
                label: 'Terms & Conditions',
                onTap: () => Get.to(() => TermsAndConditionsScreen()),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('LEGAL'),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _SettingsTileData(
                icon: Icons.shield_outlined,
                label: 'Privacy Policy',
                onTap: () => Get.to(() => PrivacyPolicyScreen()),
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
          onTap: () => Get.to(() => EditProfileScreen()),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ProfileImage.circularAvatar(
                radius: 44,
                baseUrl: Url,
                imagePath: imagesapi,
                isLoading: isLoadingImage,
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
                isLoading: item.isLoading,
                onTap: item.isLoading ? null : item.onTap,
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
  final bool isLoading;
  final VoidCallback onTap;

  const _SettingsTileData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingLabel,
    this.trailingLabelColor,
    this.isLoading = false,
  });
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingLabel;
  final Color? trailingLabelColor;
  final bool isLoading;
  final VoidCallback? onTap;

  static const Color _primaryOrange = Color(0xFFFFB020);
  static const Color _iconBg = Color(0xFFFFF3E0);
  static const Color _textPrimary = Color(0xFF0F172A);

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailingLabel,
    this.trailingLabelColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: disabled ? 0.55 : 1,
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
                if (isLoading)
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primaryOrange,
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
