import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jebby/Views/helper/colors.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart' as d;
import '../../../Services/provider/sign_in_provider.dart';
import '../../../model/getProductsByProductId.dart';
import '../../../model/productDeleteModelImage.dart';
import '../../../model/user_model.dart';
import '../../../res/app_url.dart';
import '../../../view_model/apiServices.dart';
import 'package:jebby/Views/widgets/address_autocomplete_field.dart';
import 'package:jebby/utils/api_headers.dart';
import 'package:jebby/utils/google_places_address.dart';
import 'package:jebby/utils/product_upload_filename.dart';
import 'package:jebby/utils/show_snackbar.dart';
import '../../../view_model/user_view_model.dart';
import '../../widgets/transport_options_section.dart';
import '../../../model/handoff_window.dart';

class EditProductScreen extends StatefulWidget {
  final dynamic category_id;
  final dynamic sub_category_id;
  final dynamic name;
  final dynamic price;
  final dynamic specifications;
  final dynamic description;
  final dynamic product_id;
  final dynamic images;
  final dynamic imageID;
  final dynamic delivery_charges;

  EditProductScreen({
    this.category_id,
    this.sub_category_id,
    this.name,
    this.price,
    this.specifications,
    this.description,
    this.product_id,
    this.images,
    this.imageID,
    this.delivery_charges,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  String Url = dotenv.env['baseUrlM'] ?? 'No url found';
  bool product_update_button = false;
  bool img_button = false;
  bool imgLoader = false;
  bool _offersPickup = true;
  bool _offersDelivery = false;
  List<HandoffWindow> _handoffWindows = [];
  String dropdownValue = 'One';
  bool switchnot = true;
  bool catLoader = true;
  bool catError = false;
  bool sub_catLoader = true;
  bool sub_catError = false;
  bool cats_loader = true;
  bool sub_cats_loader = true;
  late String dropdownvalue;
  late String sub_dropdownvalue;
  String selectedValue = "select";
  String sub_selectedvalue = "select";
  List<String> sub_items = [];
  List sub_items_id = [];
  List<String> items = [];
  List items_id = [];
  late var selected_id;
  late var selected_sub_id;
  late var sub_name;
  late var sub_id;
  late var sub_length;
  List<XFile> imageFileList = [];
  /// Gallery index to insert each pending upload at (`null` = append).
  List<int?> _uploadInsertAt = [];
  List imagesPath = [];
  List<String> _existingImageUrls = [];
  List<dynamic> _existingImageIds = [];
  final List<dynamic> _deletedImageIds = [];
  bool _imagesModified = false;
  List<dynamic> image_document = [];

  int get _totalImageCount => _existingImageUrls.length + imageFileList.length;
  bool get _hasImages => _totalImageCount > 0;

  TextEditingController nameController = TextEditingController();
  TextEditingController specsController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController rentPriceController = TextEditingController();
  TextEditingController deliverychargesController = TextEditingController();
  TextEditingController SecurityDepositeController = TextEditingController();
  final TextEditingController _deliveryRadiusController = TextEditingController();

  var pasd =
      ApiRepository.shared.getProductsByIdList?.data![0].availableFrom.toString();
  var paed =
      ApiRepository.shared.getProductsByIdList?.data![0].availableTo.toString();
  DateTime _calendarMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isSelectingEnd = false;

  var security_deposit =
      ApiRepository.shared.getProductsByIdList?.data![0].security_deposit
          .toString();

  // Index of the image currently shown in the big preview.
  int _activeImageIndex = 0;
  late var name_length;
  late var category_name;
  late var category_id;
  String? cat_value;
  String? sub_cat_value;

  bool productAvailabilitySwitch = true;

  // Location (for Location Based Delivery)
  final TextEditingController _locationController = TextEditingController();
  ParsedUsAddress? _resolvedLocation;
  String? locationLat;
  String? locationLng;

  void _clearResolvedLocation() {
    setState(() {
      _resolvedLocation = const ParsedUsAddress();
      locationLat = null;
      locationLng = null;
    });
  }

  Future<void> _applySelectedLocation(ParsedUsAddress address) async {
    setState(() {
      _resolvedLocation = address;
      _locationController.text = address.displayLine;
      if (address.hasCoordinates) {
        locationLat = address.latitude!.toString();
        locationLng = address.longitude!.toString();
      } else {
        locationLat = null;
        locationLng = null;
      }
    });
  }

  void _showFileSizeAlert(String message) {
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

  InputDecoration get _listingLocationDecoration => InputDecoration(
        hintText: 'Enter address',
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBlue, width: 1.5),
        ),
      );

  // Dropdown values shown in the second screenshot.
  String materialValue = "Wooden";
  String conditionValue = "New";
  String finishValue = "Simple Finish";
  String styleValue = "Minimal";
  String yearMadeValue = "2025";

  final List<String> _materialOptions = ["Wooden", "Plastic", "Metal", "Other"];
  final List<String> _conditionOptions = ["New", "Used", "Refurbished"];
  final List<String> _finishOptions = ["Simple Finish", "Glossy", "Matte"];
  final List<String> _styleOptions = ["Minimal", "Classic", "Modern"];
  final List<String> _yearOptions = [
    "2018",
    "2019",
    "2020",
    "2021",
    "2022",
    "2023",
    "2024",
    "2025",
  ];

  void _syncSpecsFromDropdowns() {
    // Keep backend compatibility: backend expects a single `specifications` string.
    specsController.text =
        "Material: $materialValue, Condition: $conditionValue, Finish: $finishValue, Style: $styleValue, Year Made: $yearMadeValue";
  }

  final DateFormat _rangeTitleFormat = DateFormat('MMM d');

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _availabilityStart() =>
      DateTime.tryParse(pasd.toString()) ?? DateTime.now();
  DateTime _availabilityEnd() =>
      DateTime.tryParse(paed.toString()) ?? DateTime.now();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isWithinSelectedRange(DateTime day) {
    final d = _dateOnly(day);
    final start = _dateOnly(_availabilityStart());
    final end = _dateOnly(_availabilityEnd());
    return !d.isBefore(start) && !d.isAfter(end);
  }

  DateTime _lastAllowedDate() {
    final now = DateTime.now();
    return DateTime(now.year + 5, now.month, now.day);
  }

  void _selectAvailabilityDay(DateTime day) {
    final today = _dateOnly(DateTime.now());
    final last = _dateOnly(_lastAllowedDate());
    if (day.isBefore(today) || day.isAfter(last)) return;

    final start = _availabilityStart();
    setState(() {
      if (!_isSelectingEnd) {
        pasd = DateFormat('yyyy-MM-dd').format(day);
        paed = DateFormat('yyyy-MM-dd').format(day);
        _isSelectingEnd = true;
        return;
      }
      if (day.isBefore(_dateOnly(start))) {
        pasd = DateFormat('yyyy-MM-dd').format(day);
        paed = DateFormat('yyyy-MM-dd').format(day);
      } else {
        paed = DateFormat('yyyy-MM-dd').format(day);
        _isSelectingEnd = false;
      }
    });
  }

  void _shiftCalendarMonth(int delta) {
    final now = DateTime.now();
    final earliest = DateTime(now.year, now.month);
    final latest = DateTime(_lastAllowedDate().year, _lastAllowedDate().month);
    final next = DateTime(_calendarMonth.year, _calendarMonth.month + delta);
    if (next.isBefore(earliest) || next.isAfter(latest)) return;
    setState(() => _calendarMonth = next);
  }

  void initState() {
    assign();
    getCatId();
    getSubCatID();
    getSubCategory(selected_id);
    getData();
    profileData(context);
    getCategory();
    super.initState();
  }

  void assign() {
    _loadExistingImages();
    pasd =
        ApiRepository.shared.getProductsByIdList?.data![0].availableFrom.toString();
    paed = ApiRepository.shared.getProductsByIdList?.data![0].availableTo.toString();
    final productData = ApiRepository.shared.getProductsByIdList?.data![0];
    final transport = productData?.transport;
    _offersPickup = transport?.pickup ?? productData?.hasPickup ?? true;
    _offersDelivery = transport?.delivery ?? productData?.hasDelivery ?? false;
    _handoffWindows = transport?.handoffWindows ?? [];
    _deliveryRadiusController.text =
        transport?.deliveryRadiusMiles?.toString() ?? '';

    nameController.text = widget.name;
    specsController.text = widget.specifications;
    descriptionController.text = widget.description;
    rentPriceController.text = widget.price.toString();
    selected_id = widget.category_id.toString();
    selected_sub_id = widget.sub_category_id.toString();
    deliverychargesController.text = widget.delivery_charges;
    SecurityDepositeController.text = security_deposit.toString();
    final data0 = ApiRepository.shared.getProductsByIdList?.data?[0];
    if (data0 != null) {
      final listingAddress = data0.address?.toString().trim() ?? '';
      if (listingAddress.isNotEmpty) {
        _locationController.text = listingAddress;
        _resolvedLocation = ParsedUsAddress(
          formattedAddress: listingAddress,
          latitude: double.tryParse(data0.latitude?.toString() ?? ''),
          longitude: double.tryParse(data0.longitude?.toString() ?? ''),
        );
      }
      if (data0.latitude != null) {
        locationLat = data0.latitude.toString();
      }
      if (data0.longitude != null) {
        locationLng = data0.longitude.toString();
      }
    }
  }

  void _markImagesModified() => _imagesModified = true;

  void _loadExistingImages() {
    _existingImageUrls = [];
    _existingImageIds = [];
    _deletedImageIds.clear();
    _uploadInsertAt.clear();
    _imagesModified = false;

    final rawImages = widget.images;
    if (rawImages is List) {
      for (final item in rawImages) {
        if (item == null) continue;
        final path = item.toString().trim();
        if (path.isNotEmpty) _existingImageUrls.add(path);
      }
    }

    final rawIds = widget.imageID;
    if (rawIds is List) {
      _existingImageIds.addAll(rawIds);
    }

    if (_existingImageUrls.isEmpty) {
      final data = ApiRepository.shared.getProductsByIdList?.data;
      if (data != null && data.length > 1 && data[1].images != null) {
        for (final img in data[1].images!) {
          final path = img.path?.toString().trim() ?? '';
          if (path.isNotEmpty) _existingImageUrls.add(path);
          if (img.id != null) _existingImageIds.add(img.id);
        }
      }
    }

    while (_existingImageIds.length < _existingImageUrls.length) {
      _existingImageIds.add(null);
    }
  }

  String _remoteImageUrl(String path) {
    if (path.startsWith('http')) return path;
    return '${AppUrl.baseUrlM}$path';
  }

  Widget _buildImageAt(
    int index, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (index < _existingImageUrls.length) {
      return CachedNetworkImage(
        imageUrl: _remoteImageUrl(_existingImageUrls[index]),
        width: width,
        height: height,
        fit: fit,
        placeholder:
            (_, __) => Container(
              width: width,
              height: height,
              color: Colors.grey.shade300,
            ),
        errorWidget:
            (_, __, ___) => Container(
              width: width,
              height: height,
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image_outlined),
            ),
      );
    }

    final localIndex = index - _existingImageUrls.length;
    return Image.file(
      File(imageFileList[localIndex].path),
      width: width,
      height: height,
      fit: fit,
    );
  }

  void _adjustActiveIndexAfterRemoval(int removedIndex) {
    if (_activeImageIndex > removedIndex) {
      _activeImageIndex--;
    } else if (_activeImageIndex >= _totalImageCount) {
      _activeImageIndex = _totalImageCount > 0 ? _totalImageCount - 1 : 0;
    }
  }

  void _removeImageAt(int index) {
    if (index < _existingImageUrls.length) {
      if (index < _existingImageIds.length && _existingImageIds[index] != null) {
        _deletedImageIds.add(_existingImageIds[index]);
      }
      _existingImageUrls.removeAt(index);
      if (index < _existingImageIds.length) {
        _existingImageIds.removeAt(index);
      }
    } else {
      final localIndex = index - _existingImageUrls.length;
      if (localIndex >= 0 && localIndex < imageFileList.length) {
        if (localIndex < imagesPath.length) {
          imagesPath.removeAt(localIndex);
        }
        imageFileList.removeAt(localIndex);
        if (localIndex < _uploadInsertAt.length) {
          _uploadInsertAt.removeAt(localIndex);
        }
      }
    }
    _markImagesModified();
    _adjustActiveIndexAfterRemoval(index);
  }

  @override
  void dispose() {
    _locationController.dispose();
    _deliveryRadiusController.dispose();
    super.dispose();
  }

  getCatId() {
    ApiRepository.shared.CategoryId(
      (List) => {
        if (this.mounted)
          {
            if (List.status == 0)
              {
                setState(() {
                  catLoader = false;
                  catError = false;
                }),
              }
            else
              {
                setState(() {
                  cat_value =
                      ApiRepository
                          .shared
                          .getCategoryByIdModelList!
                          .data![0]
                          .name
                          .toString();
                  catLoader = false;
                  catError = false;
                }),
              },
          },
      },
      (error) => {
        if (error != null)
          {
            setState(() {
              catLoader = true;
              catError = true;
            }),
          },
      },
      widget.category_id.toString(),
    );
  }

  getSubCatID() {
    ApiRepository.shared.SubCategoryId(
      (List) => {
        if (this.mounted)
          {
            if (List.status == 0)
              {
                setState(() {
                  sub_catLoader = false;
                  sub_catError = false;
                }),
              }
            else
              {
                setState(() {
                  sub_cat_value =
                      ApiRepository
                          .shared
                          .getSubCategoryByIdModelList!
                          .data![0]
                          .name
                          .toString();
                  sub_catLoader = false;
                  sub_catError = false;
                }),
              },
          },
      },
      (error) => {
        if (error != null)
          {
            setState(() {
              sub_catLoader = true;
              sub_catError = true;
            }),
          },
      },
      widget.sub_category_id.toString(),
    );
  }

  getCategory() {
    ApiRepository.shared.getCategoryList(
      (List) => {
        if (this.mounted)
          {
            if (List.status == 0)
              {
                setState(() {
                  cats_loader = false;
                }),
              }
            else
              {
                name_length = ApiRepository.shared.categoryList?.data?.length,
                for (int i = 0; i < name_length; i++)
                  {
                    category_name =
                        ApiRepository.shared.categoryList?.data?[i].name,
                    category_id =
                        ApiRepository.shared.categoryList?.data?[i].id,
                    items.add(category_name.toString()),
                    items_id.add(category_id),
                  },
                setState(() {
                  dropdownValue = items.first;
                  cats_loader = false;
                }),
              },
          },
      },
      (error) => {
        if (this.mounted)
          {
            if (error != null)
              {
                setState(() {
                  cats_loader = false;
                }),
              },
          },
      },
    );
    ApiRepository.shared.checkApiStatus(true, "categoryList");
  }

  getSubCategory(id) {
    ApiRepository.shared.getSubCategoryList(
      (list) => {
        if (this.mounted)
          {
            if (list.status == 0)
              {
                setState(() {
                  sub_items = ["No Category Found"];
                  sub_cats_loader = false;
                }),
              }
            else
              {
                sub_length = ApiRepository.shared.subCategoryList?.data?.length,
                sub_items = [],
                sub_items_id = [],
                for (int i = 0; i < sub_length!; i++)
                  {
                    sub_name =
                        ApiRepository.shared.subCategoryList?.data?[i].name,
                    sub_id = ApiRepository.shared.subCategoryList?.data?[i].id,
                    sub_items.add(sub_name.toString()),
                    sub_items_id.add(sub_id),
                  },
                setState(() {
                  sub_cats_loader = false;
                  final targetId =
                      selected_sub_id?.toString() ??
                      widget.sub_category_id.toString();
                  final idx = sub_items_id.indexWhere(
                    (itemId) => itemId.toString() == targetId,
                  );
                  if (idx >= 0) {
                    selected_sub_id = sub_items_id[idx];
                    sub_cat_value = sub_items[idx];
                    sub_dropdownvalue = sub_items[idx];
                  } else if (sub_cat_value != null &&
                      sub_items.contains(sub_cat_value)) {
                    final nameIdx = sub_items.indexOf(sub_cat_value!);
                    selected_sub_id = sub_items_id[nameIdx];
                    sub_dropdownvalue = sub_cat_value!;
                  } else if (sub_items.isNotEmpty) {
                    selected_sub_id = sub_items_id.first;
                    sub_cat_value = sub_items.first;
                    sub_dropdownvalue = sub_items.first;
                  }
                }),
              },
          },
      },
      (error) => {
        if (error != null)
          {
            setState(() {
              sub_cats_loader = true;
            }),
          },
      },
      id.toString(),
    );
  }

  void selectImages() async {
    try {
      List<XFile>? selectedImages = await ImagePicker().pickMultiImage();
      if (selectedImages.isNotEmpty) {
        const int maxImages = 4;
        final remaining = maxImages - _totalImageCount;
        if (remaining <= 0) return;

        final imagesToAdd = selectedImages.take(remaining).toList();
        var rejectedOversized = false;
        for (XFile image in imagesToAdd) {
          final tempImage = File(image.path);
          final fileSize = await tempImage.length();
          if (fileSize > 7 * 1024 * 1024) {
            rejectedOversized = true;
            continue;
          }
          imagesPath.add(tempImage);
          imageFileList.add(image);
          _uploadInsertAt.add(null);
        }
        if (rejectedOversized) {
          _showFileSizeAlert(
            'Selected file is larger than 7MB. Please select a smaller file.',
          );
        }
        if (imageFileList.isNotEmpty) {
          _markImagesModified();
          _activeImageIndex = _totalImageCount - 1;
        }
      }
      setState(() {});
    } catch (e) {}
  }

  // Adds exactly one image (matches the "+ Add" behavior in screenshots).
  void addOneImage() async {
    try {
      const int maxImages = 4;
      if (_totalImageCount >= maxImages) return;

      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (image == null) return;
      final tempImage = File(image.path);
      final fileSize = await tempImage.length();
      if (fileSize > 7 * 1024 * 1024) {
        _showFileSizeAlert(
          'Selected file is larger than 7MB. Please select a smaller file.',
        );
        return;
      }
      setState(() {
        imagesPath.add(tempImage);
        imageFileList.add(image);
        _uploadInsertAt.add(null);
        _markImagesModified();
        _activeImageIndex = _totalImageCount - 1;
      });
    } catch (_) {}
  }

  // Replaces the currently selected image in the preview.
  void replaceFirstImage() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (image == null) return;
      final tempImage = File(image.path);
      final fileSize = await tempImage.length();
      if (fileSize > 7 * 1024 * 1024) {
        _showFileSizeAlert(
          'Selected file is larger than 7MB. Please select a smaller file.',
        );
        return;
      }
      setState(() {
        _markImagesModified();
        if (!_hasImages) {
          imagesPath = [tempImage];
          imageFileList = [image];
          _uploadInsertAt = [0];
          _activeImageIndex = 0;
          return;
        }

        final idx = _activeImageIndex.clamp(0, _totalImageCount - 1);
        if (idx < _existingImageUrls.length) {
          if (idx < _existingImageIds.length && _existingImageIds[idx] != null) {
            _deletedImageIds.add(_existingImageIds[idx]);
          }
          _existingImageUrls.removeAt(idx);
          if (idx < _existingImageIds.length) {
            _existingImageIds.removeAt(idx);
          }
          imagesPath.add(tempImage);
          imageFileList.add(image);
          _uploadInsertAt.add(idx);
          _activeImageIndex = _totalImageCount - 1;
        } else {
          final localIdx = idx - _existingImageUrls.length;
          imagesPath[localIdx] = tempImage;
          imageFileList[localIdx] = image;
        }
      });
    } catch (_) {}
  }

  Future<GetProductsByProductId> getProductsById(
    onResponse(GetProductsByProductId List),
    onError(error),
    id,
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.getProductsByID + id),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        var data = GetProductsByProductId.fromJson(jsonDecode(response.body));

        ApiRepository.shared.getProductByProductId(data);
        onResponse(data);

        return data;
      } catch (error) {
        onError(error.toString());
      }
    } else if (response.statusCode == 400) {
      onError("You are not in Range");
    } else if (response.statusCode == 500) {
      onError("Internal Server Error");
    }

    return GetProductsByProductId();
  }

  Future<ProductDeleteImageModel> deleteProductImage(id) async {
    setState(() {
      imgLoader = true;
    });
    final request = json.encode(<String, dynamic>{
      "id": id,
      "product_id": widget.product_id.toString(),
    });

    final response = await http.post(
      Uri.parse(AppUrl.productDeleteImage),
      body: request,
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        getProductsById(
          (List) => {
            if (this.mounted)
              {
                if (List.data?.length == 0)
                  {}
                else
                  {
                    setState(() {
                      imgLoader = false;
                    }),
                  },
              },
          },
          (error) {},
          widget.product_id.toString(),
        );
      } catch (error) {
      }
    } else if (response.statusCode == 400) {
    } else if (response.statusCode == 500) {
    }

    return ProductDeleteImageModel();
  }

  Future<bool> _deleteRemoteImageSilently(String imageId) async {
    final request = json.encode(<String, dynamic>{
      "id": imageId,
      "product_id": widget.product_id.toString(),
    });
    final response = await http.post(
      Uri.parse(AppUrl.productDeleteImage),
      body: request,
      headers: await ApiHeaders.json(),
    );
    return response.statusCode == 200;
  }

  Future<bool> _syncProductImages() async {
    if (!_imagesModified) return true;

    try {
      final idsToDelete = List<dynamic>.from(_deletedImageIds)
        ..sort((a, b) {
          final ai = int.tryParse(a?.toString() ?? '') ?? -1;
          final bi = int.tryParse(b?.toString() ?? '') ?? -1;
          return bi.compareTo(ai);
        });
      for (final imageId in idsToDelete) {
        if (imageId == null) continue;
        final deleted = await _deleteRemoteImageSilently(imageId.toString());
        if (!deleted) return false;
      }
      _deletedImageIds.clear();

      if (imageFileList.isNotEmpty) {
        image_document = [];
        for (final file in imageFileList) {
          image_document.add(
            await d.MultipartFile.fromFile(
              file.path,
              filename: productUploadFilename(file.path),
            ),
          );
        }

        final formData = d.FormData();
        formData.fields
          ..add(MapEntry('id', widget.product_id.toString()))
          ..add(MapEntry('insert_at', jsonEncode(_uploadInsertAt)));
        for (final part in image_document) {
          formData.files.add(MapEntry('file', part));
        }

        final response = await d.Dio().post(
          AppUrl.productUpdateImage,
          data: formData,
          options: d.Options(
            contentType: 'multipart/form-data',
            headers: await ApiHeaders.authOnly(),
          ),
        );
        if (response.statusCode != 200) return false;

        imageFileList.clear();
        imagesPath.clear();
        _uploadInsertAt.clear();
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  updateImage() async {
    setState(() {
      img_button = true;
    });
    image_document = [];
    if (imagesPath.length > 0) {
      for (int i = 0; i < imagesPath.length; i++) {
        var path = imagesPath[i].path;
        image_document.add(
          await d.MultipartFile.fromFile(
            path,
            filename: productUploadFilename(path),
          ),
        );
      }
      try {
        setState(() {
          imagesPath = []; //for displaying images at grid
          imageFileList = []; //for displaying images at grid
        });
        getProductsById(
          (list) {
            if (this.mounted) {
              if (list.status == 0) {
              } else {
                setState(() {
                  img_button = false;
                });
              }
            }
          },
          (error) {},
          widget.product_id.toString(),
        );
        showAppSuccessSnackbar('Images updated.');
      } catch (e) {
        showAppErrorSnackbar('Error uploading images.');
      }
    } 
    else {
      showAppErrorSnackbar('Select images to upload.', title: 'Required');
    }

    setState(() {
      img_button = false;
    });
  }

  void _showError(String message) =>
      showAppErrorSnackbar(message, title: 'Required');

  bool _isValidIntPrice(String value, {required bool required}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return !required;
    final parsed = int.tryParse(trimmed);
    return parsed != null && parsed >= 0;
  }

  prodUpdate() async {
    setState(() {
      product_update_button = true;
    });

    if (!_hasImages) {
      _showError('You need to select at least 1 image');
      setState(() => product_update_button = false);
      return;
    }

    if (!_isValidIntPrice(rentPriceController.text, required: true)) {
      _showError('Please enter a valid rent price');
      setState(() => product_update_button = false);
      return;
    }
    if (!_isValidIntPrice(SecurityDepositeController.text, required: true)) {
      _showError('Please enter a valid security deposit');
      setState(() => product_update_button = false);
      return;
    }
    if (_offersDelivery &&
        !_isValidIntPrice(deliverychargesController.text, required: true)) {
      _showError('Please enter a valid delivery fee');
      setState(() => product_update_button = false);
      return;
    }

    if (!_offersPickup && !_offersDelivery) {
      _showError('Enable pickup and/or delivery');
      setState(() => product_update_button = false);
      return;
    }

    if (_offersDelivery) {
      final radius = int.tryParse(_deliveryRadiusController.text.trim());
      if (radius == null || radius <= 0) {
        _showError('Please enter a delivery radius (miles)');
        setState(() => product_update_button = false);
        return;
      }
    }

    if (_handoffWindows.isEmpty) {
      _showError('Please add at least one handoff window');
      setState(() => product_update_button = false);
      return;
    }

    if (DateTime.parse(
          pasd.toString(),
        ).isAfter(DateTime.parse(paed.toString())) ||
        DateTime.parse(
          pasd.toString(),
        ).isAtSameMomentAs(DateTime.parse(paed.toString()))) {
      _showError('End Date must be greater than Start Date');
      setState(() => product_update_button = false);
      return;
    }

    if (id != null &&
        widget.category_id != null &&
        selected_sub_id.toString().isNotEmpty &&
        nameController.text.toString().isNotEmpty &&
        rentPriceController.text.toString().isNotEmpty &&
        SecurityDepositeController.text.isNotEmpty &&
        (!_offersDelivery || deliverychargesController.text.toString().isNotEmpty) &&
        specsController.text.toString().isNotEmpty &&
        descriptionController.text.toString().isNotEmpty &&
        widget.product_id != null &&
        widget.product_id != null &&
        id != null &&
        selected_sub_id != null &&
        pasd != null &&
        paed != null
    ) {
      if (_locationController.text.trim().isEmpty ||
          _resolvedLocation?.hasResolvedMapLocation != true) {
        _showError(ParsedUsAddress.selectFromSuggestionsMessage);
        setState(() => product_update_button = false);
        return;
      }

      if (_imagesModified) {
        final imagesSynced = await _syncProductImages();
        if (!imagesSynced) {
          if (mounted) {
            showAppErrorSnackbar('Failed to update product images');
          }
          setState(() => product_update_button = false);
          return;
        }
      }

      await ApiRepository.shared.productUpdate(
        id,
        selected_id,
        selected_sub_id.toString(),
        nameController.text.toString(),
        rentPriceController.text.toString(),
        specsController.text.toString(),
        descriptionController.text.toString(),
        widget.product_id,
        widget.product_id,
        id,
        _offersPickup ? 1 : 0,
        _offersDelivery ? 1 : 0,
        pasd,
        paed,
        deliverychargesController.text.toString(),
        SecurityDepositeController.text.toString(),
        _locationController.text.trim(),
        locationLat ?? "",
        locationLng ?? "",
        _handoffWindows,
        _deliveryRadiusController.text.trim(),
      );
    } else {
      _showError("Fields can't be empty");
      setState(() => product_update_button = false);
      return;
    }

    setState(() {
      product_update_button = false;
    });
  }

  Future<UserModel> getUserDate() => UserViewModel().getUser();

  Future getData() async {
    final sp = context.read<SignInProvider>();
    final usp = context.read<UserViewModel>();
    usp.getUser();
    sp.getDataFromSharedPreferences();
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
          fullname = value.name.toString();
          email = value.email.toString();
          role = value.role.toString();
        })
        .onError((error, stackTrace) {
          if (kDebugMode) {}
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
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
        title: Text(
          "Edit Product",
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            /// PRODUCT IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      !_hasImages
                          ? Colors.grey.shade300
                          : Colors.white,
                  border:
                      !_hasImages
                          ? Border.all(color: Colors.grey.shade400, width: 1)
                          : null,
                ),
                child: Stack(
                  children: [
                    if (_hasImages)
                      Positioned.fill(
                        child: _buildImageAt(
                          _activeImageIndex.clamp(0, _totalImageCount - 1),
                          fit: BoxFit.cover,
                        ),
                      ),

                    if (!_hasImages)
                      Center(
                        child: _glassPill(
                          onTap: addOneImage,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          backgroundColor: const Color(
                            0xFF000000,
                          ).withOpacity(0.25),
                          borderColor: kprimaryColor.withOpacity(0.95),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Add Image",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_hasImages && _totalImageCount < 4)
                      Positioned(
                        top: 15,
                        left: 15,
                        child: _glassPill(
                          onTap: replaceFirstImage,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          backgroundColor: const Color(
                            0xFF000000,
                          ).withOpacity(0.25),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.upload,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Replace Image",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (_hasImages && _totalImageCount < 4)
                      Positioned(
                        bottom: 15,
                        right: 15,
                        child: _glassPill(
                          onTap: addOneImage,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          backgroundColor: const Color(
                            0xFF000000,
                          ).withOpacity(0.25),
                          borderColor: kprimaryColor.withOpacity(0.95),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Add",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.add,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: !_hasImages ? 8 : 20),
            if (_hasImages)
              SizedBox(
                height: 86,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      _totalImageCount < 4
                          ? _totalImageCount + 1
                          : _totalImageCount,
                  itemBuilder: (context, index) {
                    const maxImages = 4;
                    final showAddTile =
                        _totalImageCount < maxImages &&
                        index == _totalImageCount;
                    if (showAddTile) {
                      final activeDots =
                          _totalImageCount < 3 ? _totalImageCount : 3;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: addOneImage,
                          child: Container(
                            width: 92,
                            height: 86,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 26,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(3, (i) {
                                    return Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            i < activeDots
                                                ? kprimaryColor
                                                : Colors.grey.shade400,
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    final imageIndex = index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _activeImageIndex = imageIndex;
                                });
                              },
                              child: Opacity(
                                opacity: 0.78,
                                child: _buildImageAt(
                                  imageIndex,
                                  width: 92,
                                  height: 86,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _removeImageAt(imageIndex);
                                });
                              },
                              child: CircleAvatar(
                                radius: 13,
                                backgroundColor: Colors.black,
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            
            SizedBox(height: 10),
            /// PRODUCT NAME
            Text(
              "Product Name",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 8),

            SizedBox(
              height: 48,
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: kprimaryColor, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),

            SizedBox(height: 20),

            /// DESCRIPTION
            Text(
              "Description",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 8),

            SizedBox(
              height: 80,
              child: TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: kprimaryColor, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),

            SizedBox(height: 20),

            /// RENT PRICE
            Text(
              "Rent Price",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 8),

            SizedBox(
              height: 48,
              child: TextField(
                controller: rentPriceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 46,
                    minHeight: 48,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 6),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1E88E5),
                      ),
                      child: const Icon(
                        Icons.attach_money,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(8, 10, 14, 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: kprimaryColor, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),

            SizedBox(height: 20),

            /// SECURITY + DELIVERY
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Deposit',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: TextField(
                          controller: SecurityDepositeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 46,
                              minHeight: 48,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 6,
                              ),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF1E88E5),
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            contentPadding: const EdgeInsets.fromLTRB(
                              8,
                              10,
                              14,
                              10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: kprimaryColor,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Charges',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        height: 48,
                        child: TextField(
                          controller: deliverychargesController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 46,
                              minHeight: 48,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 6,
                              ),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF1E88E5),
                                ),
                                child: const Icon(
                                  Icons.local_shipping_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            contentPadding: const EdgeInsets.fromLTRB(
                              8,
                              10,
                              14,
                              10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: kprimaryColor,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            /// CATEGORY
            Text(
              "Category",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 8),

            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                value:
                    (cat_value != null && items.contains(cat_value))
                        ? cat_value
                        : null,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF8F9098),
                ),
                items:
                    items.map((String value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(
                          value,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1B1B1F),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    cat_value = value;
                  });
                },
              ),
            ),

            SizedBox(height: 20),

            /// SUB CATEGORY
            Text(
              "Sub Category",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 8),

            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                value:
                    (sub_cat_value != null &&
                            sub_items.contains(sub_cat_value))
                        ? sub_cat_value
                        : null,
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF8F9098),
                ),
                items:
                    sub_items.map((String value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(
                          value,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1B1B1F),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    sub_cat_value = value;
                  });
                },
              ),
            ),

            SizedBox(height: 20),

            TransportOptionsSection(
              pickupEnabled: _offersPickup,
              deliveryEnabled: _offersDelivery,
              deliveryFeeController: deliverychargesController,
              radiusController: _deliveryRadiusController,
              windows: _handoffWindows,
              onPickupChanged: (value) => setState(() {
                _offersPickup = value;
                if (!value && !_offersDelivery) _offersDelivery = true;
              }),
              onDeliveryChanged: (value) => setState(() {
                _offersDelivery = value;
                if (!value && !_offersPickup) _offersPickup = true;
              }),
              onWindowsChanged: (windows) => setState(() => _handoffWindows = windows),
            ),

            SizedBox(height: 14),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Listing location",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.black,
                ),
                textAlign: TextAlign.left,
              ),
            ),
            SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Where renters pick up this item, or where you deliver from.",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(height: 6),
            AddressAutocompleteField(
              controller: _locationController,
              resolvedAddress: _resolvedLocation,
              onEditingStarted: _clearResolvedLocation,
              onAddressSelected: _applySelectedLocation,
              hint: 'Enter address',
              decoration: _listingLocationDecoration,
            ),
            SizedBox(height: 14),

            _buildAvailabilityCalendar(MediaQuery.of(context).size.width),

            SizedBox(height: 18),

            // Product Specifications
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Product Specifications',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "We provide sturdy and comfortable wood",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            _specDropdown("Material", materialValue, _materialOptions, (v) {
              setState(() {
                materialValue = v!;
                _syncSpecsFromDropdowns();
              });
            }),
            SizedBox(height: 12),
            _specDropdown("Condition", conditionValue, _conditionOptions, (v) {
              setState(() {
                conditionValue = v!;
                _syncSpecsFromDropdowns();
              });
            }),
            SizedBox(height: 12),
            _specDropdown("Finish", finishValue, _finishOptions, (v) {
              setState(() {
                finishValue = v!;
                _syncSpecsFromDropdowns();
              });
            }),
            SizedBox(height: 12),
            _specDropdown("Style", styleValue, _styleOptions, (v) {
              setState(() {
                styleValue = v!;
                _syncSpecsFromDropdowns();
              });
            }),
            SizedBox(height: 12),
            _specDropdown("Year Made", yearMadeValue, _yearOptions, (v) {
              setState(() {
                yearMadeValue = v!;
                _syncSpecsFromDropdowns();
              });
            }),
            SizedBox(height: 16),
          ],
        ),
      ),

      bottomNavigationBar: Material(
        elevation: 12,
        shadowColor: Colors.black26,
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: product_update_button ? null : prodUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kprimaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: product_update_button
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Update Product',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassPill({
    required VoidCallback onTap,
    required Widget child,
    required EdgeInsets padding,
    Color? backgroundColor,
    Color? borderColor,
    double blurSigma = 10,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(30)),
  }) {
    final bg = backgroundColor ?? const Color(0xFF517A94).withOpacity(0.22);
    final bd = borderColor;

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: borderRadius,
            border: bd == null ? null : Border.all(color: bd, width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }

  Widget _specDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 6),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              underline: const SizedBox(),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF8F9098),
              ),
              items:
                  options
                      .map(
                        (v) => DropdownMenuItem<String>(
                          value: v,
                          child: Text(
                            v,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF1B1B1F),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: onChanged,
              style: GoogleFonts.inter(
                color: const Color(0xFF1B1B1F),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityCalendar(double width) {
    final today = _dateOnly(DateTime.now());
    final lastAllowed = _lastAllowedDate();
    final start = _dateOnly(_availabilityStart());
    final end = _dateOnly(_availabilityEnd());
    final isSingleDaySelection = _isSameDay(start, end);
    final monthFirst = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final int leadingEmpty = monthFirst.weekday % 7;
    final int daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rental Period',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: const Color(0xFF1B1B1F),
              ),
            ),
            const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF0A143D)),
              const SizedBox(width: 10),
              Text(
                '${_rangeTitleFormat.format(start)} - ${_rangeTitleFormat.format(end)}',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A143D),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _monthButton(Icons.chevron_left, () => _shiftCalendarMonth(-1)),
                  Expanded(
                    child: Center(
                      child: Text(
                        DateFormat('MMMM yyyy').format(_calendarMonth),
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  _monthButton(Icons.chevron_right, () => _shiftCalendarMonth(1)),
                ],
              ),
              Row(
                children: const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                    .map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(fontSize: 12, color: Color(0xFF59689A))))))
                    .toList(),
              ),
              const SizedBox(height: 4),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leadingEmpty + daysInMonth,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 0,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (context, index) {
                  if (index < leadingEmpty) return const SizedBox.shrink();
                  final dayNum = index - leadingEmpty + 1;
                  final day = DateTime(_calendarMonth.year, _calendarMonth.month, dayNum);
                  final disabled = day.isBefore(today) || day.isAfter(lastAllowed);
                  final isStart = _isSameDay(day, start);
                  final isEnd = _isSameDay(day, end);
                  final inRange = _isWithinSelectedRange(day);
                  final row = index ~/ 7;

                  bool hasLeftInRange = false;
                  if (index > 0 && (index - 1) ~/ 7 == row) {
                    final prev = dayNum - 1;
                    if (prev >= 1) {
                      final prevDay = DateTime(
                        _calendarMonth.year,
                        _calendarMonth.month,
                        prev,
                      );
                      final prevDisabled =
                          prevDay.isBefore(today) || prevDay.isAfter(lastAllowed);
                      hasLeftInRange = !prevDisabled && _isWithinSelectedRange(prevDay);
                    }
                  }

                  bool hasRightInRange = false;
                  if ((index + 1) ~/ 7 == row) {
                    final next = dayNum + 1;
                    if (next <= daysInMonth) {
                      final nextDay = DateTime(
                        _calendarMonth.year,
                        _calendarMonth.month,
                        next,
                      );
                      final nextDisabled =
                          nextDay.isBefore(today) || nextDay.isAfter(lastAllowed);
                      hasRightInRange = !nextDisabled && _isWithinSelectedRange(nextDay);
                    }
                  }

                  Color textColor = const Color(0xFF0A143D);
                  BoxDecoration? rangeDeco;
                  BoxDecoration? dayDeco;
                  Alignment dayAlignment = Alignment.center;
                  if (disabled) {
                    textColor = const Color(0xFFB8BED1);
                  } else if (inRange && !isSingleDaySelection) {
                    rangeDeco = BoxDecoration(
                      color: const Color(0xFFDCE1EB),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(hasLeftInRange ? 0 : 10),
                        bottomLeft: Radius.circular(hasLeftInRange ? 0 : 10),
                        topRight: Radius.circular(hasRightInRange ? 0 : 10),
                        bottomRight: Radius.circular(hasRightInRange ? 0 : 10),
                      ),
                    );
                  }
                  if (!disabled && (isStart || isEnd)) {
                    dayDeco = BoxDecoration(
                      color: const Color(0xFF0A143D),
                      borderRadius: BorderRadius.circular(10),
                    );
                    textColor = Colors.white;
                    if (isStart && hasRightInRange) {
                      dayAlignment = Alignment.centerLeft;
                    } else if (isEnd && hasLeftInRange) {
                      dayAlignment = Alignment.centerRight;
                    }
                  }

                  const double dayExtent = 30;
                  return GestureDetector(
                    onTap: disabled ? null : () => _selectAvailabilityDay(day),
                    child: Container(
                      decoration: rangeDeco,
                      alignment: dayAlignment,
                      child: Container(
                        width: dayExtent,
                        height: dayExtent,
                        decoration: dayDeco,
                        alignment: Alignment.center,
                        child: Text(
                          '$dayNum',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: (isStart || isEnd) ? FontWeight.w700 : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(
                _isSelectingEnd
                    ? 'Select an end date'
                    : 'Select a start date to adjust your range',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF72747A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'From: ${DateFormat('MM/dd/yyyy').format(_availabilityStart())}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF72747A),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'To: ${DateFormat('MM/dd/yyyy').format(_availabilityEnd())}',
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF72747A),
                ),
              ),
            ),
          ],
        ),
      ],
    )));
  }

  Widget _monthButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 22, color: const Color(0xFF0A143D)),
        ),
      ),
    );
  }
}
