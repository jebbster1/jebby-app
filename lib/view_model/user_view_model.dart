import 'package:flutter/cupertino.dart';
import 'package:jebby/model/user_model.dart';
import 'package:jebby/utils/profile_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserViewModel with ChangeNotifier {
  static bool isSocialAuthSource(String? source) {
    final normalized = source?.trim().toLowerCase() ?? '';
    return normalized.isNotEmpty && normalized != 'simple';
  }

  static String socialAuthPasswordMessage(String? source) {
    switch (source?.trim().toUpperCase()) {
      case 'GOOGLE':
        return 'This account uses Google sign-in. Manage your password through your Google account.';
      case 'FACEBOOK':
        return 'This account uses Facebook sign-in. Manage your password through your Facebook account.';
      case 'APPLE':
        return 'This account uses Apple sign-in. Manage your password through your Apple ID settings.';
      default:
        return 'This account uses social sign-in. Password changes are not available here.';
    }
  }

  String? _role;
  String? get role => _role;

  static String normalizeRole(String? role) {
    if (role == null) return '0';
    final trimmed = role.trim();
    if (trimmed.isEmpty || trimmed == 'null') return '0';
    if (trimmed.toLowerCase() == 'guest') return 'Guest';
    final asInt = int.tryParse(trimmed);
    if (asInt != null) return asInt == 1 ? '1' : '0';
    return trimmed == '1' ? '1' : '0';
  }

  static String? displayEmail(String? email) {
    final value = email?.trim() ?? '';
    if (value.isEmpty || value == 'null') return null;
    return value;
  }

  bool _isGuest = false;

  bool get isGuestUser =>
      _isGuest ||
      (_role?.trim().toLowerCase() == 'guest') ||
      (_name?.trim() == 'Guest');

  bool get isEarnMode => !isGuestUser && normalizeRole(_role) == '1';

  void setRole(String role) {
    final normalized = normalizeRole(role);
    if (_role == normalized) return;
    _role = normalized;
    notifyListeners();
    SharedPreferences.getInstance().then(
      (sp) => sp.setString('role', normalized),
    );
  }

  String? _id;
  String? get id => _id;

  String? _token;
  String? get token => _token;

  String? _name;
  String? get name => _name;

  String? _email;
  String? get email => _email;

  String? _phoneNumber;
  String? get phoneNumber => _phoneNumber;

  String? _profileImage;
  String? get profileImage => _profileImage;
  String? _address;
  String? get address => _address;

  String? _latitude;
  String? get latitude => _latitude;
  String? _longitude;
  String? get longitude => _longitude;

  String? _source;
  String? get source => _source;

  Future<bool> saveUser(UserModel user) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString('token', user.token.toString());
    sp.setString('id', user.id.toString());
    sp.setString('fullname', user.name.toString());
    sp.setString('email', user.email.toString());
    sp.setString('phoneNumber', user.phoneNumber.toString());
    final incomingAddress = user.address?.trim();
    if (incomingAddress != null && incomingAddress.isNotEmpty) {
      sp.setString('address', incomingAddress);
    }
    sp.setString('role', user.role.toString());
    sp.setString('isGuest', user.isGuest.toString());
    final incomingSource = user.source?.trim();
    if (incomingSource != null && incomingSource.isNotEmpty) {
      sp.setString('source', incomingSource);
      _source = incomingSource;
    }

    _token = user.token;
    _id = user.id;
    _name = user.name;
    _email = user.email;
    _phoneNumber = user.phoneNumber;
    _role = normalizeRole(user.role);
    _isGuest = user.isGuest == true || _role == 'Guest';

    notifyListeners();
    return true;
  }

  Future<bool> updateUser(UpdatedModel user) async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    var updatedUser; //= user.data![0];
    if (user.data!.length != 0) {
      updatedUser = user.data![0];

      sp.setString('fullname', updatedUser.name.toString());
      sp.setString('email', updatedUser.email.toString());
      sp.setString('phoneNumber', updatedUser.phoneNumber.toString());
      sp.setString('profileImage', ProfileImage.sanitizePath(updatedUser.profileImage?.toString()));
      final updatedAddress = updatedUser.address?.toString().trim();
      if (updatedAddress != null && updatedAddress.isNotEmpty) {
        sp.setString('address', updatedAddress);
      }
      sp.setString('latitude', updatedUser.latitude.toString());
      sp.setString('longitude', updatedUser.longitude.toString());
    }
    notifyListeners();
    return true;
  }

  Future<UpdatedModel> getUpdatedUser() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();

    _token = sp.getString('token');
    _id = sp.getString('id');
    _name = sp.getString('fullname');
    _email = sp.getString('email');
    _phoneNumber = sp.getString('phoneNumber');
    _role = normalizeRole(sp.getString('role'));
    _address = sp.getString('address');
    _latitude = sp.getString('latitude');
    _longitude = sp.getString('longitude');
    _profileImage = ProfileImage.sanitizePath(sp.getString('profileImage'));
    if (_profileImage != null && _profileImage!.isEmpty) _profileImage = null;
    _source = sp.getString('source');
    final isGuestUserString = sp.getString('isGuest');
    _isGuest =
        (isGuestUserString != null && isGuestUserString == 'true') ||
        _role == 'Guest' ||
        _name?.trim() == 'Guest';

    notifyListeners();

    return UpdatedModel(
      data: [
        Data(
          profileImage: profileImage.toString(),
          name: name.toString(),
          phoneNumber: phoneNumber.toString(),
          email: email.toString(),
          address: address.toString(),
          userId: id.toString(),
          latitude: latitude.toString(),
          longitude: longitude.toString(),
        ),
      ],
    );

  }

  Future<UserModel> getUser() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();

    _token = sp.getString('token');
    _id = sp.getString('id');
    _name = sp.getString('fullname');
    _email = sp.getString('email');
    _phoneNumber = sp.getString('phoneNumber');
    _address = sp.getString('address');
    _role = normalizeRole(sp.getString('role'));
    _source = sp.getString('source');
    if (_address?.trim().isEmpty == true) {
      _address = null;
    }
    String? isGuestUserString = sp.getString('isGuest');
    final isGuest =
        (isGuestUserString != null && isGuestUserString == 'true') ||
        _role == 'Guest' ||
        _name?.trim() == 'Guest';
    _isGuest = isGuest;
    notifyListeners();
    return UserModel(
      token: _token ?? '',
      id: _id ?? '',
      address: _address,
      name: _name,
      email: _email,
      phoneNumber: _phoneNumber,
      role: _role ?? '',
      source: _source,
      isGuest: isGuest,
    );
  }

  static Future<bool> hasActiveSession() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('token')?.trim() ?? '';
    final role = sp.getString('role')?.trim() ?? '';
    if (token.isEmpty || role.isEmpty) return false;
    if (token == 'null' || role == 'null') return false;
    return true;
  }

  Future<bool> remove() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    sp.remove('token');
    sp.remove('id');
    sp.remove('fullname');
    sp.remove('email');
    sp.remove('phoneNumber');
    sp.remove('role');
    sp.remove('address');
    sp.remove('latitude');
    sp.remove('longitude');
    sp.remove('profileImage');
    sp.remove('isGuest');
    sp.remove('source');
    _token = null;
    _id = null;
    _name = null;
    _email = null;
    _phoneNumber = null;
    _role = null;
    _address = null;
    _latitude = null;
    _longitude = null;
    _profileImage = null;
    _source = null;
    _isGuest = false;

    notifyListeners();
    return true;
  }
}
