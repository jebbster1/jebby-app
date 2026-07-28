import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppUrl {
  static var baseUrl = 'https://reqres.in';

  static var moviesBaseUrl =
      'https://dea91516-1da3-444b-ad94-c6d0c4dfab81.mock.pstmn.io/';

  static var loginEndPint = baseUrl + '/api/login';

  static var registerApiEndPoint = baseUrl + '/api/register';

  static var moviesListEndPoint = moviesBaseUrl + 'movies_list';

  static var Url = dotenv.env['baseUrlM'] ?? 'No url found';
  static var baseUrlM = Url;

  /// base url
  static var registerApiEndPointM = baseUrlM + '/register';
  static var loginApiEndPointM = baseUrlM + '/login';

  static var OTPApiEndPoint = baseUrlM + '/otp';
  static var forgetPasswordEmail = baseUrlM + "/forgetPasswordEmail";
  static var ChangePasswordUrl = baseUrlM + "/changePasswordForget";
  static var ForgetPasswordOtpEndPoint = baseUrlM + "/forgetPasswordEmailOtp";

  static var editProfileUrl = baseUrlM + "/UserProfileInsert";
  static var deleteAccount = baseUrlM + "/VendorDelete";

  ///GET Apis
  static var UserProfileGetByIdUrl = baseUrlM + "/UserProfileGetById/:id";
  static var categoryGetUrl = baseUrlM + "/categoryGet";
  static var subcategoryGetUrl = baseUrlM + "/subCategoryGetByCategoryId/";
  static var featuredGetUrl = baseUrlM + "/getFeaturedProducts";
  static var vendorProduct = baseUrlM + "/getAllProductByVendorId/";
  static var lastVendorProduct = baseUrlM + "/LastProductByVendorId/";
  static var productInfoInsert = baseUrlM + "/productInfoInsert";
  static var allVendorProductById = baseUrlM + "/getAllProductByVendorId/";
  static var getProductsByID = baseUrlM + "/getProductById/";
  static var getRelatedProduct = baseUrlM + "/getRelatedProductsByProductId/";
  static var deleteProduct = baseUrlM + "/deleteProduct";
  static var productDeleteImage = baseUrlM + "/productDeleteImage";
  static var productUpdateImage = baseUrlM + "/productUpdateImage";
  static var productUpdate = baseUrlM + "/productUpdate";
  static var categoryID = baseUrlM + "/categoryGetById/";
  static var subCategoryID = baseUrlM + "/subCategoryGetById/";
  static var privacyPolicy = baseUrlM + "/getPrivacyPolicy";
  static var termsAndConditions = baseUrlM + "/getTermsAndConditions";
  static var aboutApp = baseUrlM + "/getAboutApp";
  static var termLength = baseUrlM + "/getTermLength";
  static var userCredential = baseUrlM + "/UserProfileGetById/";
  static var rentalAgreement = baseUrlM + "/getRentalAgreement";
  static var usagePolicy = baseUrlM + "/getUsageAndLimitation";
  static var insurance = baseUrlM + "/getInsurance";
  static var transport = baseUrlM + "/getTransport";
  static var miantenance = baseUrlM + "/getMaintainance";
  static var termination = baseUrlM + "/getTermination";
  static var allProducts = baseUrlM + "/getProducts";
  static var getMessages = baseUrlM + "/GetMessagesByIds";
  static var getChatsHistory = baseUrlM + "/getMessageVendorsProfile/";
  static var stripePayment = baseUrlM + "/payByStripe";
  static var getFromFavorite = baseUrlM + "/addToFavoriteGet/";
  static var addToFavourite = baseUrlM + "/addToFavorite";
  static var getAllNotificationForApp =
      baseUrlM + "/getAllNotificationsForApp/";
  static var getReviewsByProductId = baseUrlM + "/getReviewsByProductId/";
  static var getAllReviewsByVendorId = baseUrlM + "/getReviewsByVendorId/";
  static var getVendorProductsByReviews = baseUrlM + "/getProductsByReviews/";
  static var deleteNotification = baseUrlM + "/deleteNotification";
  static var postSeenNotification = baseUrlM + "/setSeenOne";
  static var postSeenoneNotification = baseUrlM + "/seenOneNotification";
  static var getAllVendorOrders = baseUrlM + "/getAllOrdersByVendorId/";
  static var getAllUserOrders = baseUrlM + "/getAllOrdersByUserId/";
  static var orderStatusById = baseUrlM + "/orderStatusById";
  static var reOrder = baseUrlM + "/reOrder";
  static var negoRequest = baseUrlM + "/RequestNago";
  static var negoRequestUpdate = baseUrlM + "/ChangeNegoStatus";
  static var negoById = baseUrlM + "/getNegoById/";
  static var getUserStripeTransactions = baseUrlM + "/getUserStripeTransactions/";

  static var updateUserRoleApiEndPoint = baseUrlM + '/UpdateUserRole';
  static var updateFCMToken = baseUrlM + '/updateFCMToken';

  static var onboardingStateGet = baseUrlM + '/onboarding-state/';
  static var onboardingStateUpdate = baseUrlM + '/onboarding-state';

  static var stripeProviderUploadDocument =
      baseUrlM + '/stripe/provider/upload-document';
  static var stripeProviderSubmit = baseUrlM + '/stripe/provider/submit';
  static var stripeProviderSubmitRequirements =
      baseUrlM + '/stripe/provider/submit-requirements';
  static var stripeAccountStatus = baseUrlM + '/stripe/account-status/';
  static var eventsUrl = baseUrlM + '/events';
}
