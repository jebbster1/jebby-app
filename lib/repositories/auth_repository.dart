import 'package:jebby/services/network/base_api_services.dart';
import 'package:jebby/services/network/network_api_service.dart';
import 'package:jebby/constants/app_url.dart';
import 'package:jebby/utils/device_platform.dart';

class AuthRepository {
  BaseApiServices _apiServices = NetworkApiService();

  Map<String, dynamic> _withPlatform(dynamic data) {
    final map = Map<String, dynamic>.from(data as Map);
    map['platform'] = clientPlatform();
    return map;
  }

  Future<dynamic> loginApi(dynamic data) async {
    try {
      dynamic response = await _apiServices.getPostApiResponse(
        AppUrl.loginApiEndPointM,
        _withPlatform(data),
      );
      return response;
    } catch (e) {
      throw e;
    }
  }

  Future<dynamic> signUpApi(dynamic data) async {
    try {
      dynamic response = await _apiServices.getPostApiResponse(
        AppUrl.registerApiEndPointM,
        _withPlatform(data),
      );
      return response;
    } catch (e) {
      throw e;
    }
  }

  Future<dynamic> otpRegisterApi(dynamic data) async {
    try {
      dynamic response = await _apiServices.getPostApiResponse(
        AppUrl.OTPApiEndPoint,
        _withPlatform(data),
      );
      return response;
    } catch (e) {
      throw e;
    }
  }

  Future<dynamic> resendRegistrationOtpApi(dynamic data) async {
    try {
      dynamic response = await _apiServices.getPostApiResponse(
        AppUrl.resendRegistrationOtpEndPoint,
        _withPlatform(data),
      );
      return response;
    } catch (e) {
      throw e;
    }
  }

  Future<dynamic> signUpApiWithSocial(dynamic data) async {
    try {
      dynamic response = await _apiServices.getPostApiResponse(
        AppUrl.registerApiEndPointM,
        _withPlatform(data),
      );
      return response;
    } catch (e) {
      throw e;
    }
  }

  Future<dynamic> forgetPasswordApi(dynamic data) async {
    try {
      dynamic response = await _apiServices.getPostApiResponse(
        AppUrl.forgetPasswordEmail,
        data,
      );
      return response;
    } catch (e) {
      throw e;
    }
  }

  Future<dynamic> ForgetPasswordotpApi(dynamic data) async {
    try {
      dynamic response = await _apiServices.getPostApiResponse(
        AppUrl.ForgetPasswordOtpEndPoint,
        data,
      );
      return response;
    } catch (e) {
      throw e;
    }
  }

  //change password
  Future<dynamic> changePasswordApi(dynamic data) async {
    try {
      dynamic response = await _apiServices.getPostApiResponse(
        AppUrl.ChangePasswordUrl,
        data,
      );
      return response;
    } catch (e) {
      throw e;
    }
  }

  Future<dynamic> editProfileApi(dynamic data) async {
    try {
      dynamic response = await _apiServices.getPostApiResponse(
        AppUrl.ChangePasswordUrl,
        data,
      );
      return response;
    } catch (e) {
      throw e;
    }
  }

  Future<dynamic> submitAccountDeletionRequest(dynamic data) async {
    try {
      dynamic response = await _apiServices.getPostApiResponse(
        AppUrl.accountDeletionRequest,
        data,
      );
      return response;
    } catch (e) {
      throw e;
    }
  }

  Future<dynamic> submitFeedbackApi(dynamic data) async {
    try {
      dynamic response = await _apiServices.getPostApiResponse(
        AppUrl.feedback,
        data,
      );
      return response;
    } catch (e) {
      throw e;
    }
  }

  Future<dynamic> updateRoleApi(dynamic data) async {
    try {
      dynamic response = await _apiServices.getPostApiResponse(
        AppUrl.updateUserRoleApiEndPoint,
        data,
      );
      return response;
    } catch (e) {
      throw e;
    }
  }
}
