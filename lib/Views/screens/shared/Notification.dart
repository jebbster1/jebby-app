import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jebby/Services/provider/sign_in_provider.dart';
import 'package:jebby/model/getNotificationModel.dart';
import 'package:jebby/model/user_model.dart' as usermodel;
import 'package:jebby/res/app_url.dart';
import 'package:jebby/view_model/apiServices.dart';
import 'package:jebby/view_model/user_view_model.dart';
import 'package:jebby/Views/screens/shared/Chat.dart';
import 'package:jebby/Views/screens/profile/userprofile.dart';
import 'package:jebby/utils/profile_image.dart';
import 'package:jebby/Views/screens/vendors/MyOrders.dart';
import 'package:jebby/res/color.dart';
import 'package:provider/provider.dart';

/// Notifications for both renter and vendor flows. Same API; vendor sees
/// order notifications and vendor-specific order screens.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key, this.isVendor = false})
      : super(key: key);

  final bool isVendor;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String sourceId = "";
  String? profileImage;
  bool isLoading = true;
  bool isEmpty = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final sp = context.read<SignInProvider>();
    final usp = context.read<UserViewModel>();

    await usp.getUpdatedUser();
    await sp.getDataFromSharedPreferences();
    profileImage = ProfileImage.sanitizePath(
      (usp.profileImage ?? sp.imageUrl ?? '').toString(),
    );

    final usermodel.UserModel user = await usp.getUser();
    sourceId = user.id.toString();
    if (mounted) setState(() {});

    _getNotifications();
  }

  void _getNotifications() {
    ApiRepository.shared.notifications(
      sourceId,
      (data) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          isEmpty = data.data == null || data.data!.isEmpty;
        });
      },
      (error) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          isEmpty = true;
        });
      },
    );
  }

  void _seenNotification(dynamic id) {
    ApiRepository.shared.seenoneNotification(id);
  }

  List<Data> _visibleItems(List<Data> raw) {
    if (widget.isVendor) return raw;
    return raw.where((e) => e.name != "order").toList();
  }

  String _sectionLabel(DateTime date) {
    final now = DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (d == today) return "Today";
    if (d == yesterday) return "Yesterday";
    return DateFormat('MMM dd yyyy, EEEE').format(date);
  }

  List<Widget> _buildGroupedSections(List<Data> data) {
    final visible = _visibleItems(data);
    if (visible.isEmpty) return [];

    final Map<String, List<Data>> grouped = {};
    for (final item in visible) {
      final createdAtRaw = item.createdAt?.toString();
      final createdAt =
          DateTime.tryParse(createdAtRaw ?? '') ?? DateTime.now();
      final key = _sectionLabel(createdAt);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    final List<Widget> sections = [];
    grouped.forEach((sectionTitle, items) {
      sections.add(
        Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sectionTitle,
                style: TextStyle(
                  fontSize: 32 / 2,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF212121),
                  fontFamily: GoogleFonts.inter().fontFamily,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(items.length, (index) {
                final item = items[index];
                return _notificationTile(
                  item,
                  showDivider: index != items.length - 1,
                );
              }),
            ],
          ),
        ),
      );
    });
    return sections;
  }

  void _onNotificationTap(Data data) {
    final name = (data.name ?? '').toString();
    final id = data.id;
    _seenNotification(id);

    if (name == "message") {
      Get.to(() => MessagesScreen());
    } else if (name == "order" && widget.isVendor) {
      Get.to(() => OrderRequestScreen());
    }
  }

  Widget _notificationTile(Data data, {required bool showDivider}) {
    final name = (data.name ?? '').toString();
    final desc = (data.description ?? '').toString();
    final seen = data.seen.toString();
    final date = data.createdAt?.toString() ?? '';
    final formattedDate = DateFormat('hh:mm a')
        .format(DateTime.tryParse(date) ?? DateTime.now());

    return InkWell(
      onTap: () => _onNotificationTap(data),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: seen == "0"
                        ? const Color(0xFFF59D0A)
                        : const Color(0xFFF2D04F),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name.capitalizeFirst ?? '',
                              style: TextStyle(
                                fontSize: 31 / 2,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B1B1F),
                                fontFamily: GoogleFonts.inter().fontFamily,
                              ),
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: const Color(0xFF7C7C84),
                              fontSize: 26 / 2,
                              fontWeight: FontWeight.w400,
                              fontFamily: GoogleFonts.inter().fontFamily,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc,
                        style: TextStyle(
                          color: const Color(0xFF6D6D75),
                          fontSize: 16,
                          height: 1.3,
                          fontFamily: GoogleFonts.inter().fontFamily,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showDivider) ...[
              const SizedBox(height: 10),
              const Divider(
                thickness: 1,
                height: 1,
                color: Color(0xFFE2E2E8),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarProfileAction() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(() => MyProfileScreen()),
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ProfileImage.circularAvatar(
              radius: 18,
              baseUrl: AppUrl.baseUrlM,
              imagePath: profileImage,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationsData =
        ApiRepository.shared.getNotificationModelList?.data ?? [];
    final sections = _buildGroupedSections(notificationsData);
    final bool showEmpty = isLoading
        ? false
        : isEmpty || (notificationsData.isNotEmpty && sections.isEmpty);

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
        title: Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: GoogleFonts.inter().fontFamily,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
          style: IconButton.styleFrom(foregroundColor: Colors.black),
        ),
        actions: [_buildAppBarProfileAction()],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : showEmpty
              ? Center(
                  child: Text(
                    "No notifications yet",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                      fontFamily: GoogleFonts.inter().fontFamily,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  children: sections,
                ),
    );
  }
}
