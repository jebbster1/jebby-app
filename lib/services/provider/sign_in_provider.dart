import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../view_models/auth_view_model.dart';

class SignInProvider extends ChangeNotifier {
  static const _appleEmailPrefsPrefix = 'apple_sign_in_email_';
  static const _appleNamePrefsPrefix = 'apple_sign_in_name_';

  String? _emailFromAppleIdentityToken(String? identityToken) {
    if (identityToken == null || identityToken.isEmpty) return null;
    try {
      final parts = identityToken.split('.');
      if (parts.length < 2) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final email = map['email']?.toString().trim();
      if (email != null && email.contains('@')) return email;
    } catch (_) {}
    return null;
  }

  String _buildAppleDisplayName(String? givenName, String? familyName) {
    final parts = <String>[];
    if (givenName != null && givenName.trim().isNotEmpty) {
      parts.add(givenName.trim());
    }
    if (familyName != null && familyName.trim().isNotEmpty) {
      parts.add(familyName.trim());
    }
    return parts.join(' ');
  }

  String? _emailFromFirebaseUser(User? user) {
    if (user == null) return null;

    final primaryEmail = user.email?.trim();
    if (primaryEmail != null &&
        primaryEmail.isNotEmpty &&
        primaryEmail.contains('@')) {
      return primaryEmail;
    }

    for (final profile in user.providerData) {
      if (profile.providerId == 'apple.com') {
        final providerEmail = profile.email?.trim();
        if (providerEmail != null &&
            providerEmail.isNotEmpty &&
            providerEmail.contains('@')) {
          return providerEmail;
        }
      }
    }

    return null;
  }

  Future<String?> _readCachedAppleEmail(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_appleEmailPrefsPrefix$uid');
  }

  Future<String?> _readCachedAppleName(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_appleNamePrefsPrefix$uid');
  }

  Future<void> _cacheAppleProfile({
    required String uid,
    required String email,
    required String fullName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (email.contains('@')) {
      await prefs.setString('$_appleEmailPrefsPrefix$uid', email);
    }
    if (fullName.trim().isNotEmpty) {
      await prefs.setString('$_appleNamePrefsPrefix$uid', fullName.trim());
    }
  }

  Future<({String email, String fullName})?> _resolveAppleProfile({
    required AuthorizationCredentialAppleID appleCredential,
    required User? user,
  }) async {
    final uid = user?.uid ?? '';
    var email = appleCredential.email?.trim();
    email ??= _emailFromAppleIdentityToken(appleCredential.identityToken);
    email ??= _emailFromFirebaseUser(user);
    if (uid.isNotEmpty) {
      email ??= await _readCachedAppleEmail(uid);
    }

    var fullName = _buildAppleDisplayName(
      appleCredential.givenName,
      appleCredential.familyName,
    );
    if (fullName.isEmpty) {
      fullName = user?.displayName?.trim() ?? '';
    }
    if (fullName.isEmpty && uid.isNotEmpty) {
      fullName = (await _readCachedAppleName(uid))?.trim() ?? '';
    }
    if (fullName.isEmpty) {
      fullName = 'Apple User';
    }

    if (email == null || email.isEmpty || !email.contains('@')) {
      return null;
    }

    if (uid.isNotEmpty) {
      await _cacheAppleProfile(uid: uid, email: email, fullName: fullName);
    }

    return (email: email, fullName: fullName);
  }

  // instance of firebaseauth, facebook and google
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FacebookAuth facebookAuth = FacebookAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  bool _isSignedIn = false;
  bool get isSignedIn => _isSignedIn;

  //hasError, errorCode, provider,uid, email, name, imageUrl
  bool _hasError = false;
  bool get hasError => _hasError;

  String? _errorCode;
  String? get errorCode => _errorCode;

  String? _provider;
  String? get provider => _provider;

  String? _uid;
  String? get uid => _uid;

  String? _role;
  String? get role => _role;

  String? _name;
  String? get name => _name;

  String? _email;
  String? get email => _email;

  String? _phoneNumber;
  String? get phoneNumber => _phoneNumber;

  String? _imageUrl;
  String? get imageUrl => _imageUrl;

  SignInProvider() {
    checkSignInUser();
  }

  Future checkSignInUser() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    _isSignedIn = s.getBool("signed_in") ?? false;
    notifyListeners();
  }

  Future setSignIn() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    s.setBool("signed_in", true);
    _isSignedIn = true;
    notifyListeners();
  }

  // sign in with google
  Future signInWithGoogle(value, BuildContext context) async {
    final authViewMode = Provider.of<AuthViewModel>(context, listen: false);
    _hasError = false;
    _errorCode = null;

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        // executing our authentication
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        // signing to firebase user instance
        final userCredential =
            await firebaseAuth.signInWithCredential(credential);
        final userDetails = userCredential.user;
        if (userDetails == null) {
          _errorCode = 'Google sign-in failed. Please try again.';
          _hasError = true;
          notifyListeners();
          return;
        }

        // now save all values
        _name = userDetails.displayName;
        _email = userDetails.email;
        _imageUrl = userDetails.photoURL;
        _provider = "GOOGLE";
        _uid = userDetails.uid;
        _role = value.toString();

        notifyListeners();

        //save in registerApi
        Map data = {
          "name": userDetails.displayName,
          "email": userDetails.email,
          "password": "",
          "source": "GOOGLE",
          "role": value.toString(),
        };
        authViewMode.signUpApiWithSocials(data, context);
      } else {
        _errorCode = "Google sign-in was cancelled";
        _hasError = true;
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "account-exists-with-different-credential":
          _errorCode =
              "You already have an account with us. Use correct provider";
          _hasError = true;
          notifyListeners();
          break;

        case "null":
          _errorCode = "Some unexpected error while trying to sign in";
          _hasError = true;
          notifyListeners();
          break;
        default:
          _errorCode = e.message ?? e.toString();
          _hasError = true;
          notifyListeners();
      }
    } on PlatformException catch (e) {
      _errorCode = e.message ?? e.code;
      _hasError = true;
      notifyListeners();
    } catch (e) {
      _errorCode = e.toString();
      _hasError = true;
      notifyListeners();
    }
  }

  Future signInWithFacebook(value, BuildContext context) async {
    final authViewMode = Provider.of<AuthViewModel>(context, listen: false);
    _hasError = false;
    _errorCode = null;

    try {
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (loginResult.status == LoginStatus.success) {
      final userData = await FacebookAuth.instance.getUserData(
        fields: "name,email,picture.width(200)",
      );

      if (userData.isNotEmpty) {
        final String email = (userData['email'] ?? '').toString();
        if (email.isEmpty) {
          _errorCode = "Facebook account email is not available";
          _hasError = true;
          notifyListeners();
          return;
        }

        Map data = {
          "name": userData['name'],
          "email": email,
          "password": "",
          "source": "FACEBOOK",
          "role": value.toString(),
        };
        authViewMode.signUpApiWithSocials(data, context);
        notifyListeners();
      } else {
        print('Login failed or cancelled');
      }
      } else if (loginResult.status == LoginStatus.cancelled) {
        _errorCode = "Facebook sign-in was cancelled";
        _hasError = true;
        notifyListeners();
      } else {
        _errorCode = loginResult.message ?? "Facebook sign-in failed";
        _hasError = true;
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "account-exists-with-different-credential":
          _errorCode =
              "You already have an account with us. Use correct provider";
          _hasError = true;
          notifyListeners();
          break;

        case "null":
          _errorCode = "Some unexpected error while trying to sign in";
          _hasError = true;
          notifyListeners();
          break;
        default:
          _errorCode = e.toString();
          _hasError = true;
          notifyListeners();
      }
    } on PlatformException catch (e) {
      _errorCode = e.message ?? e.code;
      _hasError = true;
      notifyListeners();
    } catch (e) {
      _errorCode = e.toString();
      _hasError = true;
      notifyListeners();
    }
  }

  // sign in with apple

  Future signInWithApple(value, BuildContext context) async {
    final authViewMode = Provider.of<AuthViewModel>(context, listen: false);
    _hasError = false;
    _errorCode = null;

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      print('Apple Login Family Name: ${appleCredential.familyName}');
      print('Apple Login Given Name: ${appleCredential.givenName}');
      print('Apple Login Email: ${appleCredential.email}');

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      print('Apple Login OAuth Credentials Full Name: ${oauthCredential.appleFullPersonName}');
  
      final userData = await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );
      final user = userData.user;
      print('firebase user: ${userData.user}');
      final profile = await _resolveAppleProfile(
        appleCredential: appleCredential,
        user: user,
      );

      if (profile == null) {
        _errorCode =
            "Apple account email is not available. Remove Jebby from Apple ID settings (Settings → Apple ID → Sign in with Apple), then sign in again.";
        _hasError = true;
        notifyListeners();
        return;
      }

      if (user != null &&
          (user.displayName == null || user.displayName!.trim().isEmpty)) {
        // ignore: deprecated_member_use
        await user.updateProfile(displayName: profile.fullName);
        await user.reload();
      }

      if (userData.user != null) {
        Map data = {
          "name": profile.fullName,
          "email": profile.email,
          "password": "",
          "source": "APPLE",
          "role": value.toString(),
        };
        authViewMode.signUpApiWithSocials(data, context);
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "account-exists-with-different-credential":
          _errorCode =
              "You already have an account with us. Use correct provider";
          _hasError = true;
          notifyListeners();
          break;

        case "null":
          _errorCode = "Some unexpected error while trying to sign in";
          _hasError = true;
          notifyListeners();
          break;
        default:
          _errorCode = e.toString();
          _hasError = true;
          notifyListeners();
      }
    }
  }

  // ENTRY FOR CLOUDFIRESTORE
  Future getUserDataFromFirestore(uid) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get()
        .then(
          (DocumentSnapshot snapshot) => {
            _uid = snapshot['uid'],
            _name = snapshot['name'],
            _email = snapshot['email'],
            _phoneNumber = snapshot['phoneNumber'],
            _imageUrl = snapshot['image_url'],
            _provider = snapshot['provider'],
          },
        );
  }

  Future saveDataToFirestore() async {
    final DocumentReference r = FirebaseFirestore.instance
        .collection("users")
        .doc(uid);
    await r.set({
      "name": _name,
      "email": _email,
      "phone_number": _phoneNumber,
      "uid": _uid,
      "image_url": _imageUrl,
      "provider": _provider,
    });
    debugPrint("thw value is set");
    notifyListeners();
  }

  Future saveDataToSharedPreferences() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    await s.setString('name', _name ?? '');
    await s.setString('email', _email ?? '');
    await s.setString('uid', _uid ?? '');
    await s.setString('phoneNumber', _phoneNumber ?? '');
    await s.setString('role', _role ?? '');
    await s.setString('image_url', _imageUrl ?? '');
    await s.setString('provider', _provider ?? '');
    notifyListeners();
  }

  Future getDataFromSharedPreferences() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    _name = s.getString('name');
    _email = s.getString('email');
    _phoneNumber = s.getString('phoneNumber');
    _imageUrl = s.getString('image_url');

    _provider = s.getString('provider');
    notifyListeners();
  }

  // checkUser exists or not in cloudfirestore
  Future<bool> checkUserExists() async {
    DocumentSnapshot snap =
        await FirebaseFirestore.instance.collection('users').doc(_uid).get();
    if (snap.exists) {
      return true;
    } else {
      return false;
    }
  }

  // signout
  Future userSignOut() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove("fullname");
    await sharedPreferences.remove("email");
    await sharedPreferences.remove("phoneNumber");
    await sharedPreferences.remove("profileImage");
    await sharedPreferences.remove("isGuest");
    await sharedPreferences.remove("address");
    await sharedPreferences.remove("latitude");
    await sharedPreferences.remove("longitude");
    await sharedPreferences.remove("token");

    try {
      await firebaseAuth.signOut();
    } catch (_) {}
    try {
      await googleSignIn.signOut();
    } catch (_) {}
    try {
      await facebookAuth.logOut();
    } catch (_) {}

    _isSignedIn = false;
    notifyListeners();
    await clearStoredData();
  }

  Future clearStoredData() async {
    final SharedPreferences s = await SharedPreferences.getInstance();
    s.clear();
  }
}

math.Random random = math.Random();

int generateUniqueNumber() {
  // Generate a random number between 0 and 999999
  int randomNumber = random.nextInt(1000000);

  // Get the current timestamp in milliseconds
  int timestamp = DateTime.now().millisecondsSinceEpoch;

  // Combine the random number and timestamp to create a unique number
  int uniqueNumber = int.parse('$randomNumber$timestamp');

  return uniqueNumber;
}
