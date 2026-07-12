import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart' as d;

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jebby/Views/screens/profile/userprofile.dart';

import 'package:jebby/model/user_model.dart';
import 'package:jebby/utils/utilities/dialog/error_dialog.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../Services/provider/sign_in_provider.dart';
import '../../../utils/overlay_support.dart';
import '../../../view_model/apiServices.dart';
import '../../../view_model/user_view_model.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({Key? key}) : super(key: key);

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  String Url = dotenv.env['baseUrlM'] ?? 'No url found';
  File? _image;
  File? _image1;

  final picker = ImagePicker();

  Future getGalleryImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      final file = File(pickedImage.path);
      final fileSize = await file.length();

      if (fileSize > 5 * 1024 * 1024) {
        _showAlert(
          'Selected file is larger than 5MB. Please select a smaller file.',
        );
      } else {
        setState(() {
          _image = file;
        });
      }
    } else {
      log("No image picked");
    }
  }

  Future getGalleryImage1() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage != null) {
      final file = File(pickedImage.path);
      final fileSize = await file.length();

      if (fileSize > 5 * 1024 * 1024) {
        _showAlert(
          'Selected file is larger than 5MB. Please select a smaller file.',
        );
      } else {
        setState(() {
          _image1 = file;
        });
      }
    } else {
      log("No image picked");
    }
  }

  Future getData() async {
    final sp = context.read<SignInProvider>();
    final usp = context.read<UserViewModel>();
    usp.getUser();
    sp.getDataFromSharedPreferences();
  }

  String dropdownValue = "standard";
  List<String> items = ["standard", "custom", "express"];

  Future<UserModel> getUserDate() => UserViewModel().getUser();

  @override
  void initState() {
    super.initState();
    // _locationController.addListener(() {
    //   _onChanged();
    // });
    //  _onChanged();
    getData();
    profileData(context);
  }

  _onChanged() {
    getSuggestion(_locationController.text);
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'File Size Exceeded',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(fontWeight: FontWeight.w400),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void getSuggestion(String input) async {
    String kPLACES_API_KEY =
        dotenv.env['kPLACES_API_KEY'] ?? 'No secret key found';

    try {
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String request =
          '$baseURL?input=$input&key=$kPLACES_API_KEY&sessiontoken=$_sessionToken';
      var response = await http.get(Uri.parse(request));

      log('mydata');
      log(response.body.toString());
      if (response.statusCode == 200) {
        setState(() {
          _placeList = json.decode(response.body)['predictions'];
        });
      } else {
        throw Exception('Failed to load predictions');
      }
    } catch (e) {
      // toastMessage('success');
    }
  }

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
          log("message from Edir profile" + id.toString());
          getProductsApi(id);
          fullname = value.name.toString();
          _nameController.text = fullname.toString();
          email = value.email.toString();
          role = value.role.toString();
          getUserData();
          log("From Edit PAge Log Test" + fullname.toString());
        })
        .onError((error, stackTrace) {
          if (kDebugMode) {}
        });
  }

  /////////////////////////////////////////////////////////
  TextEditingController _emailController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  var _locationController = TextEditingController();
  var _ShippingAddressController = TextEditingController();
  var Latitiude;
  var Longitude;
  var uuid = new Uuid();
  String _sessionToken = '1234567890';
  var vuid = new Uuid();
  List<dynamic> _placeList = [];
  var selected = "standard";

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
                  stripeEmailController.text =
                      ApiRepository
                                  .shared
                                  .getUserCredentialModelList!
                                  .data![0]
                                  .stripeEmail
                                  .toString() ==
                              "0"
                          ? ""
                          : ApiRepository
                              .shared
                              .getUserCredentialModelList!
                              .data![0]
                              .stripeEmail
                              .toString();
                  paypalEmailController.text =
                      ApiRepository
                          .shared
                          .getUserCredentialModelList!
                          .data![0]
                          .paypalEmail
                          .toString();
                  dropdownValue =
                      ApiRepository
                                  .shared
                                  .getUserCredentialModelList!
                                  .data![0]
                                  .stripeAccountType
                                  .toString() ==
                              "0"
                          ? "standard"
                          : ApiRepository
                              .shared
                              .getUserCredentialModelList!
                              .data![0]
                              .stripeAccountType
                              .toString();
                  // .shared
                  // .getUserCredentialModelList!
                  // .data![0]
                  // .stripeAccountType
                  // .toString()}");
                  selected =
                      ApiRepository
                                  .shared
                                  .getUserCredentialModelList!
                                  .data![0]
                                  .stripeAccountType
                                  .toString() ==
                              "0"
                          ? "standard"
                          : ApiRepository
                              .shared
                              .getUserCredentialModelList!
                              .data![0]
                              .stripeAccountType
                              .toString();
                }),
              },
          },
      },
      (error) => {if (error != null) {}},
      id.toString(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _ShippingAddressController.dispose();
    super.dispose();
  }

  TextEditingController stripeEmailController = TextEditingController();

  // TextEditingController stripeAccountController = TextEditingController();
  TextEditingController paypalEmailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // change read to watch!!!!
    final sp = context.watch<SignInProvider>();
    final usp = context.watch<UserViewModel>();

    // final authViewMode = Provider.of<AuthViewModel>(context);
    log(
      "For Providersssssssssssssss " +
          usp.name.toString() +
          "For Providersssssssssssssss " +
          sp.name.toString(),
    );
    _emailController.text = sp.email.toString();
    double res_width = MediaQuery.of(context).size.width;
    double res_height = MediaQuery.of(context).size.height;
    return Theme(
      data: Theme.of(
        context,
      ).copyWith(textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)),
      child: Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F2),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
        leading: InkWell(
          onTap: () {
            Get.back();
          },
          borderRadius: BorderRadius.circular(50),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: res_width * 0.9,
                child: Column(
                  children: [
                    SizedBox(height: res_height * 0.01),
                    SizedBox(
                      height: 222,
                      width: double.infinity,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          GestureDetector(
                            onTap: getGalleryImage,
                            child: Container(
                              width: double.infinity,
                              height: 170,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child:
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: _image != null
                                        ? Image.file(
                                            _image!.absolute,
                                            fit: BoxFit.cover,
                                          )
                                        : (back_image_api.toString().trim().isEmpty ||
                                                back_image_api.toString() == "null")
                                            ? Image.asset(
                                                "assets/slicing/placeholder.png",
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                Url + back_image_api,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) return child;
                                                  return Image.asset(
                                                    "assets/slicing/placeholder.png",
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Image.asset(
                                                    "assets/slicing/placeholder.png",
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                              ),
                                  ),
                            ),
                          ),
                          Positioned(
                            top: 118,
                            right: 14,
                            child: GestureDetector(
                              onTap: getGalleryImage,
                              child: Container(
                                height: 34,
                                width: 34,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF6AE02),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Center(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: getGalleryImage1,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        child: _image1 != null
                                            ? CircleAvatar(
                                                radius: 50,
                                                backgroundImage: FileImage(
                                                  _image1!.absolute,
                                                ),
                                              )
                                            : CircleAvatar(
                                                radius: 50,
                                                backgroundImage:
                                                    _profileImageProvider(),
                                              ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          height: 32,
                                          width: 32,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFF6AE02),
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: res_height * 0.01),
                    Text(
                      nameapi == "null"
                          ? sp.name.toString() == "null"
                              ? fullname.toString()
                              : sp.name.toString()
                          : nameapi.toString(),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Verified User",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Txtfld("Name", _nameController, ""),
                    TxtfldforEmail(
                      "Email",
                      _emailController,
                      _emailController.text.toString(),
                    ),

                    // role == "1"
                    //     ?
                    //     Txtfld(
                    //         "Stripe Account Email", stripeEmailController, "")
                    //     : SizedBox(
                    //         height: 1,
                    //       ),
                    // role == "1" ?
                    // Align(
                    //   alignment: Alignment.topLeft,
                    //   child: Text("Stripe account type")) : Text(""),
                    // role == "1"
                    //     ? Align(
                    //         alignment: Alignment.topLeft,
                    //         child: DropdownButton<String>(
                    //           value: dropdownValue,
                    //           icon: const Icon(Icons.arrow_downward),
                    //           elevation: 16,
                    //           style: const TextStyle(color: Colors.black),
                    //           underline: Container(
                    //               height: 4,
                    //               width:
                    //                   MediaQuery.of(context).size.width * 0.4,
                    //               color: kprimaryColor),
                    //           onChanged: (String? value) {
                    //             // This is called when the user selects an item.
                    //             setState(() {
                    //               dropdownValue = value!;
                    //               selected = value.toString();
                    //             });
                    //           },
                    //           items: items.map<DropdownMenuItem<String>>(
                    //               (String value) {
                    //             return DropdownMenuItem<String>(
                    //               value: value,
                    //               child: Text(value),
                    //             );
                    //           }).toList(),
                    //         ),
                    //       )
                    //     // Txtfld("Stripe Account Type", stripeAccountController,
                    //     //     "custom | standard | express")
                    //     : SizedBox(
                    //         height: 1,
                    //       ),
                    // role == "1"
                    //     ? Txtfld(
                    //         "Paypal Account Email", paypalEmailController, "")
                    //     : SizedBox(
                    //         height: 1,
                    //       ),
                    SizedBox(height: res_height * 0.001),
                    TxtfldforLocation("Location", _locationController),
                    SizedBox(
                      // height: MediaQuery.of(context).size.height*0.1,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: ScrollPhysics(),
                        itemCount: _placeList.length,
                        itemBuilder: ((context, index) {
                          String name = _placeList[index]["description"];

                          if (_locationController.text.isEmpty) {
                            return Text("");
                          } else if (name.toLowerCase().contains(
                            _locationController.text.toLowerCase(),
                          )) {
                            return ListTile(
                              onTap: () async {
                                _locationController.text =
                                    _placeList[index]["description"];
                                List<Location> location =
                                    await locationFromAddress(
                                      _placeList[index]["description"],
                                    );
                                log(
                                  "Latitiude : " +
                                      location.last.latitude.toString(),
                                );
                                log(
                                  "Longitude : " +
                                      location.last.longitude.toString(),
                                );

                                setState(() {
                                  _locationController.removeListener(() {});
                                  Latitiude = location.last.latitude.toString();
                                  Longitude =
                                      location.last.longitude.toString();
                                  _placeList = [];
                                });
                              },
                              leading: CircleAvatar(
                                child: Icon(
                                  Icons.pin_drop,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(_placeList[index]["description"]),
                              titleTextStyle: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            );
                          } else {
                            return SizedBox.shrink();
                          }
                        }),
                      ),
                    ),

                    // SizedBox(
                    //   height: 1,
                    // ),
                    //           Container(
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       SizedBox(
                    //         height: res_height * 0.02,
                    //       ),
                    //       Text('Shipping Address',style: TextStyle(fontSize: 17, color: Colors.black,),),
                    //       SizedBox(
                    //         height: res_height * 0.005,
                    //       ),
                    //       Container(
                    //         // height: 70,
                    //         width: res_width * 0.89,
                    //         child: TextField(
                    //           onChanged: (value) {
                    //             setState(() {
                    //               _onChanged2();
                    //             });
                    //           },
                    //           maxLines: 1,
                    //           controller: _ShippingAddressController,
                    //           decoration: InputDecoration(
                    //             // hintText:placholder,
                    //             border: OutlineInputBorder(
                    //               borderRadius: BorderRadius.circular(15.0),
                    //             ),
                    //             enabledBorder: const OutlineInputBorder(
                    //               borderSide: const BorderSide(color: kprimaryColor, width: 1),
                    //               borderRadius: BorderRadius.all(Radius.circular(15)),
                    //             ),
                    //             focusedBorder: const OutlineInputBorder(
                    //               borderSide: const BorderSide(color: kprimaryColor, width: 1),
                    //               borderRadius: BorderRadius.all(Radius.circular(15)),
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),

                    // SizedBox(
                    //   // height: res_height * 0.05,
                    //   child: ListView.builder(
                    //       shrinkWrap: true,
                    //       physics: ScrollPhysics(),
                    //       itemCount: _placeList1.length,
                    //       itemBuilder: ((context, index) {
                    //         String name = _placeList1[index]["description"];

                    //         if (_ShippingAddressController.text.isEmpty) {
                    //           return Text("");
                    //         } else if (name.toLowerCase().contains(_ShippingAddressController.text.toLowerCase())) {
                    //           return ListTile(
                    //             onTap: () async {
                    //               _ShippingAddressController.text = _placeList1[index]["description"];
                    //               List<Location> location = await locationFromAddress(_placeList1[index]["description"]);
                    //               setState(() {
                    //                 _ShippingAddressController.removeListener(() {});
                    //                 Latitiude = location.last.latitude.toString();
                    //                 Longitude = location.last.longitude.toString();
                    //                 _placeList1 = [];
                    //               });
                    //             },
                    //             leading: CircleAvatar(child: Icon(Icons.pin_drop, color: Colors.white)),
                    //             title: Text(_placeList1[index]["description"]),
                    //           );
                    //         } else {
                    //           return SizedBox.shrink();
                    //         }
                    //       })),
                    // ),
                    // return ListTile(
                    //   onTap: () async {
                    //     _locationController.text = _placeList[index]["description"];
                    //     List<Location> location = await locationFromAddress(_placeList[index]["description"]);
                    //     log("Latitiude : " + location.last.latitude.toString());
                    //     log("Longitude : " + location.last.longitude.toString());

                    //     setState(() {
                    //       _locationController.removeListener(() {
                    //         _onChanged();
                    //       });
                    //       Latitiude = location.last.latitude.toString();
                    //       Longitude = location.last.longitude.toString();
                    //       _placeList = [];
                    //     });
                    //   },
                    //   title: Text(_placeList[index]["description"]),
                    // );
                    const SizedBox.shrink(),

                    //////////////////////////////////////
                    SizedBox(height: res_height * 0.02),
                    GestureDetector(
                      onTap: () async {
                        log("pressed tap");
                        Loader.show();
                        if (imagesapi == "null") {
                          try {
                            if (_nameController.text.isEmpty) {
                              Loader.hide();
                              return ShowErrorDialog(
                                context,
                                "Please Enter Name",
                              );
                            }

                            if (_locationController.text.isEmpty) {
                              Loader.hide();
                              return ShowErrorDialog(
                                context,
                                "Please enter current location",
                              );
                            }
                            if (_image == null) {
                              Loader.hide();
                              return ShowErrorDialog(
                                context,
                                "Please Upload Cover Picture",
                              );
                            }
                            if (_image1 == null) {
                              Loader.hide();
                              return ShowErrorDialog(
                                context,
                                "Please Upload Profile Picture",
                              );
                            } else {
                              String fileName = Uuid().v4();
                              String fileName1 = Uuid().v4();
                              if (role == "1") {
                                // vendor profile insert
                                // if (stripeEmailController.text.isNotEmpty ) {
                                d.FormData formData = new d.FormData.fromMap({
                                  "file": [
                                    await d.MultipartFile.fromFile(
                                      _image1!.path,
                                      filename: fileName1,
                                    ),
                                    await d.MultipartFile.fromFile(
                                      _image!.path,
                                      filename: fileName,
                                    ),
                                  ],
                                  'name': _nameController.text.toString(),
                                  'email': _emailController.text.toString(),
                                  'number': '',
                                  'address':
                                      _locationController.text.toString(),
                                  'latitude': Latitiude,
                                  'longitude': Longitude,
                                  //"files": await d.MultipartFile.fromFile(_image!.path, filename: fileName),
                                  'user_id': id,
                                  'stripe_email':
                                      _emailController.text.toString(),
                                  // 'stripe_email':
                                  //     stripeEmailController.text.toString(),
                                  'paypal_email': "testppemail@gmail.com",
                                  'stripe_account_type': "standard",
                                  // 'stripe_account_type': selected.toString(),
                                  'shipping_address':
                                      _locationController.text.toString(),
                                  // "pics":3
                                });
                                log(formData.fields.toString());

                                d.Response response = await Dio().post(
                                  "${Url}/UserProfileInsert",
                                  data: formData,
                                );
                                log(response.statusCode.toString());
                                Loader.hide();
                                role == "1"
                                    ? Get.off(() => RenterProfile())
                                    : Get.off(() => MyProfileScreen());
                                // } else {
                                //   final snackBar = new SnackBar(
                                //       content: new Text(
                                //           "Payment fields cannot be empty"));
                                //   ScaffoldMessenger.of(context)
                                //       .showSnackBar(snackBar);
                                // }
                              }
                              // client profile insert
                              else {
                                d.FormData formData = new d.FormData.fromMap({
                                  "file": [
                                    await d.MultipartFile.fromFile(
                                      _image1!.path,
                                      filename: fileName1,
                                    ),
                                    await d.MultipartFile.fromFile(
                                      _image!.path,
                                      filename: fileName,
                                    ),
                                  ],
                                  'name': _nameController.text.toString(),
                                  'email': _emailController.text.toString(),
                                  'number': '',
                                  'address':
                                      _locationController.text.toString(),
                                  'latitude': Latitiude,
                                  'longitude': Longitude,
                                  //"files": await d.MultipartFile.fromFile(_image!.path, filename: fileName),
                                  'user_id': id,
                                  'stripe_email': 'testemail@gmail.com',
                                  'paypal_email': "testppemail@gmail.com",
                                  'stripe_account_type': "standard",
                                  'shipping_address':
                                      _ShippingAddressController.text
                                          .toString(),
                                  // "pics":3
                                });
                                log(formData.fields.toString());

                                d.Response response = await Dio().post(
                                  "${Url}/UserProfileInsert",
                                  data: formData,
                                );
                                log(response.statusCode.toString());
                                Loader.hide();
                                role == "1"
                                    ? Get.off(() => RenterProfile())
                                    : Get.off(() => MyProfileScreen());
                              }
                            }
                          } catch (e) {
                            Loader.hide();
                            log("expectation Caugcht: 1 " + e.toString());
                          }
                        } else {
                          try {
                            late d.FormData formData;
                            if (role == "1") {
                              // for vendor profile update
                              if (stripeEmailController.text.isNotEmpty) {
                                if (_image == null && _image1 != null) {
                                  String fileName1 = p.basename(_image1!.path);
                                  formData = new d.FormData.fromMap({
                                    "file": await d.MultipartFile.fromFile(
                                      _image1!.path,
                                      filename: fileName1,
                                    ),
                                    'name': _nameController.text.toString(),
                                    'email': _emailController.text.toString(),
                                    'number': '',
                                    'address':
                                        _locationController.text.toString(),
                                    'latitude': Latitiude,
                                    'longitude': Longitude,
                                    'user_id': id,
                                    //"files": await d.MultipartFile.fromFile(_image!.path, filename: fileName),
                                    "pics": 1,
                                    "paypal_email":
                                        "testingpaypalemail@gmail.com",

                                    "stripe_email":
                                        stripeEmailController.text.toString(),
                                    "stripe_account_type": selected.toString(),
                                    'shipping_address':
                                        _locationController.text.toString(),
                                  });
                                } else if (_image1 == null && _image != null) {
                                  String fileName = p.basename(_image!.path);
                                  formData = new d.FormData.fromMap({
                                    "file": await d.MultipartFile.fromFile(
                                      _image!.path,
                                      filename: fileName,
                                    ),
                                    'name': _nameController.text.toString(),
                                    'email': _emailController.text.toString(),
                                    'number': '',
                                    'address':
                                        _locationController.text.toString(),
                                    'latitude': Latitiude,
                                    'longitude': Longitude,
                                    'user_id': id,

                                    //"files": await d.MultipartFile.fromFile(_image!.path, filename: fileName),
                                    "pics": 2,
                                    "paypal_email":
                                        "testingpaypalemail@gmail.com",
                                    "stripe_email":
                                        stripeEmailController.text.toString(),
                                    "stripe_account_type": selected.toString(),
                                    'shipping_address':
                                        _locationController.text.toString(),
                                  });
                                } else if (_image1 == null && _image == null) {
                                  log("both images are null");
                                  formData = new d.FormData.fromMap({
                                    'name': _nameController.text.toString(),
                                    'email': _emailController.text.toString(),
                                    'number': '',
                                    'address':
                                        _locationController.text.toString(),
                                    'latitude': Latitiude,
                                    'longitude': Longitude,
                                    'user_id': id,

                                    //"files": await d.MultipartFile.fromFile(_image!.path, filename: fileName),
                                    "pics": 1,
                                    "paypal_email":
                                        "testingpaypalemail@gmail.com",
                                    "stripe_email":
                                        stripeEmailController.text.toString(),
                                    "stripe_account_type": selected.toString(),
                                    'shipping_address':
                                        _locationController.text.toString(),
                                  });
                                } else {
                                  log("hellooooo22");
                                  String fileName = p.basename(_image!.path);
                                  String fileName1 = p.basename(_image1!.path);
                                  formData = new d.FormData.fromMap({
                                    "file": [
                                      await d.MultipartFile.fromFile(
                                        _image1!.path,
                                        filename: fileName1,
                                      ),
                                      await d.MultipartFile.fromFile(
                                        _image!.path,
                                        filename: fileName,
                                      ),
                                    ],
                                    'name': _nameController.text.toString(),
                                    'email': _emailController.text.toString(),
                                    'number': '',
                                    'address':
                                        _locationController.text.toString(),
                                    'latitude': Latitiude,
                                    'longitude': Longitude,
                                    'user_id': id,

                                    //"files": await d.MultipartFile.fromFile(_image!.path, filename: fileName),
                                    "pics": 3,
                                    "paypal_email":
                                        "testingpaypalemail@gmail.com",
                                    "stripe_email":
                                        stripeEmailController.text.toString(),
                                    "stripe_account_type": selected.toString(),
                                    // 'shipping_address': _ShippingAddressController.text.toString(),
                                  });
                                }
                                log(formData.fields.toString());
                              } else {
                                Loader.hide();
                                final snackBar = new SnackBar(
                                  content: new Text(
                                    "Payment fields cannot be empty",
                                  ),
                                );
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(snackBar);
                              }
                            } else {
                              // for client update
                              if (_image == null && _image1 != null) {
                                String fileName1 = p.basename(_image1!.path);
                                formData = new d.FormData.fromMap({
                                  "file": await d.MultipartFile.fromFile(
                                    _image1!.path,
                                    filename: fileName1,
                                  ),
                                  'name': _nameController.text.toString(),
                                  'email': _emailController.text.toString(),
                                  'number': '',
                                  'address':
                                      _locationController.text.toString(),
                                  'latitude': Latitiude,
                                  'longitude': Longitude,
                                  'user_id': id,
                                  //"files": await d.MultipartFile.fromFile(_image!.path, filename: fileName),
                                  "pics": 1,
                                  "paypal_email": "testemail@gmail.com",
                                  "stripe_email": "testemail@gmail.com",
                                  "stripe_account_type": "standard",
                                });
                              } else if (_image1 == null && _image != null) {
                                String fileName = p.basename(_image!.path);
                                formData = new d.FormData.fromMap({
                                  "file": await d.MultipartFile.fromFile(
                                    _image!.path,
                                    filename: fileName,
                                  ),
                                  'name': _nameController.text.toString(),
                                  'email': _emailController.text.toString(),
                                  'number': '',
                                  'address':
                                      _locationController.text.toString(),
                                  'latitude': Latitiude,
                                  'longitude': Longitude,
                                  'user_id': id,

                                  //"files": await d.MultipartFile.fromFile(_image!.path, filename: fileName),
                                  "pics": 2,
                                  "paypal_email": "testemail@gmail.com",
                                  "stripe_email": "testemail@gmail.com",
                                  "stripe_account_type": "standard",
                                  'shipping_address':
                                      _ShippingAddressController.text
                                          .toString(),
                                });
                              } else if (_image1 == null && _image == null) {
                                log("both images are null");
                                formData = new d.FormData.fromMap({
                                  'name': _nameController.text.toString(),
                                  'email': _emailController.text.toString(),
                                  'number': '',
                                  'address':
                                      _locationController.text.toString(),
                                  'latitude': Latitiude,
                                  'longitude': Longitude,
                                  'user_id': id,

                                  //"files": await d.MultipartFile.fromFile(_image!.path, filename: fileName),
                                  "pics": 1,
                                  "paypal_email": "testemail@gmail.com",
                                  "stripe_email": "testemail@gmail.com",
                                  "stripe_account_type": "standard",
                                  'shipping_address':
                                      _ShippingAddressController.text
                                          .toString(),
                                });
                              } else {
                                log("hellooooo22");
                                String fileName = p.basename(_image!.path);
                                String fileName1 = p.basename(_image1!.path);
                                formData = new d.FormData.fromMap({
                                  "file": [
                                    await d.MultipartFile.fromFile(
                                      _image1!.path,
                                      filename: fileName1,
                                    ),
                                    await d.MultipartFile.fromFile(
                                      _image!.path,
                                      filename: fileName,
                                    ),
                                  ],
                                  'name': _nameController.text.toString(),
                                  'email': _emailController.text.toString(),
                                  'number': '',
                                  'address':
                                      _locationController.text.toString(),
                                  'latitude': Latitiude,
                                  'longitude': Longitude,
                                  'user_id': id,

                                  //"files": await d.MultipartFile.fromFile(_image!.path, filename: fileName),
                                  "pics": 3,
                                  "paypal_email": "testemail@gmail.com",
                                  "stripe_email": "testemail@gmail.com",
                                  "stripe_account_type": "standard",
                                  'shipping_address':
                                      _ShippingAddressController.text
                                          .toString(),
                                });
                              }
                              log(formData.fields.toString());
                            }
                            d.Response response = await Dio().post(
                              "${Url}/UserProfileUpdate",
                              data: formData,
                            );
                            log(response.statusCode.toString());
                            Loader.hide();
                            role == "1"
                                ? Get.off(() => RenterProfile())
                                : Get.off(() => MyProfileScreen());
                          } catch (e) {
                            Loader.hide();
                            log("expectation Caugch: 2 " + e.toString());
                          }
                        }

                        ////////////////////For Tests
                      },
                      child: Container(
                        height: 58,
                        width: res_width * 0.9,
                        child: Center(
                          child: Text(
                            'Save',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6AE02),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: res_height * 0.02),
            ],
          ),
        ),
      ),
    ),
    );
  }

  ImageProvider _profileImageProvider() {
    final path = imagesapi.toString().trim();
    final hasImage = path.isNotEmpty && path != "null";
    if (!hasImage) {
      return const AssetImage("assets/slicing/blankuser.jpeg");
    }
    final imageUrl = path.toLowerCase().startsWith('http') ? path : Url + path;
    return NetworkImage(imageUrl);
  }

  Txtfld(txt, _controller, hintText) {
    double res_width = MediaQuery.of(context).size.width;
    double res_height = MediaQuery.of(context).size.height;
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: res_height * 0.02),
          Text(
            txt,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E2E2E),
            ),
          ),
          SizedBox(height: res_height * 0.005),
          Container(
            height: 48,
            width: res_width * 0.9,
            child: TextField(
              maxLines: 1,
              controller: _controller,
              decoration: InputDecoration(
                hintText: hintText,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCECED3), width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCECED3), width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TxtfldforLocation(txt, _controller) {
    double res_width = MediaQuery.of(context).size.width;
    double res_height = MediaQuery.of(context).size.height;
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: res_height * 0.02),
          Text(
            txt,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E2E2E),
            ),
          ),
          SizedBox(height: res_height * 0.005),
          Container(
            height: 62,
            width: res_width * 0.9,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _onChanged();
                });
              },
              maxLines: 1,
              controller: _locationController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCECED3), width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCECED3), width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TxtfldforEmail(txt, _controller, placholder) {
    double res_width = MediaQuery.of(context).size.width;
    double res_height = MediaQuery.of(context).size.height;
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: res_height * 0.02),
          Text(
            txt,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E2E2E),
            ),
          ),
          SizedBox(height: res_height * 0.005),
          Container(
            height: 48,
            width: res_width * 0.9,
            child: TextField(
              readOnly: true,
              controller: _controller,
              decoration: InputDecoration(
                hintText: placholder,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCECED3), width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFCECED3), width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  var imagesapi = "null";
  var nameapi = "null";
  var locationapi = "null";
  var emailapi = "null";
  var back_image_api = "null";

  ////////
  Future getProductsApi(id) async {
    final response = await http.get(
      Uri.parse('${Url}/UserProfileGetById/${id}'),
    );
    var data = jsonDecode(response.body.toString());
    log(data.toString());
    if (data["data"].length != 0) {
      log(data["data"][0]["id"].toString());
    }

    setState(() {
      if (data["data"].length != 0) {
        imagesapi = data["data"][0]["image"].toString();
        nameapi = data["data"][0]["name"].toString();
        _nameController.text = data["data"][0]["name"].toString();
        _emailController.text = data["data"][0]["email"].toString();
        _locationController.text = data["data"][0]["address"].toString();
        _ShippingAddressController.text =
            data["data"][0]["shipping_address"].toString();
        back_image_api = data["data"][0]["back_image"].toString();
        Latitiude = data["data"][0]["latitude"].toString();
        Longitude = data["data"][0]["longitude"].toString();
      }
    });
    if (response.statusCode == 200) {
      if (data["data"].length != 0) {
        SharedPreferences updatePrefrences =
            await SharedPreferences.getInstance();

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
            'image',
            data["data"][0]["image"].toString(),
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
            'number',
            data["data"][0]["number"].toString(),
          );
        });
        return data;
      } else {
        return "No data";
      }
    }
    // Upload(File imageFile) async {
    //   var stream = new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    //     var length = await imageFile.length();

    //     var uri = Uri.parse(uploadURL);

    //    var request = new http.MultipartRequest("POST", uri);
    //     var multipartFile = new http.MultipartFile('file', stream, length,
    //         filename: basename(imageFile.path));
    //         //contentType: new MediaType('image', 'png'));

    //     request.files.add(multipartFile);
    //     var response = await request.send();
    //     response.stream.transform(utf8.decoder).listen((value) {
    //     });
    //   }
  }
}
