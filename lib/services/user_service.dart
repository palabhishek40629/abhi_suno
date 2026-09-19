import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String _kNameKey = 'user_custom_profile_name';
  static const String _kBioKey = 'user_custom_profile_bio';
  static const String _kImageKey = 'user_custom_profile_image';
  static const String _kEmailKey = 'user_custom_profile_email';
  static const String _kLoggedInKey = 'user_is_logged_in';
  static const String _kGoogleUserKey = 'user_is_google_account';

  String _userName = 'Abhishek Pal';
  String _userBio = 'Computer Science & Engineering Student';
  String? _profileImagePath;
  String _userEmail = 'abhishekpal40629@gmail.com';
  bool _isLoggedIn = true;
  bool _isGoogleUser = false;
  bool _isLoaded = false;

  String get userName => _userName;
  String get userBio => _userBio;
  String? get profileImagePath => _profileImagePath;
  String get userEmail => _userEmail;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGoogleUser => _isGoogleUser;
  bool get isLoaded => _isLoaded;

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString(_kNameKey) ?? 'Abhishek Pal';
      _userBio = prefs.getString(_kBioKey) ?? 'Computer Science & Engineering Student';
      _profileImagePath = prefs.getString(_kImageKey);
      _userEmail = prefs.getString(_kEmailKey) ?? 'abhishekpal40629@gmail.com';
      _isLoggedIn = prefs.getBool(_kLoggedInKey) ?? true;
      _isGoogleUser = prefs.getBool(_kGoogleUserKey) ?? false;
      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      _isLoaded = true;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? imagePath,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null && name.trim().isNotEmpty) {
      _userName = name.trim();
      await prefs.setString(_kNameKey, _userName);
    }
    if (bio != null) {
      _userBio = bio.trim();
      await prefs.setString(_kBioKey, _userBio);
    }
    if (imagePath != null) {
      _profileImagePath = imagePath;
      await prefs.setString(_kImageKey, imagePath);
    }
    if (email != null && email.trim().isNotEmpty) {
      _userEmail = email.trim();
      await prefs.setString(_kEmailKey, _userEmail);
    }
    notifyListeners();
  }

  Future<void> login({
    required String name,
    required String email,
    String? bio,
    String? imagePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _userName = name.trim();
    _userEmail = email.trim();
    if (bio != null) _userBio = bio.trim();
    if (imagePath != null) _profileImagePath = imagePath;
    _isLoggedIn = true;

    await prefs.setString(_kNameKey, _userName);
    await prefs.setString(_kEmailKey, _userEmail);
    await prefs.setString(_kBioKey, _userBio);
    if (imagePath != null) await prefs.setString(_kImageKey, imagePath);
    await prefs.setBool(_kLoggedInKey, true);

    notifyListeners();
  }

  Future<void> loginWithGoogle({
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    _userName = name.trim();
    _userEmail = email.trim();
    _userBio = 'Music Lover • Google Verified';
    if (photoUrl != null && photoUrl.isNotEmpty) {
      _profileImagePath = photoUrl;
    }
    _isLoggedIn = true;
    _isGoogleUser = true;

    await prefs.setString(_kNameKey, _userName);
    await prefs.setString(_kEmailKey, _userEmail);
    await prefs.setString(_kBioKey, _userBio);
    if (photoUrl != null && photoUrl.isNotEmpty) {
      await prefs.setString(_kImageKey, photoUrl);
    }
    await prefs.setBool(_kLoggedInKey, true);
    await prefs.setBool(_kGoogleUserKey, true);

    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = false;
    _isGoogleUser = false;
    _userName = 'Guest User';
    _userBio = 'Music Enthusiast';
    _userEmail = '';
    _profileImagePath = null;

    await prefs.setBool(_kLoggedInKey, false);
    await prefs.setBool(_kGoogleUserKey, false);
    await prefs.setString(_kNameKey, _userName);
    await prefs.setString(_kBioKey, _userBio);
    await prefs.setString(_kEmailKey, _userEmail);
    await prefs.remove(_kImageKey);

    notifyListeners();
  }
}
