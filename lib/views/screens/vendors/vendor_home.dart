import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:jebby/utils/api_headers.dart';
import 'package:jebby/utils/api_datetime.dart';
import 'package:jebby/utils/profile_image.dart';
import 'package:jebby/constants/color.dart';
import 'package:jebby/views/screens/navigation/app_drawer.dart';
import 'package:jebby/views/screens/vendors/my_orders.dart';
import 'package:jebby/views/screens/vendors/my_products.dart';
import 'package:jebby/views/widgets/reservation_action_card.dart';
import 'package:jebby/views/screens/shared/notifications.dart';
import 'package:jebby/views/screens/profile/user_profile.dart';
import 'package:jebby/views/screens/vendors/my_transactions.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/provider/sign_in_provider.dart';
import '../../../utils/order_status.dart';
import '../../../models/user_model.dart';
import 'package:jebby/repositories/api_repository.dart';
import '../../../view_models/user_view_model.dart';

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({Key? key}) : super(key: key);

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  Future<void> getData() async {
    final sp = context.read<SignInProvider>();
    final usp = context.read<UserViewModel>();
    await usp.getUser();
    sp.getDataFromSharedPreferences();
  }

  Future<UserModel> getUserDate() => UserViewModel().getUser();

  String? token;
  String sourceId = "";
  String? fullname;
  String? email;
  String? role;
  String? profileAddress;
  String? profileImage;
  double averageRating = 0;
  int totalReviews = 0;
  String Url = dotenv.env['baseUrlM'] ?? '';

  void profileData(BuildContext context) async {
    getUserDate()
        .then((value) async {
          token = value.token.toString();
          sourceId = value.id.toString();
          fullname = value.name.toString();
          email = value.email.toString();
          role = value.role.toString();
          getProductsApi(sourceId);
          _fetchReviews(sourceId);
          getTodayTransactions();
          getNotifications();
        })
        .onError((error, stackTrace) {
          if (kDebugMode) {}
        });
  }

  Future getProductsApi(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$Url/UserProfileGetById/$id'),
        headers: await ApiHeaders.json(),
      );
      var data = jsonDecode(response.body.toString());
      if (data["data"] != null &&
          data["data"] is List &&
          (data["data"] as List).isNotEmpty) {
        final profile = data["data"][0];
        final apiAddress = profile["address"]?.toString() ?? "";
        final apiImage = ProfileImage.sanitizePath(
          profile["profile_image"]?.toString(),
        );
        final apiName = profile["name"]?.toString() ?? "";
        if (mounted) {
          setState(() {
            profileAddress = apiAddress;
            profileImage = apiImage;
            if (apiName.isNotEmpty) fullname = apiName;
          });
        }
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('address', apiAddress);
        prefs.setString('profileImage', apiImage);
        if (apiName.isNotEmpty) prefs.setString('fullname', apiName);
      }
    } catch (e) {
      if (kDebugMode) {}
    }
  }

  Widget _buildProfileAvatar() {
    final sp = context.read<SignInProvider>();
    final hasApiImage = ProfileImage.isValidPath(profileImage);
    final imageUrl =
        hasApiImage
            ? (profileImage!.startsWith('http')
                ? profileImage!
                : '${Url}${profileImage!.startsWith('/') ? '' : '/'}$profileImage')
            : null;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 38,
        backgroundColor: Colors.white,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          imageBuilder:
              (context, imageProvider) =>
                  CircleAvatar(radius: 36, backgroundImage: imageProvider),
          placeholder:
              (context, url) => CircleAvatar(
                radius: 36,
                backgroundColor: Colors.grey.shade200,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                ),
              ),
          errorWidget:
              (context, url, error) => CircleAvatar(
                radius: 36,
                backgroundColor: Colors.grey.shade200,
                child: Icon(Icons.person, size: 44, color: Colors.grey),
              ),
        ),
      );
    }
    if (sp.imageUrl != null && sp.imageUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 38,
        backgroundColor: Colors.white,
        child: CachedNetworkImage(
          imageUrl: sp.imageUrl!,
          imageBuilder:
              (context, imageProvider) =>
                  CircleAvatar(radius: 36, backgroundImage: imageProvider),
          placeholder:
              (context, url) => CircleAvatar(
                radius: 36,
                backgroundColor: Colors.grey.shade200,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryColor,
                ),
              ),
          errorWidget:
              (context, url, error) => CircleAvatar(
                radius: 36,
                backgroundColor: Colors.grey.shade200,
                child: Icon(Icons.person, size: 44, color: Colors.grey),
              ),
        ),
      );
    }
    return CircleAvatar(
      radius: 38,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 36,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 44, color: Colors.grey),
      ),
    );
  }

  void _fetchReviews(String id) {
    ApiRepository.shared.reviewsByVendorId(id, (reviewsData) {
      if (!mounted) return;
      final reviews = reviewsData.data ?? [];
      if (reviews.isEmpty) {
        setState(() {
          averageRating = 0;
          totalReviews = reviewsData.totalreviews ?? 0;
        });
        return;
      }
      double sum = 0;
      for (var r in reviews) {
        sum += (r.stars ?? 0).toDouble();
      }
      setState(() {
        averageRating = sum / reviews.length;
        totalReviews = reviewsData.totalreviews ?? reviews.length;
      });
    }, (error) {});
  }

  Widget profileCard() {
    return GestureDetector(
      onTap: () async {
        await Get.to(() => UserProfileScreen());
        if (mounted) profileData(context);
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFFFBA104),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "My Profile",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 28,
                  weight: 700,
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullname ?? "Loading...",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              (profileAddress == null ||
                                      profileAddress!.trim().isEmpty)
                                  ? "Add your address"
                                  : profileAddress!,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: averageRating,
                            itemBuilder:
                                (context, index) => Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 18,
                                ),
                            itemCount: 5,
                            itemSize: 18,
                            direction: Axis.horizontal,
                            unratedColor: Colors.white.withOpacity(0.3),
                          ),
                          SizedBox(width: 6),
                          Text(
                            "($totalReviews Reviews)",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                _buildProfileAvatar(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  seenNotification() {
    ApiRepository.shared.seenNotification(sourceId);
  }

  bool isLoading1 = true;
  bool isError1 = false;
  bool isEmpty1 = false;
  bool isTodayLoading = true;
  bool isTodayError = false;

  getNotifications() {
    ApiRepository.shared.notifications(
      sourceId,
      (List) {
        if (this.mounted) {
          if (List.data!.length == 0) {
            setState(() {
              isEmpty1 = true;
              isLoading1 = false;
              isError1 = false;
            });
          } else {
            setState(() {
              isEmpty1 = false;
              isLoading1 = false;
              isError1 = false;
            });
          }
        }
      },
      (error) {
        if (error != null) {
          setState(() {
            isEmpty1 = false;
            isLoading1 = false;
            isError1 = true;
          });
        }
      },
    );
  }

  Future<void> getTodayTransactions() async {
    if (!mounted) return;
    setState(() {
      isTodayLoading = true;
      isTodayError = false;
    });

    if (sourceId.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        isTodayLoading = false;
        isTodayError = true;
      });
      return;
    }

    try {
      await ApiRepository.shared.getVenodorOrders(
        sourceId,
        (list) {
          if (!mounted) return;
          setState(() {
            isTodayLoading = false;
            isTodayError = false;
          });
        },
        (error) {
          if (!mounted) return;
          setState(() {
            isTodayLoading = false;
            isTodayError = true;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isTodayLoading = false;
        isTodayError = true;
      });
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '---';
    return months[month - 1];
  }

  String _formatTxnDate(String? raw) {
    final parsed = parseApiDateTime(raw);
    if (parsed == null) return 'Date unavailable';
    return '${_monthName(parsed.month)} ${parsed.day}, ${parsed.year}';
  }

  String _formatNotiTime(String? raw) => formatApiTime(raw);

  List<Widget> _todaySectionChildren() {
    if (isTodayLoading) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
                strokeWidth: 2.4,
              ),
            ),
          ),
        ),
      ];
    }
    if (isTodayError) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Could not load transactions.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ];
    }

    final raw = ApiRepository.shared.getAllOrdersByVenodrIdList?.data ?? [];
    final visible = raw.where((e) => !OrderStatus.isTerminal(e.orderStatus)).toList();
    if (visible.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'No transactions yet.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ];
    }

    final top = visible.take(3).toList();
    return top.map((item) {
      final amount = item.totalPrice.toString();
      return todayItem(
        item.name?.toString().isNotEmpty == true
            ? item.name.toString()
            : 'Customer',
        _formatTxnDate(item.createdAt?.toString()),
        '-\$$amount',
      );
    }).toList();
  }

  List<Widget> _latestNotificationsChildren() {
    if (isLoading1) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
                strokeWidth: 2.4,
              ),
            ),
          ),
        ),
      ];
    }
    if (isError1) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Could not load notifications.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ];
    }

    final raw = ApiRepository.shared.getNotificationModelList?.data ?? [];
    if (raw.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'No notifications yet.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ];
    }

    final top = raw.take(2).toList();
    final children = <Widget>[];
    for (int i = 0; i < top.length; i++) {
      final item = top[i];
      children.add(
        notificationItem(
          (item.name?.toString().isNotEmpty == true)
              ? item.name.toString().capitalizeFirst
              : 'Notification',
          item.description?.toString() ?? '',
          _formatNotiTime(item.createdAt?.toString()),
          dotColor: const Color(0xFFFBA104),
        ),
      );
      if (i != top.length - 1) {
        children.add(const Divider(height: 1));
      }
    }
    return children;
  }

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
  void dispose() {
    notiTimer().timer?.cancel();
    super.dispose();
  }

  void func() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setBool("time", true);
    check();
  }

  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getData();
      if (mounted) profileData(context);
    });
    func();
  }

  Widget featureCard(title, subtitle, icon) {
    return GestureDetector(
      onTap: () {
        if (title == "My Products") {
          Get.to(() => MyProductsScreen(side: false));
        } else {
          Get.to(() => VendorMyOrdersScreen());
        }
      },
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(icon, height: 48, width: 48),
                Icon(Icons.chevron_right, color: Colors.black54, size: 24),
              ],
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (title == "Today") {
                    Get.to(() => VendorMyTransactionsScreen());
                  } else {
                    Get.to(() => const NotificationsScreen(isVendor: true));
                  }
                },
                child: Text(
                  "View all",
                  style: GoogleFonts.inter(
                    color: Color(0xFFFBA104),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget todayItem(name, date, amount) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFFFE4EC),
            child: Icon(Icons.north_east, color: Colors.red, size: 22),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "PAID",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget notificationItem(title, subtitle, time, {Color? dotColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor ?? Color(0xFFFBA104),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.3,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  final GlobalKey<ScaffoldState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Scaffold(
        key: _key,

        drawer: Consumer<UserViewModel>(
          builder: (context, usp, _) => AppDrawerScreen(
            key: ValueKey('drawer-${usp.role}'),
          ),
        ),
        backgroundColor: const Color(0xFFF3F3F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: Colors.black,
          centerTitle: false,
          titleSpacing: 0,
          title: Text(
            'Home',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              fontSize: 19,
            ),
          ),
          leading: InkWell(
            onTap: () {
              _key.currentState!.openDrawer();
            },
            borderRadius: BorderRadius.circular(50),
            child: Padding(
              padding: const EdgeInsets.all(17.0),
              child: Image.asset(
                'assets/images/mingcute_menu-fill.png',
                color: Colors.black,
              ),
            ),
          ),
          actions: [
            SizedBox(width: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Material(
                  color: Colors.white,
                  shape: CircleBorder(
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      seenNotification();
                      Get.to(() => const NotificationsScreen(isVendor: true));
                    },
                    child: SizedBox(
                      height: 36,
                      width: 36,
                      child: Center(
                        child: Image.asset(
                          'assets/images/notificationnew.png',
                          height: 20,
                          width: 20,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isLoading1 &&
                    ApiRepository.shared.getNotificationModelList?.unseen
                            .toString() !=
                        "0" &&
                    ApiRepository.shared.getNotificationModelList != null)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Color(0xFFFBA104),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        ApiRepository.shared.getNotificationModelList!.unseen
                            .toString(),
                        style: TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 10),
            Material(
              color: Colors.white,
              shape: CircleBorder(
                side: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Get.to(() => UserProfileScreen()),
                child: SizedBox(
                  height: 36,
                  width: 36,
                  child: Center(
                    child: Image.asset(
                      'assets/images/personnew.png',
                      height: 20,
                      width: 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
          ],
        ),

        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// SEARCH BAR
                //       contentPadding: EdgeInsets.symmetric(vertical: 14),


                /// PROFILE CARD
                profileCard(),

                const ReservationActionCard(),

                SizedBox(height: 24),

                /// FEATURE BOXES
                Row(
                  children: [
                    Expanded(
                      child: featureCard(
                        "My Products",
                        "Manage Products",
                        "assets/images/myproducts.png",
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: featureCard(
                        "My Orders",
                        "Track your rentals.",
                        "assets/images/myorders1.png",
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                /// TODAY SECTION
                _sectionCard(title: "Today", children: _todaySectionChildren()),

                SizedBox(height: 24),

                /// NOTIFICATIONS
                _sectionCard(
                  title: "Latest Notifications",
                  children: _latestNotificationsChildren(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  contBox({txt, img}) {
    double res_width = MediaQuery.of(context).size.width;
    double res_height = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () {
        if (txt == "Orders") {
          Get.to(() => VendorMyOrdersScreen());
        }
        if (txt == "Transactions") {
          Get.to(() => VendorMyTransactionsScreen());
        }
        if (txt == "Product") {
          Get.to(() => MyProductsScreen(side: false));
        }
        if (txt == "Profile") {
          Get.to(() => UserProfileScreen());
        }
      },
      child: Column(
        children: [
          Container(
            width: res_width * 0.4,
            height: res_height * 0.2,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              color: Color(0xFFFBA104),
              borderRadius: BorderRadius.all(Radius.circular(18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: 5,
                  offset: Offset(2, 1), // Shadow position
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: res_width * 0.135,
                  child: Image.asset(
                    '$img',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6),
          Text("$txt", style: TextStyle(fontSize: 17)),
        ],
      ),
    );
  }
}
