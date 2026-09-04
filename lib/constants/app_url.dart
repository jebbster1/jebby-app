import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppUrl {
  AppUrl._();

  static String get baseUrlM => dotenv.env['baseUrlM'] ?? '';

  static String get registerApiEndPointM => '$baseUrlM/register';
  static String get loginApiEndPointM => '$baseUrlM/login';
  static String get OTPApiEndPoint => '$baseUrlM/otp';
  static String get resendRegistrationOtpEndPoint =>
      '$baseUrlM/resendRegistrationOtp';
  static String get forgetPasswordEmail => '$baseUrlM/forgetPasswordEmail';
  static String get ChangePasswordUrl => '$baseUrlM/changePasswordForget';
  static String get ForgetPasswordOtpEndPoint =>
      '$baseUrlM/forgetPasswordEmailOtp';
  static String get accountDeletionRequest => '$baseUrlM/accountDeletion';
  static String get feedback => '$baseUrlM/feedback';

  static String get categoryGetUrl => '$baseUrlM/categoryGet';
  static String get subcategoryGetUrl => '$baseUrlM/subCategoryGetByCategoryId/';
  static String get featuredGetUrl => '$baseUrlM/getFeaturedProducts';
  static String get vendorProduct => '$baseUrlM/getAllProductByVendorId/';
  static String get allVendorProductById => '$baseUrlM/getAllProductByVendorId/';
  static String get getProductsByID => '$baseUrlM/getProductById/';
  static String get deleteProduct => '$baseUrlM/deleteProduct';
  static String get productDeleteImage => '$baseUrlM/productDeleteImage';
  static String get productUpdateImage => '$baseUrlM/productUpdateImage';
  static String get categoryID => '$baseUrlM/categoryGetById/';
  static String get subCategoryID => '$baseUrlM/subCategoryGetById/';
  static String cmsPage(String slug) => '$baseUrlM/cms/$slug';
  static String get userCredential => '$baseUrlM/UserProfileGetById/';
  static String get allProducts => '$baseUrlM/getProducts';
  static String get getFromFavorite => '$baseUrlM/addToFavoriteGet/';
  static String get addToFavourite => '$baseUrlM/addToFavorite';
  static String get getAllNotificationForApp =>
      '$baseUrlM/getAllNotificationsForApp/';
  static String get getReviewsByProductId => '$baseUrlM/getReviewsByProductId/';
  static String get getAllReviewsByVendorId => '$baseUrlM/getReviewsByVendorId/';
  static String get getVendorProductsByReviews =>
      '$baseUrlM/getProductsByReviews/';
  static String get deleteNotification => '$baseUrlM/deleteNotification';
  static String get postSeenNotification => '$baseUrlM/setSeenOne';
  static String get postSeenoneNotification => '$baseUrlM/seenOneNotification';
  static String get getAllVendorOrders => '$baseUrlM/getAllOrdersByVendorId/';
  static String get getAllUserOrders => '$baseUrlM/getAllOrdersByUserId/';
  static String get getUserStripeTransactions =>
      '$baseUrlM/getUserStripeTransactions/';
  static String get updateUserRoleApiEndPoint => '$baseUrlM/UpdateUserRole';
  static String get updateFCMToken => '$baseUrlM/updateFCMToken';
  static String get onboardingStateGet => '$baseUrlM/onboarding-state/';
  static String get onboardingStateUpdate => '$baseUrlM/onboarding-state';
  static String get stripeProviderUploadDocument =>
      '$baseUrlM/stripe/provider/upload-document';
  static String get stripeProviderSubmit => '$baseUrlM/stripe/provider/submit';
  static String get stripeProviderSubmitRequirements =>
      '$baseUrlM/stripe/provider/submit-requirements';
  static String get eventsUrl => '$baseUrlM/events';
  static String get reservationsActionRequired =>
      '$baseUrlM/reservations/action-required';
  static String get getValuesUrl => '$baseUrlM/GetValues';
}
