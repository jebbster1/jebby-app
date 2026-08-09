import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:jebby/Views/screens/vendors/MyProducts.dart';
import 'package:jebby/model/categoryList_model.dart';
import 'package:jebby/model/getCategoryByIdModel.dart';
import 'package:jebby/model/getSubCategoryByIdModel.dart';
import 'package:jebby/model/postNotificationSeenOneModal.dart';
import 'package:jebby/model/vendorProductModel.dart';
import '../Views/screens/mainfolder/homemain.dart';
import '../model/PostMessageModel.dart';
import '../model/PostOrderModel.dart';
import '../model/addFavouriteModel.dart';
import '../model/deleteNotificationModel.dart';
import '../model/getAllMessagesModel.dart';
import '../model/getAllOrdersByUserIdModel.dart';
import '../model/getAllOrdersByVendorId.dart';
import '../model/getAllProductsModel.dart';
import '../model/getAllReviewsByVendorId.dart';
import '../model/getChatHistoryModel.dart';
import '../model/getFavouriteProductsModel.dart';
import '../model/getFeaturedProductsModel.dart';
import '../model/cmsPageModel.dart';
import '../model/getNotificationModel.dart';
import '../model/getReviewsByProductId.dart';
import '../model/filteredProductDataModel.dart';
import '../model/getAllProductsByVendorId.dart';
import '../model/getProductsByProductId.dart';
import '../model/getUserCredentialModel.dart';
import '../model/getVendorProductsByReviewsModel.dart';
import '../model/postNotificationSeenModel.dart';
import '../model/postOrderStatusUpdateModel.dart';
import '../model/productDeleteModelImage.dart';
import '../model/productUpdateModel.dart';
import '../model/reOrderModel.dart';
import '../model/stripePaymentModel.dart';
import '../model/stripeTransactionsModel.dart';
import '../model/sub_category_list_model.dart';
import '../res/app_url.dart';
import '../utils/api_headers.dart';
import '../utils/show_snackbar.dart';

class ApiRepository extends ChangeNotifier {
  bool getCategoryListApiStatus = false;
  bool subCategoryListListApiStatus = false;
  bool getVendorProductListListApiStatus = false;
  bool getProductByVendorIdListApiStatus = false;
  bool getProductsListApiStatus = false;
  bool delStatus = false;
  bool notificationLoader = false;
  bool getNotificationModelListApiStatus = false;
  bool getAllOrdersByVenodrIdListApiStatus = false;

  CategoryList? categoryList;
  SubCategoryList? subCategoryList;
  GetVendorProductsModel? VendorProductList;
  GetAllProductsByVendorId? vendorProductsByIdList;
  GetProductsByProductId? getProductsByIdList;
  GetCategoryByIdModel? getCategoryByIdModelList;
  GetSubCategoryByIdModel? getSubCategoryByIdModelList;
  ProductDeleteImageModel? getProductDeleteImageModelList;
  GetFilteredProductDataModel? getFilteredProductDataList;
  final Map<String, CmsPageModel> _cmsPagesBySlug = {};
  GetUserCredentialModel? getUserCredentialModelList;
  GetAllProductsModel? getAllProductsModelList;
  GetAllMessagesModel? getAllMessagesModelList;
  GetChatHistoryModel? getChatsHistoryModelList;
  GetFavouriteProductsModel? getFavouriteProductsModelList;
  GetNotificationModel? getNotificationModelList;
  GetAllReviewsByProductId? getReviewsByProductIdModelList;
  GetAllReviewsByVendorId? getAllReviewsByVendorIdModelList;
  GetVendorProductsByReveiwsModel? getVendorProductsByReviewsModelList;
  GetAllOrderByVendorIdModel? getAllOrdersByVenodrIdList;
  GetAllOrdersByUserIdModel? getAllOrdersByUserIdModelList;
  GetFeaturedModel? getFeaturedProductsModelList;
  StripeTransactionsModel? stripeTransactionsModelList;

  static var shared = ApiRepository();

  var notificationTimer;
  static var Url = dotenv.env['baseUrlM'] ?? 'No url found';

  checkApiStatus(status, apiName) {
    if (apiName == "categoryList") {
      getCategoryListApiStatus = status;
    } else if (apiName == "subcategoryList") {
      getCategoryListApiStatus = status;
    } else if (apiName == "getVendorProductList") {
      getVendorProductListListApiStatus = status;
    } else if (apiName == "getProductsList") {
      getProductsListApiStatus = status;
    } else if (apiName == "getNotifications") {
      getNotificationModelListApiStatus = status;
    } else if (apiName == "getAllOrdersByVenodrId") {
      getAllOrdersByVenodrIdListApiStatus = status;
    }
  }

  getCategory(data) {
    categoryList = data;
    notifyListeners();
  }

  getSubCategory(data) {
    subCategoryList = data;
    notifyListeners();
  }

  getVendorProduct(data) {
    VendorProductList = data;
    notifyListeners();
  }

  getVendorProductsById(data) {
    vendorProductsByIdList = data;
    notifyListeners();
  }

  getProductByProductId(data) {
    getProductsByIdList = data;
    notifyListeners();
  }

  getSubCategoryById(data) {
    getSubCategoryByIdModelList = data;
  }

  getCategoryById(data) {
    getCategoryByIdModelList = data;
  }

  getdeletedProductImage(status) {
    delStatus = status;
    notifyListeners();
  }

  getFilteredProduct(data) {
    getFilteredProductDataList = data;
    notifyListeners();
  }

  CmsPageModel? cmsPageForSlug(String slug) => _cmsPagesBySlug[slug];

  getUserCredential(data) {
    getUserCredentialModelList = data;
  }

  getAllProducts(data) {
    getAllProductsModelList = data;
    notifyListeners();
  }

  getAllMessages(data) {
    getAllMessagesModelList = data;
  }

  getChatHistory(data) {
    getChatsHistoryModelList = data;
    notifyListeners();
  }

  getFavouriteProduct(data) {
    getFavouriteProductsModelList = data;
    notifyListeners();
  }

  getAllUserOrders(data) {
    getAllOrdersByUserIdModelList = data;
    notifyListeners();
  }

  var unseenMessages = "";

  getNotifications(data) {
    getNotificationModelList = data;
    notificationLoader = true;
    unseenMessages =
        ApiRepository.shared.getNotificationModelList!.unseen.toString();

    notifyListeners();
  }

  getReviewsByProductId(data) {
    getReviewsByProductIdModelList = data;
    notifyListeners();
  }

  getAllReviewsByVendorId(data) {
    getAllReviewsByVendorIdModelList = data;
    notifyListeners();
  }

  getVenodrProductsByReviews(data) {
    getVendorProductsByReviewsModelList = data;
    notifyListeners();
  }

  getAllOrdersByVenodrId(data) {
    getAllOrdersByVenodrIdList = data;
    notifyListeners();
  }

  getFeaturedProducts(data) {
    getFeaturedProductsModelList = data;
    notifyListeners();
  }

  Future<CategoryList> getCategoryList(
    onResponse(CategoryList List),
    onError(error),
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.categoryGetUrl),
      headers: await ApiHeaders.json(),
    );

    if (response.statusCode == 200) {
      try {
        var data = CategoryList.fromJson(jsonDecode(response.body));

        getCategory(data);
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

    return CategoryList();
  }

  Future<SubCategoryList> getSubCategoryList(
    onResponse(SubCategoryList List),
    onError(error),
    id,
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.subcategoryGetUrl + id),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        var data = SubCategoryList.fromJson(jsonDecode(response.body));

        getSubCategory(data);
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

    return SubCategoryList();
  }

  Future<GetVendorProductsModel> getVendorProductList(
    onResponse(GetVendorProductsModel list),
    onError(error),
    id,
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.vendorProduct + id),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        var data = GetVendorProductsModel.fromJson(jsonDecode(response.body));

        getVendorProduct(data);
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

    return GetVendorProductsModel();
  }

  Future<GetAllProductsByVendorId> getAllVendorProductsByID(
    onResponse(GetAllProductsByVendorId list),
    onError(error),
    id,
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.allVendorProductById + id),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        var data = GetAllProductsByVendorId.fromJson(jsonDecode(response.body));

        getVendorProductsById(data);
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

    return GetAllProductsByVendorId();
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

        getProductByProductId(data);
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

  /// Returns `null` on success, or an error message string.
  Future<String?> deleteProductsById(id) async {
    final request = json.encode(<String, dynamic>{"id": id});
    final response = await http.post(
      Uri.parse(AppUrl.deleteProduct),
      body: request,
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      return null;
    }

    var message = 'Could not delete this listing. Please try again.';
    try {
      final body = json.decode(response.body);
      if (body is Map && body['message'] != null) {
        message = body['message'].toString();
      }
    } catch (_) {}

    return message;
  }

  Future<ProductDeleteImageModel> deleteProductImage(id, {required String productId}) async {
    final request = json.encode(<String, dynamic>{
      "id": id,
      "product_id": productId,
    });
    final response = await http.post(
      Uri.parse(AppUrl.productDeleteImage),
      body: request,
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        getdeletedProductImage(true);
      } catch (error) {
      }
    } else if (response.statusCode == 400) {
    } else if (response.statusCode == 500) {
    }

    return ProductDeleteImageModel();
  }

  Future<ProductUpdateModel> productUpdate(
    user_id,
    category_id,
    subcategory_id,
    name,
    price,
    specifications,
    description,
    id,
    prodID,
    user_id1,
    is_delivery,
    available_from,
    available_to,
    delivery_charges,
    security_deposit,
    address,
    latitude,
    longitude,

  ) async {
    final request = json.encode(<String, dynamic>{
      "user_id": user_id,
      "category_id": category_id,
      "subcategory_id": subcategory_id,
      "name": name,
      "price": price,
      "specifications": specifications,
      "description": description,
      "id": id,
      "product_id": prodID,
      "user_id1": user_id1,
      "is_delivery": is_delivery,
      "available_from": available_from,
      "available_to": available_to,
      "delivery_charges": delivery_charges,
      "security_deposit": security_deposit,
      "address": address,
      "latitude": latitude,
      "longitude": longitude,
    });

    final response = await http.post(
      Uri.parse("${Url}/productUpdate"),
      body: request,
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        Get.offAll(() => ProductListScreen(side: false));
      } catch (error) {
      }
    } else if (response.statusCode == 400) {
    } else if (response.statusCode == 500) {
    }
    return ProductUpdateModel();
  }

  Future<GetCategoryByIdModel> CategoryId(
    onResponse(GetCategoryByIdModel List),
    onError(error),
    id,
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.categoryID + id),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        var data = GetCategoryByIdModel.fromJson(jsonDecode(response.body));

        getCategoryById(data);
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

    return GetCategoryByIdModel();
  }

  Future<GetSubCategoryByIdModel> SubCategoryId(
    onResponse(GetSubCategoryByIdModel List),
    onError(error),
    id,
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.subCategoryID + id),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        var data = GetSubCategoryByIdModel.fromJson(jsonDecode(response.body));

        getSubCategoryById(data);
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

    return GetSubCategoryByIdModel();
  }

  Future<GetFilteredProductDataModel> filteredData(
    onResponse(GetFilteredProductDataModel List),
    onError(error),
    url,
  ) async {
    final response = await http.get(
      Uri.parse(url),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        var data = GetFilteredProductDataModel.fromJson(
          jsonDecode(response.body),
        );

        getFilteredProduct(data);
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

    return GetFilteredProductDataModel();
  }

  Future<CmsPageModel> fetchCmsPage(
    String slug,
    onResponse(CmsPageModel model),
    onError(error),
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.cmsPage(slug)),
      headers: await ApiHeaders.json(),
    );

    if (response.statusCode == 200) {
      try {
        var data = CmsPageModel.fromJson(jsonDecode(response.body));
        _cmsPagesBySlug[slug] = data;
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

    return CmsPageModel();
  }

  Future<GetUserCredentialModel> userCredential(
    onResponse(GetUserCredentialModel List),
    onError(error),
    id,
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.userCredential + id.toString()),
      headers: await ApiHeaders.json(),
    );

    if (response.statusCode == 200) {
      try {
        var data = GetUserCredentialModel.fromJson(jsonDecode(response.body));

        getUserCredential(data);
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

    return GetUserCredentialModel();
  }

  Future<GetAllProductsModel> allProducts(
    onResponse(GetAllProductsModel List),
    onError(error),
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.allProducts),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        var data = GetAllProductsModel.fromJson(jsonDecode(response.body));

        getAllProducts(data);
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

    return GetAllProductsModel();
  }

  Future<GetAllMessagesModel> getMessagesApi(
    String sourceID,
    String targetID,
    onResponse(GetAllMessagesModel List),
    onError(error),
  ) async {
    final response = await http.get(
      Uri.parse("${Url}/GetMessagesByIds/${sourceID}/${targetID}"),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        var data = GetAllMessagesModel.fromJson(jsonDecode(response.body));

        getAllMessages(data);
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

    return GetAllMessagesModel();
  }

  Future<PostlMessagesModel> postMessage(
    String content,
    String sender_id,
    String recipient_id, {
    String? productId,
  }) async {
    final body = <String, dynamic>{
      "content": content.toString(),
      "sender_id": sender_id.toString(),
      "recipient_id": recipient_id.toString(),
    };
    final parsedProductId = int.tryParse(productId?.trim() ?? '');
    if (parsedProductId != null && parsedProductId > 0) {
      body["product_id"] = parsedProductId;
    }
    final request = json.encode(body);

    final response = await http.post(
      Uri.parse("${Url}/InsertMessage"),
      body: request,
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      try {} catch (error) {}
    } else if (response.statusCode == 400) {
    } else if (response.statusCode == 500) {}
    return PostlMessagesModel();
  }

  Future<GetChatHistoryModel> chatsHistory(
    String sourceID,
    onResponse(GetChatHistoryModel List),
    onError(error),
  ) async {
    final response = await http.get(
      Uri.parse("${Url}/getMessageVendorsProfile/${sourceID}"),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        var data = GetChatHistoryModel.fromJson(jsonDecode(response.body));

        getChatHistory(data);
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

    return GetChatHistoryModel();
  }

  Future<PayWithStripeModel> stripePayment(
    /*cardNumber, expiryMonth, expiryYear, cvv,*/ amount,
    accountId,
    context,
    userid,
    productId,
    rentStart,
    originalReturn,
    name,
    email,
    location,
    lat,
    long,
    shipping_address,
    security_deposit,
    ApplicationFees,

  ) async {

    final request = json.encode(<String, dynamic>{
      "amount": amount,
      "vendorAccountId": accountId,
      "sales_tax": ApplicationFees.toInt(),
      "user_id": userid,
    });

    final response = await http.post(
      Uri.parse("${Url}/payByStripe"),
      body: request,
      headers: await ApiHeaders.json(),
    );
    
    if (response.statusCode == 200) {
      try {
        final responseData = json.decode(response.body);

        // Assuming your backend returns the client secret
        final clientSecret = responseData['client_secret'];

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Jebby LLC',
            customerId: userid, // Optional
            // Optionally, configure Google Pay and Apple Pay here:
          ),
        );

        await Stripe.instance.presentPaymentSheet();

        showAppSnackbar(
          'Processing',
          'Processing payment and placing order...',
        );

        ApiRepository.shared.postOrder(
          context,
          userid,
          productId,
          rentStart,
          originalReturn,
          name,
          email,
          location,
          lat,
          long,
          shipping_address,
          security_deposit,
          responseData['payment_intent_id'],
        );


      } catch (error) {
      }
    } else if (response.statusCode == 400) {
      // Parse error message from backend
      try {
        final errorData = json.decode(response.body);
        String errorMessage = "Payment validation failed";
        
        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        }
        
        showAppErrorSnackbar(errorMessage);
      } catch (e) {
        showAppErrorSnackbar("Payment validation failed");
      }
    } else if (response.statusCode == 500) {
      // Parse error message from backend
      try {
        final errorData = json.decode(response.body);
        String errorMessage = "Server error occurred";
        
        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        }
        
        showAppErrorSnackbar(errorMessage);
      } catch (e) {
        showAppErrorSnackbar("Server error occurred");
      }
    }
    return PayWithStripeModel();
  }

  Future<PostOrderModel> postOrder(
    context,
    userid,
    productId,
    rentStart,
    originalReturn,
    name,
    email,
    location,
    lat,
    long,
    shipping_address,
    security_deposit,
    deposit_id,
  ) async {
    final request = json.encode(<String, dynamic>{
      "user_id": userid,
      "product_id": productId,
      "rent_start": rentStart,
      "original_return": originalReturn,
      "name": name,
      "email": email,
      "location": location,
      "latitude": lat,
      "longitude": long,
      "shipping_address": shipping_address,
      "security_deposit": security_deposit,
      "deposit_payment_id": deposit_id,
    });

    final response = await http.post(
      Uri.parse("${Url}/rentProductInsert"),
      body: request,
      headers: await ApiHeaders.json(),
    );

    if (response.statusCode == 200) {
      showAppSuccessSnackbar(
        'Payment successful! Order placed successfully. You and the item owner have been notified.',
      );
      Get.off(() => MainScreen());




    } else if (response.statusCode == 400) {
    } else if (response.statusCode == 500) {
      showAppErrorSnackbar('Error in saving order');
    }
    return PostOrderModel();
  }

  Future<GetFavouriteProductsModel> getFavourites(
    String id,
    onResponse(GetFavouriteProductsModel List),
    onError(error),
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.getFromFavorite + id),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        var data = GetFavouriteProductsModel.fromJson(
          jsonDecode(response.body),
        );

        getFavouriteProduct(data);
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

    return GetFavouriteProductsModel();
  }

  Future<AddFavouriteModel> addFavorite(
    userId,
    prodID,
    fav,
  ) async {
    final request = json.encode(<String, dynamic>{
      "user_id": userId,
      "product_id": prodID,
      "fav": fav,
    });

    final response = await http.post(
      Uri.parse(AppUrl.addToFavourite),
      headers: await ApiHeaders.json(),
      body: request,
    );

    if (response.statusCode == 200) {
      try {
      } catch (error) {
      }
    } else if (response.statusCode == 400) {
    } else if (response.statusCode == 500) {
    }
    return AddFavouriteModel();
  }

  Future<GetNotificationModel> notifications(
    id,
    onResponse(GetNotificationModel List),
    onError(error),
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.getAllNotificationForApp + id.toString()),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        ApiRepository.shared.checkApiStatus(true, "getNotifications");
        var data = GetNotificationModel.fromJson(jsonDecode(response.body));

        getNotifications(data);

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

    return GetNotificationModel();
  }

  Future<GetAllReviewsByProductId> reviewsByProductId(
    String id,
    onResponse(GetAllReviewsByProductId List),
    onError(error),
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.getReviewsByProductId + id),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        var data = GetAllReviewsByProductId.fromJson(jsonDecode(response.body));

        getReviewsByProductId(data);
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

    return GetAllReviewsByProductId();
  }

  Future<GetAllReviewsByVendorId> reviewsByVendorId(
    String id,
    onResponse(GetAllReviewsByVendorId List),
    onError(error),
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.getAllReviewsByVendorId + id),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        var data = GetAllReviewsByVendorId.fromJson(jsonDecode(response.body));

        getAllReviewsByVendorId(data);
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

    return GetAllReviewsByVendorId();
  }

  Future<GetVendorProductsByReveiwsModel> reviewsByVenodorProduct(
    String id,
    onResponse(GetVendorProductsByReveiwsModel List),
    onError(error),
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.getVendorProductsByReviews + id),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        var data = GetVendorProductsByReveiwsModel.fromJson(
          jsonDecode(response.body),
        );

        getVenodrProductsByReviews(data);
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
    return GetVendorProductsByReveiwsModel();
  }

  Future<DeleteNotificationModel> deleteNotification(id) async {
    final request = json.encode(<String, dynamic>{"id": id});

    final response = await http.post(
      Uri.parse(AppUrl.deleteNotification),
      body: request,
      headers: await ApiHeaders.json(),
    );

    if (response.statusCode == 201) {
      try {
        unseenMessages = "";

        ApiRepository.shared.notifications(id, (List) {}, (error) {});
      } catch (error) {
      }
    } else if (response.statusCode == 400) {
    } else if (response.statusCode == 500) {
    }
    return DeleteNotificationModel();
  }

  Future<GetNotificationSeenModel> seenNotification(id) async {
    final request = json.encode(<String, dynamic>{"user_id": id});

    final response = await http.post(
      Uri.parse(AppUrl.postSeenNotification),
      body: request,
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 201) {
      try {
        ApiRepository.shared.notifications(id, (List) {}, (error) {});
      } catch (error) {
      }
    } else if (response.statusCode == 400) {
    } else if (response.statusCode == 500) {
    }
    return GetNotificationSeenModel();
  }

  Future<GetNotificationSeenOneModel> seenoneNotification(id) async {
    final request = json.encode(<String, dynamic>{"id": id});

    final response = await http.post(
      Uri.parse(AppUrl.postSeenoneNotification),
      body: request,
      headers: await ApiHeaders.json(),
    );

    if (response.statusCode == 201) {
      try {
        ApiRepository.shared.notifications(id, (List) {}, (error) {});
      } catch (error) {
      }
    } else if (response.statusCode == 400) {
    } else if (response.statusCode == 500) {
    }
    return GetNotificationSeenOneModel();
  }

  Future<GetAllOrderByVendorIdModel> getVenodorOrders(
    String id,
    onResponse(GetAllOrderByVendorIdModel List),
    onError(error),
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.getAllVendorOrders + id),
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        var data = GetAllOrderByVendorIdModel.fromJson(
          jsonDecode(response.body),
        );

        getAllOrdersByVenodrId(data);
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

    return GetAllOrderByVendorIdModel();
  }

  Future<PostOrderStatusUpdateModel> orderStatusUpdate(
    id,
    status,
    desc,
    vendorID,
    route,
  ) async {
    final request = json.encode(<String, dynamic>{
      "id": id,
      "status": status,
      "description": desc,
    });

    final response = await http.post(
      Uri.parse(AppUrl.orderStatusById),
      body: request,
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        ApiRepository.shared.getVenodorOrders(
          vendorID.toString(),
          (List) {},
          (error) {},
        );
      } catch (error) {
      }
    } else if (response.statusCode == 400) {
    } else if (response.statusCode == 500) {
    }
    return PostOrderStatusUpdateModel();
  }

  Future<GetAllOrdersByUserIdModel> getAllOrdersByUserId(
    String id,
    onResponse(GetAllOrdersByUserIdModel List),
    onError(error),
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.getAllUserOrders + id),
      headers: await ApiHeaders.json(),
    );

    if (response.statusCode == 200) {
      try {
        var data = GetAllOrdersByUserIdModel.fromJson(
          jsonDecode(response.body),
        );

        getAllUserOrders(data);
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

    return GetAllOrdersByUserIdModel();
  }

  Future<ReOrderModel> reOrder(id, location) async {
    final request = json.encode(<String, dynamic>{
      "id": id,
      "location": location,
    });

    final response = await http.post(
      Uri.parse(AppUrl.reOrder),
      body: request,
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        showAppSuccessSnackbar('Order placed successfully.');

        Get.offAll(() => MainScreen());
      } catch (error) {
      }
    } else if (response.statusCode == 400) {
    } else if (response.statusCode == 500) {
    }
    return ReOrderModel();
  }

  Future<PayWithStripeModel> reOrderStripePayment(
    amount,
    accountId,
    context,
    orderId,
    location,
    applicationFee,
  ) async {

    final request = json.encode(<String, dynamic>{
      "amount": amount,
      "vendorAccountId": accountId,
      "sales_tax": applicationFee,
    });

    final response = await http.post(
      Uri.parse("${Url}/payByStripe"),
      body: request,
      headers: await ApiHeaders.json(),
    );
    if (response.statusCode == 200) {
      try {
        final responseData = json.decode(response.body);
        // Assuming your backend returns the client secret
        final clientSecret = responseData['client_secret'];

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Jebby LLC',
            // Optionally, configure Google Pay and Apple Pay here:
          ),
        );

        await Stripe.instance.presentPaymentSheet();

        showAppSnackbar(
          'Processing',
          'Amount debited, placing order please wait',
        );

        ApiRepository.shared.reOrder(orderId, location);
      } catch (error) {
      }
    } else if (response.statusCode == 400) {
      // Parse error message from backend
      try {
        final errorData = json.decode(response.body);
        String errorMessage = "Payment validation failed";
        
        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        }
        
        showAppErrorSnackbar(errorMessage);
      } catch (e) {
        showAppErrorSnackbar("Payment validation failed");
      }
    } else if (response.statusCode == 500) {
      // Parse error message from backend
      try {
        final errorData = json.decode(response.body);
        String errorMessage = "Server error occurred";
        
        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        }
        
        showAppErrorSnackbar(errorMessage);
      } catch (e) {
        showAppErrorSnackbar("Server error occurred");
      }
    }
    return PayWithStripeModel();
  }

  Future<GetFeaturedModel> featuredProducts(
    onResponse(GetFeaturedModel List),
    onError(error),
  ) async {
    print("hello2033");

    final response = await http.get(
      Uri.parse(AppUrl.featuredGetUrl),
      headers: await ApiHeaders.json(),
    );
    print(response.statusCode.toString());

    if (response.statusCode == 200) {
      try {
        var data = GetFeaturedModel.fromJson(jsonDecode(response.body));


        print("hello2041");
        getFeaturedProducts(data);
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

    return GetFeaturedModel();
  }

  getStripeTransactions(data) {
    stripeTransactionsModelList = data;
    notifyListeners();
  }

  // Check Stripe Connect account status
  Future<dynamic> checkStripeAccountStatus(
    String userId,
    onResponse(dynamic data),
    onError(error),
  ) async {
    final response = await http.get(
      Uri.parse("${Url}/stripe/account-status/${userId}"),
      headers: await ApiHeaders.json(),
    );
    
    if (response.statusCode == 200) {
      try {
        var data = jsonDecode(response.body);
        onResponse(data);
        return data;
      } catch (error) {
        onError(error.toString());
      }
    } else if (response.statusCode == 400) {
      onError("Error checking account status");
    } else if (response.statusCode == 500) {
      onError("Internal Server Error");
    }
    
    return {};
  }
  
  // Get user's Stripe transactions
  Future<StripeTransactionsModel> getUserStripeTransactions(
    String userId,
    onResponse(StripeTransactionsModel data),
    onError(error),
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.getUserStripeTransactions + userId),
      headers: await ApiHeaders.json(),
    );
    
    if (response.statusCode == 200) {
      try {
        var data = StripeTransactionsModel.fromJson(jsonDecode(response.body));
        getStripeTransactions(data);
        onResponse(data);
        return data;
      } catch (error) {
        onError(error.toString());
      }
    } else if (response.statusCode == 400) {
      onError("Error fetching transactions");
    } else if (response.statusCode == 404) {
      onError("User not found");
    } else if (response.statusCode == 500) {
      onError("Internal Server Error");
    }
    
    return StripeTransactionsModel();
  }

  Future<dynamic> getOnboardingState(
    String userId,
    onResponse(dynamic data),
    onError(error),
  ) async {
    final response = await http.get(
      Uri.parse(AppUrl.onboardingStateGet + userId),
      headers: await ApiHeaders.json(),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        onResponse(data is Map<String, dynamic> ? data : {});
        return data;
      } catch (error) {
        onError(error.toString());
      }
    } else if (response.statusCode == 404) {
      onResponse({});
    } else if (response.statusCode == 400) {
      onError('Error fetching onboarding state');
    } else if (response.statusCode == 500) {
      onError('Internal Server Error');
    }

    return {};
  }

  Future<dynamic> updateOnboardingState(
    Map<String, dynamic> body,
    onResponse(dynamic data),
    onError(error),
  ) async {
    final response = await http.post(
      Uri.parse(AppUrl.onboardingStateUpdate),
      body: json.encode(body),
      headers: await ApiHeaders.json(),
    );

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        onResponse(data);
        return data;
      } catch (error) {
        onError(error.toString());
      }
    } else if (response.statusCode == 400) {
      onError('Error updating onboarding state');
    } else if (response.statusCode == 500) {
      onError('Internal Server Error');
    }

    return {};
  }

  Future<dio.MultipartFile> _identityImageMultipartFile(
    String path, {
    required String fieldName,
  }) async {
    final bytes = await _normalizeIdentityImageBytes(path);
    final mimeType = lookupMimeType(
          '',
          headerBytes: bytes.length >= 12 ? bytes.sublist(0, 12) : bytes,
        ) ??
        'image/jpeg';

    late String filename;
    late MediaType contentType;

    if (mimeType == 'image/png') {
      filename = '$fieldName.png';
      contentType = MediaType('image', 'png');
    } else if (mimeType == 'image/webp') {
      filename = '$fieldName.webp';
      contentType = MediaType('image', 'webp');
    } else {
      filename = '$fieldName.jpg';
      contentType = MediaType('image', 'jpeg');
    }

    return dio.MultipartFile.fromBytes(
      bytes,
      filename: filename,
      contentType: contentType,
    );
  }

  Future<Uint8List> _normalizeIdentityImageBytes(String path) async {
    final bytes = await File(path).readAsBytes();
    final ext = p.extension(path).toLowerCase();
    final mimeType = lookupMimeType(
          path,
          headerBytes: bytes.length >= 12 ? bytes.sublist(0, 12) : bytes,
        ) ??
        '';

    final isHeic = ext == '.heic' ||
        ext == '.heif' ||
        mimeType.contains('heic') ||
        mimeType.contains('heif');

    if (!isHeic && mimeType.startsWith('image/')) {
      return bytes;
    }

    if (isHeic || !mimeType.startsWith('image/')) {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final pngData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      frame.image.dispose();
      if (pngData == null) {
        throw Exception('Could not process image. Try taking a new photo.');
      }
      return pngData.buffer.asUint8List();
    }

    return bytes;
  }

  static bool isGenericApiErrorMessage(String message) {
    final lower = message.toLowerCase();
    const genericPhrases = [
      'temporarily unavailable',
      'temporary unavailable',
      'invalid onboarding submission',
      'internal server error',
      'something went wrong',
      'unable to submit onboarding',
      'unable to complete onboarding',
      'request failed',
      'upload failed',
    ];
    return genericPhrases.any((phrase) => lower.contains(phrase));
  }

  static String extractApiErrorMessage(
    dynamic data, {
    String fallback = 'Request failed',
  }) {
    final candidates = <String>[];
    _collectApiErrorMessages(data, candidates);

    if (candidates.isEmpty) {
      final asString = data?.toString().trim() ?? '';
      return asString.isEmpty ? fallback : asString;
    }

    final specific = candidates.where((c) => !isGenericApiErrorMessage(c)).toList();
    if (specific.isNotEmpty) {
      specific.sort((a, b) => b.length.compareTo(a.length));
      return specific.first;
    }

    return candidates.first;
  }

  static void _collectApiErrorMessages(dynamic data, List<String> candidates) {
    if (data == null) return;

    if (data is Map) {
      for (final key in [
        'message',
        'error',
        'msg',
        'detail',
        'details',
        'reason',
        'description',
        'stripe_error',
        'stripe_message',
      ]) {
        final value = data[key];
        if (value is Map) {
          _collectApiErrorMessages(value, candidates);
        } else if (value != null) {
          final text = value.toString().trim();
          if (text.isNotEmpty) candidates.add(text);
        }
      }

      final errors = data['errors'];
      if (errors is List) {
        for (final item in errors) {
          if (item is Map) {
            final nested = item['message'] ?? item['detail'] ?? item['error'];
            if (nested != null) {
              final text = nested.toString().trim();
              if (text.isNotEmpty) candidates.add(text);
            } else {
              _collectApiErrorMessages(item, candidates);
            }
          } else if (item != null) {
            final text = item.toString().trim();
            if (text.isNotEmpty) candidates.add(text);
          }
        }
      }
      return;
    }

    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map || decoded is List) {
          _collectApiErrorMessages(decoded, candidates);
          return;
        }
      } catch (_) {
        candidates.add(data.trim());
      }
    }
  }

  String _extractApiErrorMessage(
    dynamic data, {
    String fallback = 'Request failed',
  }) =>
      extractApiErrorMessage(data, fallback: fallback);

  dynamic _tryDecodeResponseBody(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  Future<dynamic> uploadIdentityDocument({
    required String userId,
    required String documentType,
    required String frontPath,
    String? backPath,
    required onResponse(dynamic data),
    required onError(error),
  }) async {
    try {
      final formMap = <String, dynamic>{
        'user_id': userId,
        'document_type': documentType,
        'file_front': await _identityImageMultipartFile(
          frontPath,
          fieldName: 'id_front',
        ),
      };

      if (backPath != null && backPath.isNotEmpty && File(backPath).existsSync()) {
        formMap['file_back'] = await _identityImageMultipartFile(
          backPath,
          fieldName: 'id_back',
        );
      }

      final formData = dio.FormData.fromMap(formMap);
      final uploadHeaders = await ApiHeaders.json();
      final response = await dio.Dio().post(
        AppUrl.stripeProviderUploadDocument,
        data: formData,
        options: dio.Options(
          contentType: 'multipart/form-data',
          headers: uploadHeaders,
        ),
      );

      final statusCode = response.statusCode ?? 0;
      final data = response.data;

      if (statusCode >= 200 && statusCode < 300 && data is Map) {
        onResponse(data);
        return data;
      }

      onError(_extractApiErrorMessage(data, fallback: 'Upload failed'));
    } on dio.DioException catch (e) {
      final message = _extractApiErrorMessage(
        e.response?.data,
        fallback: e.message ?? 'Upload failed',
      );
      onError(message);
    } catch (e) {
      onError(e.toString());
    }

    return {};
  }

  Future<dynamic> submitProviderOnboarding({
    required Map<String, dynamic> body,
    required onResponse(dynamic data),
    required onError(error),
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppUrl.stripeProviderSubmit),
        body: json.encode(body),
        headers: await ApiHeaders.json(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        onResponse(data is Map ? data : {'status': 'pending', 'raw': data});
        return data;
      }

      final errorBody = _tryDecodeResponseBody(response.body);
      onError(
        _extractApiErrorMessage(
          errorBody,
          fallback: 'Unable to submit onboarding (${response.statusCode})',
        ),
      );
    } catch (e) {
      onError(e.toString());
    }

    return {};
  }

  Future<Map<String, dynamic>> uploadIdentityDocumentFuture({
    required String userId,
    required String documentType,
    required String frontPath,
    String? backPath,
  }) async {
    final completer = Completer<Map<String, dynamic>>();
    await uploadIdentityDocument(
      userId: userId,
      documentType: documentType,
      frontPath: frontPath,
      backPath: backPath,
      onResponse: (data) {
        if (data is Map<String, dynamic>) {
          completer.complete(data);
        } else if (data is Map) {
          completer.complete(Map<String, dynamic>.from(data));
        } else {
          completer.completeError('Invalid upload response');
        }
      },
      onError: (error) => completer.completeError(error.toString()),
    );
    return completer.future;
  }

  Future<Map<String, dynamic>> submitProviderOnboardingFuture({
    required Map<String, dynamic> body,
  }) async {
    final completer = Completer<Map<String, dynamic>>();
    await submitProviderOnboarding(
      body: body,
      onResponse: (data) {
        if (data is Map<String, dynamic>) {
          completer.complete(data);
        } else if (data is Map) {
          completer.complete(Map<String, dynamic>.from(data));
        } else {
          completer.completeError('Invalid submit response');
        }
      },
      onError: (error) => completer.completeError(error.toString()),
    );
    return completer.future;
  }

  Future<dynamic> submitProviderRequirements({
    required Map<String, dynamic> body,
    required onResponse(dynamic data),
    required onError(error),
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppUrl.stripeProviderSubmitRequirements),
        body: json.encode(body),
        headers: await ApiHeaders.json(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        onResponse(data is Map ? data : {'status': 'pending', 'raw': data});
        return data;
      }

      final errorBody = _tryDecodeResponseBody(response.body);
      onError(
        _extractApiErrorMessage(
          errorBody,
          fallback:
              'Unable to submit required information (${response.statusCode})',
        ),
      );
    } catch (e) {
      onError(e.toString());
    }

    return {};
  }

  Future<Map<String, dynamic>> submitProviderRequirementsFuture({
    required Map<String, dynamic> body,
  }) async {
    final completer = Completer<Map<String, dynamic>>();
    await submitProviderRequirements(
      body: body,
      onResponse: (data) {
        if (data is Map<String, dynamic>) {
          completer.complete(data);
        } else if (data is Map) {
          completer.complete(Map<String, dynamic>.from(data));
        } else {
          completer.completeError('Invalid requirements submit response');
        }
      },
      onError: (error) => completer.completeError(error.toString()),
    );
    return completer.future;
  }
}

class notiTimer with ChangeNotifier {
  static final notiTimer _instance = notiTimer._internal();
  factory notiTimer() => _instance;
  notiTimer._internal();

  Timer? timer;

  void cancelTimer() {
    timer?.cancel();
    timer = null;
  }
}
