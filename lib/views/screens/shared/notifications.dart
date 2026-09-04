import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:jebby/services/provider/sign_in_provider.dart';
import 'package:jebby/models/get_notification_model.dart';
import 'package:jebby/models/user_model.dart' as usermodel;
import 'package:jebby/constants/app_url.dart';
import 'package:jebby/repositories/api_repository.dart';
import 'package:jebby/view_models/user_view_model.dart';
import 'package:jebby/views/screens/shared/chat.dart';
import 'package:jebby/views/screens/profile/user_profile.dart';
import 'package:jebby/utils/profile_image.dart';
import 'package:jebby/utils/api_datetime.dart';
import 'package:jebby/views/screens/vendors/my_orders.dart';
import 'package:jebby/views/screens/reservations/reservation_detail.dart';
import 'package:jebby/constants/color.dart';
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
    return raw.where((e) {
      final name = (e.name ?? '').toString().toLowerCase();
      return name != 'order';
    }).toList();
  }

  String _notificationTitle(String? name) {
    final normalized = (name ?? '').toString().trim().toLowerCase();
    switch (normalized) {
      case 'booking_requested':
      case 'booking_request':
        return 'Booking requested';
      case 'booking_accepted':
        return 'Booking accepted';
      case 'booking_declined':
        return 'Booking declined';
      case 'booking_cancelled':
        return 'Booking cancelled';
      case 'payment_confirmed':
        return 'Payment confirmed';
      case 'return_window_open':
        return 'Return window open';
      case 'dispute_reported':
        return 'Dispute reported';
      case 'payout_released':
        return 'Payout released';
      default:
        return name?.capitalizeFirst ?? '';
    }
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
      final createdAt =
          parseApiDateTime(item.createdAt?.toString()) ?? DateTime.now();
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

    final orderId = data.orderId;
    if (orderId != null) {
      Get.to(() => ReservationDetailScreen(orderId: orderId));
      return;
    }

    if (name == "message") {
      Get.to(() => MessagesScreen());
    } else if (name == "order" && widget.isVendor) {
      Get.to(() => VendorMyOrdersScreen());
    } else if ((name == 'booking_request' || name == 'booking_requested') && widget.isVendor) {
      Get.to(() => VendorMyOrdersScreen());
    }
  }

  Widget _notificationTile(Data data, {required bool showDivider}) {
    final name = (data.name ?? '').toString();
    final desc = (data.description ?? '').toString();
    final seen = data.seen.toString();
    final formattedDate = formatApiTime(data.createdAt?.toString());

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
                              _notificationTitle(name),
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
          onTap: () => Get.to(() => UserProfileScreen()),
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
