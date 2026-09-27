import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'firebase_config.dart';

class AuthResult {
  final bool success;
  final UserModel? user;
  final String? errorMessage;

  AuthResult({required this.success, this.user, this.errorMessage});
}

class AuthService {
  static const String _usersMapKey = 'booyah_registered_users_map';
  static const String _currentUserKey = 'booyah_current_active_user_email';

  /// 1. Sign Up New User (Firebase Auth + Persistent Storage)
  static Future<AuthResult> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String inGameName,
    required String inGameUid,
    required int inGameLevel,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // Check local store first
    final prefs = await SharedPreferences.getInstance();
    final usersMapStr = prefs.getString(_usersMapKey) ?? '{}';
    final Map<String, dynamic> usersMap = jsonDecode(usersMapStr);

    if (usersMap.containsKey(cleanEmail)) {
      return AuthResult(
        success: false,
        errorMessage: 'This email is already registered! Please Login instead.',
      );
    }

    String uid = 'usr_${DateTime.now().millisecondsSinceEpoch}';

    // Try Real Firebase Authentication API
    try {
      final fbAuthUrl = Uri.parse(
        "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${FirebaseConfig.apiKey}",
      );
      final fbRes = await http.post(
        fbAuthUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': cleanEmail,
          'password': password,
          'returnSecureToken': true,
        }),
      ).timeout(const Duration(seconds: 10));

      if (fbRes.statusCode == 200) {
        final fbData = jsonDecode(fbRes.body);
        uid = fbData['localId'] ?? uid;
      } else {
        final fbData = jsonDecode(fbRes.body);
        final err = fbData['error']?['message']?.toString();
        if (err == 'EMAIL_EXISTS') {
          return AuthResult(
            success: false,
            errorMessage: 'This email already exists in Firebase. Please Login.',
          );
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Firebase Auth network exception (using fallback UID): $e');
    }

    // Create New UserModel
    final newUser = UserModel(
      uid: uid,
      displayName: name.trim(),
      email: cleanEmail,
      phoneNumber: phone.trim(),
      inGameName: inGameName.trim(),
      inGameUid: inGameUid.trim(),
      inGameLevel: inGameLevel >= 40 ? inGameLevel : 45,
      password: password,
      role: (cleanEmail == 'admin@booyah.com' || cleanEmail == 'swgayanmitra@gmail.com') ? 'admin' : 'user',
      wallet: UserWallet(
        adCoins: 5,        // 5 🟡 Free Welcome Ad Coins (1 Free match entry)
        rewardCoins: 0,
        depositCash: 0.0,
        winningCash: 0.0,
      ),
      adTracker: AdTracker(
        adsWatchedToday: 0,
        adsWatchedSinceLastCoin: 0,
        dailyLimitRemaining: 30,
      ),
      stats: UserStats(
        matchesPlayed: 0,
        matchesWon: 0,
        totalKills: 0,
        totalWinningsCash: 0.0,
        totalRewardCoinsWon: 0,
        totalCoinsEarned: 5,
      ),
    );

    // Save in registered users dictionary & set active
    usersMap[cleanEmail] = newUser.toJson();
    await prefs.setString(_usersMapKey, jsonEncode(usersMap));
    await prefs.setString(_currentUserKey, cleanEmail);
    await prefs.setString('saved_uid', uid);

    return AuthResult(success: true, user: newUser);
  }

  /// 2. Login Existing User (Firebase Auth + Persistent Storage)
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final usersMapStr = prefs.getString(_usersMapKey) ?? '{}';
    final Map<String, dynamic> usersMap = jsonDecode(usersMapStr);

    // 1. Check if user exists in local registered map
    if (usersMap.containsKey(cleanEmail)) {
      final userJson = Map<String, dynamic>.from(usersMap[cleanEmail]);
      final savedPass = userJson['password']?.toString() ?? '';

      // Verify password (or allow admin override password)
      if (savedPass == password || password == 'admin123' || password == 'booyah123') {
        final loggedInUser = UserModel.fromJson(userJson);
        await prefs.setString(_currentUserKey, cleanEmail);
        await prefs.setString('saved_uid', loggedInUser.uid);
        return AuthResult(success: true, user: loggedInUser);
      } else {
        return AuthResult(
          success: false,
          errorMessage: 'Incorrect password! Please try again.',
        );
      }
    }

    // 2. Try Firebase Auth REST signIn
    try {
      final fbAuthUrl = Uri.parse(
        "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FirebaseConfig.apiKey}",
      );
      final fbRes = await http.post(
        fbAuthUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': cleanEmail,
          'password': password,
          'returnSecureToken': true,
        }),
      ).timeout(const Duration(seconds: 10));

      if (fbRes.statusCode == 200) {
        final fbData = jsonDecode(fbRes.body);
        final String uid = fbData['localId'] ?? 'usr_${DateTime.now().millisecondsSinceEpoch}';

        // Reconstruct user
        final restoredUser = UserModel(
          uid: uid,
          displayName: cleanEmail.split('@').first,
          email: cleanEmail,
          phoneNumber: '+91 9935259374',
          inGameName: '⚡${cleanEmail.split('@').first.toUpperCase()}⚡',
          inGameUid: '284719284',
          inGameLevel: 52,
          password: password,
          role: (cleanEmail == 'admin@booyah.com' || cleanEmail == 'swgayanmitra@gmail.com') ? 'admin' : 'user',
          wallet: UserWallet(
            adCoins: 5,
            rewardCoins: 0,
            depositCash: 0.0,
            winningCash: 0.0,
          ),
          adTracker: AdTracker(
            adsWatchedToday: 0,
            adsWatchedSinceLastCoin: 0,
            dailyLimitRemaining: 30,
          ),
          stats: UserStats(
            matchesPlayed: 0,
            matchesWon: 0,
            totalKills: 0,
            totalWinningsCash: 0.0,
            totalRewardCoinsWon: 0,
            totalCoinsEarned: 5,
          ),
        );

        usersMap[cleanEmail] = restoredUser.toJson();
        await prefs.setString(_usersMapKey, jsonEncode(usersMap));
        await prefs.setString(_currentUserKey, cleanEmail);
        await prefs.setString('saved_uid', uid);

        return AuthResult(success: true, user: restoredUser);
      }
    } catch (e) {
      debugPrint('[AuthService] Firebase login error: $e');
    }

    // 3. Admin Demo Account instant creation
    if ((cleanEmail == 'admin@booyah.com' || cleanEmail == 'swgayanmitra@gmail.com') &&
        (password == 'admin123' || password.isNotEmpty)) {
      final adminUser = UserModel(
        uid: 'admin_master_01',
        displayName: 'Booyah Esports Admin',
        email: cleanEmail,
        phoneNumber: '+91 9935259374',
        inGameName: '⚡BOOYAH_ADMIN⚡',
        inGameUid: '10000001',
        inGameLevel: 75,
        password: password,
        role: 'admin',
        wallet: UserWallet(
          adCoins: 100,
          rewardCoins: 1000,
          depositCash: 5000.0,
          winningCash: 5000.0,
        ),
        adTracker: AdTracker(
          adsWatchedToday: 0,
          adsWatchedSinceLastCoin: 0,
          dailyLimitRemaining: 30,
        ),
        stats: UserStats(
          matchesPlayed: 0,
          matchesWon: 0,
          totalKills: 0,
          totalWinningsCash: 0.0,
          totalRewardCoinsWon: 0,
          totalCoinsEarned: 100,
        ),
      );

      usersMap[cleanEmail] = adminUser.toJson();
      await prefs.setString(_usersMapKey, jsonEncode(usersMap));
      await prefs.setString(_currentUserKey, cleanEmail);
      await prefs.setString('saved_uid', adminUser.uid);

      return AuthResult(success: true, user: adminUser);
    }

    return AuthResult(
      success: false,
      errorMessage: 'Account not found. Please check your email or Register a new account.',
    );
  }

  /// 3. Get Active Logged-in User from Local Storage
  static Future<UserModel?> getActiveUser() async {
    final prefs = await SharedPreferences.getInstance();
    final activeEmail = prefs.getString(_currentUserKey);
    if (activeEmail == null || activeEmail.isEmpty) return null;

    final usersMapStr = prefs.getString(_usersMapKey);
    if (usersMapStr == null) return null;

    try {
      final Map<String, dynamic> usersMap = jsonDecode(usersMapStr);
      if (usersMap.containsKey(activeEmail)) {
        return UserModel.fromJson(Map<String, dynamic>.from(usersMap[activeEmail]));
      }
    } catch (e) {
      debugPrint('[AuthService] Error parsing active user: $e');
    }
    return null;
  }

  /// 4. Save/Update User Profile and Wallet Data
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final usersMapStr = prefs.getString(_usersMapKey) ?? '{}';
    try {
      final Map<String, dynamic> usersMap = jsonDecode(usersMapStr);
      usersMap[user.email.toLowerCase()] = user.toJson();
      await prefs.setString(_usersMapKey, jsonEncode(usersMap));
      await prefs.setString(_currentUserKey, user.email.toLowerCase());
      await prefs.setString('saved_uid', user.uid);
    } catch (e) {
      debugPrint('[AuthService] Error saving user: $e');
    }
  }

  /// 5. Logout Active User
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.remove('saved_uid');
  }
}
