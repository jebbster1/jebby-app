import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:jebby/Views/screens/vendors/ProductDetails.dart';
import 'package:jebby/Views/screens/vendors/AddProduct.dart';
import 'package:jebby/utils/show_snackbar.dart';
import 'package:jebby/Views/screens/vendors/vendorhome.dart';
import 'package:jebby/res/app_url.dart';
import 'package:jebby/res/color.dart';
import 'package:provider/provider.dart';

import '../../../Services/provider/sign_in_provider.dart';
import '../../../model/user_model.dart';
import '../../../view_model/apiServices.dart';
import '../../../view_model/user_view_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:jebby/utils/api_headers.dart';

class ProductListScreen extends StatefulWidget {
  final side;
  ProductListScreen({Key? key, required this.side}) : super(key: key);
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String Url = dotenv.env['baseUrlM'] ?? 'No url found';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool emptyData = false;
  bool isLoading = true;
  bool isError = false;

  Future getData() async {
    final sp = context.read<SignInProvider>();
    final usp = context.read<UserViewModel>();
    usp.getUser();
    sp.getDataFromSharedPreferences();
  }

  Future<UserModel> getUserDate() => UserViewModel().getUser();

  String? token;
  String? id;
  String? fullname;
  String? email;
  String? role;
  void profileData(BuildContext context) async {
    getUserDate()
        .then((value) async {
          token = value.token.toString();
          id = value.id.toString();
          fullname = value.name.toString();
          email = value.email.toString();
          role = value.role.toString();
          getUserData();
          getVendorProducts(id);
          getProductsApi(id);
        })
        .onError((error, stackTrace) {
          if (kDebugMode) {}
        });
  }

  var profile = [];
  Future getProductsApi(id) async {
    final response = await http.get(
      Uri.parse('${Url}/UserProfileGetById/${id}'),
      headers: await ApiHeaders.json(),
    );
    var data = jsonDecode(response.body.toString());
    profile = data['data'];
  }

  getVendorProducts(id) {
    ApiRepository.shared.getAllVendorProductsByID(
      (list) {
        if (this.mounted) {
          if (list.data!.length == 0) {
            setState(() {
              emptyData = true;
              isLoading = false;
              isError = false;
            });
          } else {
            setState(() {
              emptyData = false;
              isLoading = false;
              isError = false;
            });
          }
        }
      },
      (error) {
        if (this.mounted) {
          if (error != null) {
            setState(() {
              isLoading = true;
              isError = true;
            });
          }
        }
      },
      id,
    );
  }

  late var vendorAccountMail;
  bool isULoading = true;

  void getUserData() {
    ApiRepository.shared.userCredential(
      (List) => {
        if (this.mounted)
          {
            if (List.data!.length == 0)
              {}
            else
              {
                setState(() {
                  isULoading = false;
                  vendorAccountMail =
                      ApiRepository
                          .shared
                          .getUserCredentialModelList!
                          .data![0]
                          .stripeEmail
                          .toString();
                }),
              },
          },
      },
      (error) => {if (error != null) {}},
      id.toString(),
    );
  }

  void initState() {
    getData();
    profileData(context);
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color textColor = Color(0xFF1A1A1A);
    final interStyle = GoogleFonts.inter(color: textColor);
    final textTheme = GoogleFonts.interTextTheme(
      Theme.of(context).textTheme.apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
    );
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: GoogleFonts.inter(color: Colors.grey),
          labelStyle: GoogleFonts.inter(color: textColor),
        ),
      ),
      child: Scaffold(
      backgroundColor: const Color(0xFFF3F3F5),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Get.back();
            } else {
              Get.offAll(() => const VendrosHomeScreen());
            }
          },
          style: IconButton.styleFrom(foregroundColor: Colors.black),
        ),
      ),

      body: DefaultTextStyle(
        style: interStyle,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal:20),
        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            /// TITLE + BUTTON

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "My Products",
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),

                    SizedBox(height:10),

                    Text(
                      "View and Edit your Products",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF72747A),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    )

                  ],
                ),

                GestureDetector(
                  onTap: (){
                    if (profile.length == 0) {

                      showAppErrorSnackbar('Complete your profile', title: 'Required');

                    } else {
                      Get.to(()=>AddProductScreen());
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal:20,vertical:10),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF6AE02),
                        borderRadius: BorderRadius.circular(30)),
                    child: Text(
                      "Add Product",
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              ],
            ),

            SizedBox(height:20),

            /// SEARCH BAR

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  icon: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Image.asset(
                      'assets/images/searchnew.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                  hintText: "Search by Product Name",
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF9A9AA1),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.inter(
                  color: const Color(0xFF2A2A2E),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            SizedBox(height:20),

            /// PRODUCT GRID

            Expanded(
              child: isError
                  ? Center(
                      child: Text(
                        "Error loading data",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6D6D75),
                        ),
                      ),
                    )
                  : isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
                  : emptyData
                  ? Center(
                      child: Text(
                        "No Products Added",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6D6D75),
                        ),
                      ),
                    )
                  : Builder(
                      builder: (_) {
                        final allProducts =
                            ApiRepository.shared.vendorProductsByIdList?.data ??
                                [];
                        final filteredProducts = allProducts.where((product) {
                          final productName =
                              (product.name ?? '').toString().toLowerCase();
                          return _searchQuery.isEmpty ||
                              productName.contains(_searchQuery);
                        }).toList();
                        return GridView.builder(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                ),

                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 225,
                ),

                itemCount: filteredProducts.length,

                itemBuilder: (context,index){

                  final product = filteredProducts[index];

                  return productCard(
                      product.id,
                      product.name,
                      product.price,
                      product.stars,
                      product.image);

                },
              );
                      },
                    ),
            )
          ],
        ),
        ),
      ),
      ),
    );
  }
  Widget productCard(id,name,price,stars,image){
    final parsedRating = double.tryParse(stars.toString()) ?? 0;
    final int filledStars = parsedRating.round().clamp(0, 5);

    return GestureDetector(

      onTap: (){
        Get.to(()=>ProductDetail2Screen(id:id));
      },

      child: Container(

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            /// IMAGE

            Stack(
              children: [

                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: AppUrl.baseUrlM + image.toString(),
                    height: 118,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                Positioned(
                  right:10,
                  top:10,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal:8,vertical:3),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade500,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      "NEW",
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(
                    name.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 31 / 2,
                      color: const Color(0xFF2A2A2E),
                    ),
                  ),

                  SizedBox(height:5),

                  Text(
                    "\$${price}",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 38 / 2,
                      color: const Color(0xFF1D1D21),
                    ),
                  ),

                  const SizedBox(height: 5),
                  Row(
                    children: List.generate(5, (index) {
                      final active = index < filledStars;
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          active ? Icons.star : Icons.star_border,
                          color: active
                              ? const Color(0xFFF6AE02)
                              : const Color(0xFFC6C8CF),
                          size: 18,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  itmBox({img, tx, dx, rt, rv, id}) {
    double res_width = MediaQuery.of(context).size.width;
    double res_height = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: GestureDetector(
        onTap: () {
          Get.off(() => ProductDetail2Screen(id: id));
        },
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 244, 244, 244),
            borderRadius: BorderRadius.circular(10),
          ),
          // child: Padding(
          //   padding: const EdgeInsets.only(
          //       bottom: 120, left: 10, right: 10, top: 10),
          child: Padding(
            padding: const EdgeInsets.all(13.0),
            child: Column(
              children: [
                Container(
                  height: res_height * 0.2,
                  decoration: BoxDecoration(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    child: CachedNetworkImage(
                      imageUrl: img.toString(),
                      fit: BoxFit.fill,
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
                  ),
                ),
                SizedBox(height: res_height * 0.005),
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: res_width * 0.5,
                        child: Text(
                          '$tx',
                          style: TextStyle(
                            fontSize: 15,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(height: res_height * 0.006),
                      Text(
                        '$dx',
                        style: TextStyle(fontSize: 13),
                        textAlign: TextAlign.left,
                      ),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: double.parse(rt),
                            itemBuilder:
                                (context, index) =>
                                    Icon(Icons.star, color: Colors.amber),
                            itemCount: 5,
                            itemSize: 15,
                            direction: Axis.horizontal,
                          ),
                          Text(
                            '($rv) Reviews',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
