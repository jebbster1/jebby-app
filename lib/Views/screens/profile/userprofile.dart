import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jebby/utils/api_headers.dart';
import 'package:jebby/res/color.dart';
import 'package:jebby/utils/profile_image.dart';

import '../../../model/user_model.dart';
import '../../../view_model/apiServices.dart';
import '../../../view_model/user_view_model.dart';
import '../home/Favourites.dart';
import '../home/MyOrders.dart';
import 'editprofile.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RenterProfile();
  }
}

class RenterProfile extends StatefulWidget {
  final dynamic vendorID;
  final dynamic vendorName;
  final dynamic vendorImage;
  final dynamic vendorBackImage;
  final dynamic vendorAddress;

  const RenterProfile({
    super.key,
    this.vendorID,
    this.vendorName,
    this.vendorImage,
    this.vendorBackImage,
    this.vendorAddress,
  });

  @override
  State<RenterProfile> createState() => _RenterProfileState();
}

class _RenterProfileState extends State<RenterProfile> {
  String Url = dotenv.env['baseUrlM'] ?? "";

  String? token;
  String? id;
  String? fullname;
  String? email;
  String? role;
  bool _isCurrentUserProfile = false;

  var imagesapi = "";
  var back_image_api = "";
  var addressapi = "";
  var phoneapi = "";

  bool isLoading = true;
  bool isEmpty = false;

  int productsCount = 0;
  int ordersCount = 0;

  Future<UserModel> getUserDate() => UserViewModel().getUser();

  @override
  void initState() {
    super.initState();
    profileData();
  }

  void profileData() async {
    getUserDate().then((value) {
      final currentUserId = value.id.toString();
      final targetVendorId =
          widget.vendorID == null ? currentUserId : widget.vendorID.toString();

      setState(() {
        token = value.token.toString();
        id = targetVendorId;
        _isCurrentUserProfile = targetVendorId == currentUserId;
        fullname = widget.vendorName == null
            ? value.name.toString()
            : widget.vendorName.toString();
        email = value.email.toString();
        role = value.role.toString();
      });

      getReviewsFor(targetVendorId);
      getProductsApi(targetVendorId);

      ApiRepository.shared.getAllVendorProductsByID(
        (list) {
          if (mounted) setState(() => productsCount = list.data?.length ?? 0);
        },
        (e) {},
        targetVendorId,
      );
      ApiRepository.shared.getVenodorOrders(
        targetVendorId,
        (list) {
          if (mounted) setState(() => ordersCount = list.data?.length ?? 0);
        },
        (e) {},
      );
    });
  }

  void getReviewsFor(String vendorId) {
    ApiRepository.shared.reviewsByVendorId(
      vendorId,
      (list) {
        if (mounted) {
          setState(() {
            isLoading = false;
            isEmpty = list.data!.isEmpty;
          });
        }
      },
      (error) {},
    );
  }

  int get _reviewsCount {
    final list = ApiRepository.shared.getAllReviewsByVendorIdModelList;
    return list?.totalreviews ?? list?.data?.length ?? 0;
  }

  double get _averageRating {
    final data = ApiRepository.shared.getAllReviewsByVendorIdModelList?.data;
    if (data == null || data.isEmpty) return 0.0;
    int sum = 0;
    for (var r in data) {
      sum += r.stars ?? 0;
    }
    return sum / data.length;
  }

  Map<int, double> _ratingDistribution() {
    final data = ApiRepository.shared.getAllReviewsByVendorIdModelList?.data;
    final total = data?.length ?? 0;
    if (total == 0) return {5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0};
    final counts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var r in data!) {
      final s = r.stars ?? 0;
      if (s >= 1 && s <= 5) counts[s] = counts[s]! + 1;
    }
    return {
      5: counts[5]! / total,
      4: counts[4]! / total,
      3: counts[3]! / total,
      2: counts[2]! / total,
      1: counts[1]! / total,
    };
  }

  static const Color _starAccent = Color(0xFFF6AE02);
  static const Color _starInactive = Color(0xFFC6C8CF);

  Widget _profileSummaryStars(double rating, {double size = 20}) {
    final filledStars = (rating.isNaN ? 0.0 : rating).round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final active = index < filledStars;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            active ? Icons.star : Icons.star_border,
            color: active ? _starAccent : _starInactive,
            size: size,
          ),
        );
      }),
    );
  }

  static String _timeAgo(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '';
    final d = DateTime.tryParse(createdAt);
    if (d == null) return '';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()} year${diff.inDays >= 730 ? 's' : ''} ago';
    }
    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} month${diff.inDays >= 60 ? 's' : ''} ago';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final roleRaw = (role ?? '').toString().trim();
    final roleInt = int.tryParse(roleRaw);
    final isProviderRole = roleInt == 1;
    final showRenterUi = _isCurrentUserProfile && !isProviderRole;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
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
          _isCurrentUserProfile ? "My Profile" : "Profile",
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_isCurrentUserProfile)
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Get.to(() => EditProfile()),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Icon(Icons.edit, color: Colors.blue, size: 20),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: showRenterUi ? _buildRenterProfileBody() : _buildProviderBody(),
    );
  }

  Widget _buildProviderBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: !ProfileImage.isValidPath(back_image_api)
                        ? Image.asset("assets/images/placeholder.png", fit: BoxFit.cover)
                        : Image.network(
                            ProfileImage.resolveUrl(Url, back_image_api)!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Image.asset(
                                "assets/images/placeholder.png",
                                fit: BoxFit.cover,
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                "assets/images/placeholder.png",
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                  ),
                ),
                Positioned(
                  bottom: -45,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.amber, Colors.blue],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: ProfileImage.avatarProvider(
                          Url,
                          imagesapi,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            Text(
              fullname ?? "",
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              (widget.vendorAddress != null && widget.vendorAddress.toString().trim().isNotEmpty)
                  ? widget.vendorAddress.toString()
                  : (email ?? ""),
              style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(child: statItem("assets/images/myproducts.png", "$productsCount", "PRODUCTS")),
                  Container(width: 1, height: 50, color: Colors.grey.shade300),
                  Expanded(child: statItem("assets/images/myorders1.png", "$ordersCount", "ORDERS")),
                  Container(width: 1, height: 50, color: Colors.grey.shade300),
                  Expanded(child: statItem("assets/images/rating1.png", "$_reviewsCount", "REVIEWS")),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ratings & Reviews", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_averageRating.toStringAsFixed(2), style: GoogleFonts.inter(fontSize: 42, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text("$_reviewsCount Review${_reviewsCount == 1 ? '' : 's'}", style: GoogleFonts.inter(fontSize: 14)),
                          const SizedBox(height: 8),
                          _profileSummaryStars(_averageRating),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            _ratingRow(5, _ratingDistribution()[5] ?? 0.0),
                            _ratingRow(4, _ratingDistribution()[4] ?? 0.0),
                            _ratingRow(3, _ratingDistribution()[3] ?? 0.0),
                            _ratingRow(2, _ratingDistribution()[2] ?? 0.0),
                            _ratingRow(1, _ratingDistribution()[1] ?? 0.0),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  isLoading
                      ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.primaryColor)))
                      : isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text("No Reviews", style: GoogleFonts.inter(color: Colors.grey)),
                            )
                          : ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: ApiRepository.shared.getAllReviewsByVendorIdModelList!.data!.length,
                              itemBuilder: (context, index) {
                                var data = ApiRepository.shared.getAllReviewsByVendorIdModelList!.data![index];
                                return reviewItem(
                                  data.userName.toString(),
                                  data.description.toString(),
                                  double.parse(data.stars.toString()),
                                  dateStr: _timeAgo(data.createdAt),
                                );
                              },
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statItem(icon, number, title) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(icon, height: 28),
        const SizedBox(height: 8),
        Text(number, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _ratingRow(int stars, double value) {
    final pct = (value * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text("$stars★", style: GoogleFonts.inter(fontSize: 12))),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFBA104)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 32, child: Text("$pct%", style: GoogleFonts.inter(fontSize: 12))),
        ],
      ),
    );
  }

  Widget reviewItem(String name, String desc, double stars, {String? dateStr}) {
    final timeAgo = dateStr ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade300,
                child: Icon(Icons.person, size: 22, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(stars.toStringAsFixed(1), style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (timeAgo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(timeAgo, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildRenterProfileBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildRenterAvatar(),
          const SizedBox(height: 12),
          Text(
            "Verified User",
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xff8F9098)),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _infoRow(Icons.person, "Name", fullname ?? ""),
                _infoRow(Icons.email, "Email Address", email ?? ""),
                // _infoRow(Icons.phone, "Mobile Number", phoneapi.isNotEmpty && phoneapi != "null" ? phoneapi : "—"),
                _infoRow(Icons.location_on, "My Address", addressapi.isNotEmpty ? addressapi : "—"),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _actionCard(
                imagename: 'mywishlist.png',
                iconColor: Colors.red,
                title: "My Wishlist",
                subtitle: "Items you love.",
                onTap: () => Get.to(() => FavouriteScreen()),
              ),
              const SizedBox(width: 12),
              _actionCard(
                imagename: 'myorders.png',
                iconColor: Colors.brown,
                title: "My Orders",
                subtitle: "Track your rentals.",
                onTap: () => Get.to(() => MyOrdersScreen()),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRenterAvatar() {
    return ProfileImage.circularAvatar(
      radius: 55,
      baseUrl: Url,
      imagePath: imagesapi,
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xff8F9098)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xff8F9098),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required String imagename,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Image.asset(
                    "assets/images/$imagename",
                    height: 20,
                    width: 20,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xff8F9098),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future getProductsApi(dynamic profileId) async {
    final response = await http.get(
      Uri.parse('${Url}/UserProfileGetById/${profileId}'),
      headers: await ApiHeaders.json(),
    );
    var data = jsonDecode(response.body);
    setState(() {
      if (data["data"].length != 0) {
        final profileImage = data["data"][0]["profile_image"]?.toString().trim() ?? '';
        imagesapi = ProfileImage.sanitizePath(profileImage);
        final coverImage = data["data"][0]["cover_image"]?.toString().trim() ?? '';
        back_image_api = ProfileImage.sanitizePath(coverImage);
        final apiRole = data["data"][0]["role"]?.toString();
        if (apiRole != null && apiRole.trim().isNotEmpty) {
          role = apiRole;
        }
        addressapi = data["data"][0]["address"]?.toString() ?? "";
        phoneapi = data["data"][0]["phone_number"]?.toString() ?? "";
      }
    });
  }
}

