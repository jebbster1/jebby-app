import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart' as d;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jebby/views/widgets/address_autocomplete_field.dart';
import 'package:jebby/utils/google_places_address.dart';
import 'package:jebby/utils/profile_image.dart';
import 'package:jebby/utils/show_snackbar.dart';

import 'package:jebby/constants/app_url.dart';
import 'package:jebby/models/user_model.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../services/provider/sign_in_provider.dart';
import '../../../utils/overlay_support.dart';
import 'package:jebby/repositories/api_repository.dart';
import '../../../view_models/user_view_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
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
    getData();
    profileData(context);
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

  Future<void> _finishProfileSave() async {
    if (id != null && id!.isNotEmpty && mounted) {
      final row = await ApiRepository.shared.fetchUserProfileRow(id!);
      if (row != null) {
        await context.read<UserViewModel>().syncProfileFromRow(row);
      }
    }
    if (!mounted) return;
    Get.back(result: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showAppSuccessSnackbar('Profile updated successfully.');
    });
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

  TextEditingController _emailController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  var _locationController = TextEditingController();
  ParsedUsAddress? _resolvedAddress;
  var Latitiude;
  var Longitude;
  var uuid = new Uuid();
  var vuid = new Uuid();
  var selected = "standard";

  void _clearResolvedAddress() {
    setState(() {
      _resolvedAddress = const ParsedUsAddress();
      Latitiude = null;
      Longitude = null;
    });
  }

  String? _locationValidationError() {
    if (_locationController.text.trim().isEmpty) {
      return 'Please enter current location';
    }
    if (_resolvedAddress?.hasResolvedMapLocation != true) {
      return ParsedUsAddress.selectFromSuggestionsMessage;
    }
    return null;
  }

  Future<void> _applySelectedAddress(ParsedUsAddress address) async {
    setState(() {
      _resolvedAddress = address;
      _locationController.text = address.displayLine;
      if (address.hasCoordinates) {
        Latitiude = address.latitude!.toString();
        Longitude = address.longitude!.toString();
      } else {
        Latitiude = null;
        Longitude = null;
      }
    });
  }

  InputDecoration get _profileAddressDecoration => InputDecoration(
        hintText: 'Search for your address',
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: Colors.grey,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCECED3), width: 1),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCECED3), width: 1),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      );

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
    super.dispose();
  }

  TextEditingController stripeEmailController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SignInProvider>();
    final usp = context.watch<UserViewModel>();

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
                                        : !ProfileImage.isValidPath(back_image_api)
                                            ? Image.asset(
                                                "assets/images/placeholder.png",
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                ProfileImage.resolveUrl(AppUrl.baseUrlM, back_image_api)!,
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
                                      _image1 != null
                                          ? ClipOval(
                                              child: SizedBox(
                                                width: 100,
                                                height: 100,
                                                child: Image.file(
                                                  _image1!,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            )
                                          : ProfileImage.circularAvatar(
                                              radius: 50,
                                              baseUrl: AppUrl.baseUrlM,
                                              imagePath: imagesapi,
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
                      () {
                        final name = nameapi.toString().trim();
                        if (name.isNotEmpty) return name;
                        final spName = sp.name?.toString().trim() ?? '';
                        if (spName.isNotEmpty) return spName;
                        return fullname.toString();
                      }(),
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

                    SizedBox(height: res_height * 0.001),
                    Container(
                      width: res_width * 0.9,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: res_height * 0.02),
                          Text(
                            'Location',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E2E2E),
                            ),
                          ),
                          SizedBox(height: res_height * 0.005),
                          AddressAutocompleteField(
                            controller: _locationController,
                            resolvedAddress: _resolvedAddress,
                            onEditingStarted: _clearResolvedAddress,
                            onAddressSelected: _applySelectedAddress,
                            hint: 'Search for your address',
                            decoration: _profileAddressDecoration,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: res_height * 0.02),
                    GestureDetector(
                      onTap: () async {
                        log("pressed tap");
                        Loader.show();
                        if (_nameController.text.isEmpty) {
                          Loader.hide();
                          showAppErrorSnackbar(
                            'Please Enter Name',
                            title: 'Required',
                          );
                          return;
                        }
                        final locationError = _locationValidationError();
                        if (locationError != null) {
                          Loader.hide();
                          showAppErrorSnackbar(
                            locationError,
                            title: 'Required',
                          );
                          return;
                        }
                        if (!ProfileImage.isValidPath(imagesapi)) {
                          try {
                            if (_image == null) {
                              Loader.hide();
                              showAppErrorSnackbar(
                                'Please Upload Cover Picture',
                                title: 'Required',
                              );
                              return;
                            }
                            if (_image1 == null) {
                              Loader.hide();
                              showAppErrorSnackbar(
                                'Please Upload Profile Picture',
                                title: 'Required',
                              );
                              return;
                            } else {
                              String fileName = Uuid().v4();
                              String fileName1 = Uuid().v4();
                              if (role == "1") {
                                // vendor profile insert
                                d.FormData formData = new d.FormData.fromMap({
                                  'name': _nameController.text.toString(),
                                  'email': _emailController.text.toString(),
                                  'phone_number': '',
                                  'address':
                                      _locationController.text.toString(),
                                  'latitude': Latitiude,
                                  'longitude': Longitude,
                                  'user_id': id,
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
                                });
                                log(formData.fields.toString());

                                d.Response response =
                                    await ApiRepository.shared
                                        .submitUserProfileMultipart(
                                  formData,
                                  isUpdate: false,
                                );
                                log(response.statusCode.toString());
                                Loader.hide();
                                await _finishProfileSave();
                                //       content: new Text(
                              }
                              // client profile insert
                              else {
                                d.FormData formData = new d.FormData.fromMap({
                                  'name': _nameController.text.toString(),
                                  'email': _emailController.text.toString(),
                                  'phone_number': '',
                                  'address':
                                      _locationController.text.toString(),
                                  'latitude': Latitiude,
                                  'longitude': Longitude,
                                  'user_id': id,
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
                                });
                                log(formData.fields.toString());

                                d.Response response =
                                    await ApiRepository.shared
                                        .submitUserProfileMultipart(
                                  formData,
                                  isUpdate: false,
                                );
                                log(response.statusCode.toString());
                                Loader.hide();
                                await _finishProfileSave();
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
                                    'name': _nameController.text.toString(),
                                    'email': _emailController.text.toString(),
                                    'phone_number': '',
                                    'address':
                                        _locationController.text.toString(),
                                    'latitude': Latitiude,
                                    'longitude': Longitude,
                                    'user_id': id,
                                    "pics": 1,
                                    "file": await d.MultipartFile.fromFile(
                                      _image1!.path,
                                      filename: fileName1,
                                    ),
                                  });
                                } else if (_image1 == null && _image != null) {
                                  String fileName = p.basename(_image!.path);
                                  formData = new d.FormData.fromMap({
                                    'name': _nameController.text.toString(),
                                    'email': _emailController.text.toString(),
                                    'phone_number': '',
                                    'address':
                                        _locationController.text.toString(),
                                    'latitude': Latitiude,
                                    'longitude': Longitude,
                                    'user_id': id,
                                    "pics": 2,
                                    "file": await d.MultipartFile.fromFile(
                                      _image!.path,
                                      filename: fileName,
                                    ),
                                  });
                                } else if (_image1 == null && _image == null) {
                                  log("both images are null");
                                  formData = new d.FormData.fromMap({
                                    'name': _nameController.text.toString(),
                                    'email': _emailController.text.toString(),
                                    'phone_number': '',
                                    'address':
                                        _locationController.text.toString(),
                                    'latitude': Latitiude,
                                    'longitude': Longitude,
                                    'user_id': id,

                                    "pics": 1,
                                  });
                                } else {
                                  log("hellooooo22");
                                  String fileName = p.basename(_image!.path);
                                  String fileName1 = p.basename(_image1!.path);
                                  formData = new d.FormData.fromMap({
                                    'name': _nameController.text.toString(),
                                    'email': _emailController.text.toString(),
                                    'phone_number': '',
                                    'address':
                                        _locationController.text.toString(),
                                    'latitude': Latitiude,
                                    'longitude': Longitude,
                                    'user_id': id,
                                    "pics": 3,
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
                                  });
                                }
                                log(formData.fields.toString());
                              } else {
                                Loader.hide();
                                showAppErrorSnackbar(
                                  'Payment fields cannot be empty',
                                  title: 'Required',
                                );
                              }
                            } else {
                              if (_image == null && _image1 != null) {
                                String fileName1 = p.basename(_image1!.path);
                                formData = new d.FormData.fromMap({
                                  'name': _nameController.text.toString(),
                                  'email': _emailController.text.toString(),
                                  'phone_number': '',
                                  'address':
                                      _locationController.text.toString(),
                                  'latitude': Latitiude,
                                  'longitude': Longitude,
                                  'user_id': id,
                                  "pics": 1,
                                  "file": await d.MultipartFile.fromFile(
                                    _image1!.path,
                                    filename: fileName1,
                                  ),
                                });
                              } else if (_image1 == null && _image != null) {
                                String fileName = p.basename(_image!.path);
                                formData = new d.FormData.fromMap({
                                  'name': _nameController.text.toString(),
                                  'email': _emailController.text.toString(),
                                  'phone_number': '',
                                  'address':
                                      _locationController.text.toString(),
                                  'latitude': Latitiude,
                                  'longitude': Longitude,
                                  'user_id': id,
                                  "pics": 2,
                                  "file": await d.MultipartFile.fromFile(
                                    _image!.path,
                                    filename: fileName,
                                  ),
                                });
                              } else if (_image1 == null && _image == null) {
                                log("both images are null");
                                formData = new d.FormData.fromMap({
                                  'name': _nameController.text.toString(),
                                  'email': _emailController.text.toString(),
                                  'phone_number': '',
                                  'address':
                                      _locationController.text.toString(),
                                  'latitude': Latitiude,
                                  'longitude': Longitude,
                                  'user_id': id,

                                  "pics": 1,
                                });
                              } else {
                                log("hellooooo22");
                                String fileName = p.basename(_image!.path);
                                String fileName1 = p.basename(_image1!.path);
                                formData = new d.FormData.fromMap({
                                  'name': _nameController.text.toString(),
                                  'email': _emailController.text.toString(),
                                  'phone_number': '',
                                  'address':
                                      _locationController.text.toString(),
                                  'latitude': Latitiude,
                                  'longitude': Longitude,
                                  'user_id': id,
                                  "pics": 3,
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
                                });
                              }
                              log(formData.fields.toString());
                            }
                            d.Response response =
                                await ApiRepository.shared
                                    .submitUserProfileMultipart(
                              formData,
                              isUpdate: true,
                            );
                            log(response.statusCode.toString());
                            Loader.hide();
                            await _finishProfileSave();
                          } catch (e) {
                            Loader.hide();
                            log("expectation Caugch: 2 " + e.toString());
                          }
                        }

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

  var imagesapi = "";
  var nameapi = "";
  var locationapi = "";
  var emailapi = "";
  var back_image_api = "";

  Future getProductsApi(id) async {
    final row = await ApiRepository.shared.fetchUserProfileRow(id.toString());
    if (row == null) return 'No data';

    log(row.toString());
    if (mounted) {
      setState(() {
        final profileImage = row['profile_image']?.toString().trim() ?? '';
        imagesapi = ProfileImage.sanitizePath(profileImage);
        nameapi = row['name']?.toString() ?? '';
        _nameController.text = row['name']?.toString() ?? '';
        _emailController.text = row['email']?.toString() ?? '';
        _locationController.text = row['address']?.toString() ?? '';
        final coverImage = row['cover_image']?.toString().trim() ?? '';
        back_image_api = ProfileImage.sanitizePath(coverImage);
        Latitiude = row['latitude']?.toString();
        Longitude = row['longitude']?.toString();
        final addressText = row['address']?.toString() ?? '';
        if (addressText.isNotEmpty) {
          _resolvedAddress = ParsedUsAddress(
            formattedAddress: addressText,
            latitude: double.tryParse(Latitiude?.toString() ?? ''),
            longitude: double.tryParse(Longitude?.toString() ?? ''),
          );
        }
      });
    }

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return row;
    setState(() {
      prefs.setString('fullname', row['name']?.toString() ?? '');
      prefs.setString('email', row['email']?.toString() ?? '');
      prefs.setString(
        'profileImage',
        ProfileImage.sanitizePath(row['profile_image']?.toString()),
      );
      prefs.setString('address', row['address']?.toString() ?? '');
      prefs.setString('latitude', row['latitude']?.toString() ?? '');
      prefs.setString('longitude', row['longitude']?.toString() ?? '');
      prefs.setString('phoneNumber', row['phone_number']?.toString() ?? '');
    });
    return {'data': [row]};
  }
}
