import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/tournament_model.dart';
import '../models/chat_model.dart';
import '../models/support_ticket_model.dart';
import 'fcm_service.dart';

class RedeemPackage {
  final String id;
  final int amount;
  final int points;
  final String title;
  final String badge;
  final String description;
  final String colorHex;

  RedeemPackage({
    required this.id,
    required this.amount,
    required this.points,
    required this.title,
    required this.badge,
    required this.description,
    required this.colorHex,
  });

  factory RedeemPackage.fromJson(Map<String, dynamic> json) {
    return RedeemPackage(
      id: json['id'] as String? ?? 'play_50',
      amount: (json['amount'] as num?)?.toInt() ?? 50,
      points: (json['points'] as num?)?.toInt() ?? 10000,
      title: json['title'] as String? ?? '₹50 Google Play Redeem Code',
      badge: json['badge'] as String? ?? 'न्यूनतम रिडीम',
      description: json['description'] as String? ?? '',
      colorHex: json['color'] as String? ?? '#10B981',
    );
  }
}

class RedeemRequestItem {
  final String id;
  final int amount;
  final int pointsCost;
  final String email;
  final String phone;
  final String status; // PENDING | DELIVERED | REJECTED
  final String redeemCode;
  final String adminNotes;
  final String createdAt;
  final String? deliveredAt;
  final String deliveryEta;

  RedeemRequestItem({
    required this.id,
    required this.amount,
    required this.pointsCost,
    required this.email,
    required this.phone,
    required this.status,
    required this.redeemCode,
    required this.adminNotes,
    required this.createdAt,
    this.deliveredAt,
    required this.deliveryEta,
  });

  factory RedeemRequestItem.fromJson(Map<String, dynamic> json) {
    return RedeemRequestItem(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 50,
      pointsCost: (json['pointsCost'] as num?)?.toInt() ?? 10000,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      redeemCode: json['redeemCode'] as String? ?? '',
      adminNotes: json['adminNotes'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      deliveredAt: json['deliveredAt'] as String?,
      deliveryEta: json['deliveryEta'] as String? ?? '24-48 Hours',
    );
  }
}

class LeaderboardEntry {
  final String uid;
  final String name;
  final int weeklyScore;
  final int rank;
  final String prize;

  LeaderboardEntry({
    this.uid = '',
    required this.name,
    required this.weeklyScore,
    required this.rank,
    this.prize = '',
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? 'Player',
      weeklyScore: (json['score'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      prize: json['prize'] as String? ?? '',
    );
  }
}

class WinnerProofItem {
  final String id;
  final String title;
  final String winnerName;
  final String tag;
  final String date;
  final String mediaUrl;
  final String review;

  WinnerProofItem({
    required this.id,
    required this.title,
    required this.winnerName,
    required this.tag,
    required this.date,
    this.mediaUrl = '',
    this.review = '',
  });

  factory WinnerProofItem.fromJson(Map<String, dynamic> json) {
    return WinnerProofItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Prize Verified',
      winnerName: json['winnerName'] as String? ?? 'Winner',
      tag: json['tag'] as String? ?? 'Verified ⚡',
      date: json['date'] as String? ?? '',
      mediaUrl: json['mediaUrl'] as String? ?? '',
      review: json['review'] as String? ?? '',
    );
  }
}

class PastSeasonWinner {
  final int rank;
  final String name;
  final int score;
  final String prize;
  final String status;

  PastSeasonWinner({
    required this.rank,
    required this.name,
    required this.score,
    required this.prize,
    required this.status,
  });

  factory PastSeasonWinner.fromJson(Map<String, dynamic> json) {
    return PastSeasonWinner(
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      name: json['name'] as String? ?? 'Winner',
      score: (json['score'] as num?)?.toInt() ?? 0,
      prize: json['prize'] as String? ?? 'Prize Eligible',
      status: json['status'] as String? ?? 'Credited to Wallet',
    );
  }
}

class PastSeasonArchive {
  final int season;
  final String seasonName;
  final String archivedDate;
  final String payoutDue;
  final List<PastSeasonWinner> winners;

  PastSeasonArchive({
    required this.season,
    required this.seasonName,
    required this.archivedDate,
    required this.payoutDue,
    required this.winners,
  });

  factory PastSeasonArchive.fromJson(Map<String, dynamic> json) {
    return PastSeasonArchive(
      season: (json['season'] as num?)?.toInt() ?? 1,
      seasonName: json['seasonName'] as String? ?? 'Season 1',
      archivedDate: json['archivedDate'] as String? ?? 'Recent',
      payoutDue: json['payoutDue'] as String? ?? 'Daily Auto-Credit',
      winners: (json['winners'] as List? ?? [])
          .map((w) => PastSeasonWinner.fromJson(Map<String, dynamic>.from(w as Map)))
          .toList(),
    );
  }
}

class AppState extends ChangeNotifier {
  static const String vpsBaseUrl = 'https://vps.swgayanbhumi.in';
  static const String _userPrefsKey = 'arena_user_data_v2';

  late UserModel user;
  bool isAuthenticated = false;
  int season = 2;
  String tournamentType = 'weekly';
  bool get isDailyTournament => tournamentType == 'daily';
  String prizePool = '₹1,000';
  String rank1Prize = '₹500';
  String rank2Prize = '₹300';
  String rank3Prize = '₹200';
  List<Map<String, dynamic>> prizesBreakdown = [];
  List<LeaderboardEntry> weeklyLeaderboard = [];
  List<WinnerProofItem> winnerProofs = [];
  List<PastSeasonArchive> pastWinners = [];
  String tournamentNotice = '📢 वीकली चैंपियनशिप लाइव! इस हफ़्ते ₹1,000 का प्राइज़ पूल!';

  // ── 🏆 FREE FIRE INDIA STATE ──
  List<FFTournament> ffTournaments = [];
  bool isLoadingTournaments = false;
  String activeCategory = 'ALL';

  List<ChatMessage> chatMessages = [];
  bool isChatLoading = false;

  List<SupportTicket> mySupportTickets = [];
  bool isSupportLoading = false;

  Map<String, dynamic> coinEconomy = {
    'adCoinReward': 10,
    'dailyAdLimit': 15,
    'welcomeBonus': 20,
    'referralReward': 50,
  };

  Map<String, dynamic> socialLinks = {
    'youtube': 'https://youtube.com/@booyahrewards',
    'instagram': 'https://instagram.com/booyahrewards',
    'telegram': 'https://t.me/booyahrewards',
  };

  Map<String, dynamic> branding = {
    'gameName': 'FREE FIRE INDIA',
    'tagline': 'India Ka Apna Battle Royale',
    'subTagline': 'India Ka Apna Esports Platform',
  };

  List<RedeemPackage> redeemPackages = [
    RedeemPackage(
      id: 'play_50',
      amount: 50,
      points: 5000,
      title: '₹50 Google Play Redeem Code',
      badge: 'न्यूनतम रिडीम (MIN)',
      description: 'Google Play Store बैलेंस में ₹50 सीधे जोड़ें।',
      colorHex: '#10B981',
    ),
    RedeemPackage(
      id: 'play_100',
      amount: 100,
      points: 10000,
      title: '₹100 Google Play Redeem Code',
      badge: 'पॉपुलर (MOST POPULAR)',
      description: 'Google Play Store बैलेंस में ₹100 सीधे जोड़ें।',
      colorHex: '#F59E0B',
    ),
    RedeemPackage(
      id: 'play_250',
      amount: 250,
      points: 25000,
      title: '₹250 Google Play Redeem Code',
      badge: 'बेस्ट वैल्यू (PRO)',
      description: 'Google Play Store बैलेंस में ₹250 सीधे जोड़ें।',
      colorHex: '#8B5CF6',
    ),
    RedeemPackage(
      id: 'play_500',
      amount: 500,
      points: 50000,
      title: '₹500 Google Play Redeem Code',
      badge: 'मेगा बंडल (VIP)',
      description: 'Google Play Store बैलेंस में ₹500 सीधे जोड़ें।',
      colorHex: '#EC4899',
    ),
  ];
  List<RedeemRequestItem> myRedeemRequests = [];
  List<Map<String, dynamic>> liveRedeemFeed = [];
  bool isRedeemLoading = false;

  static final List<WinnerProofItem> defaultProofs = [];

  AppState() {
    user = UserModel.guest();
    _initUser();
  }

  Map<String, dynamic>? appSettings;

  Future<void> fetchAppConfig() async {
    try {
      final url = Uri.parse('https://vps.swgayanbhumi.in/api/app-config');
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          if (data['appSettings'] != null) {
            appSettings = Map<String, dynamic>.from(data['appSettings']);
          }
          if (data['weeklyPrizePool'] != null) {
            prizePool = '₹${(data['weeklyPrizePool'] as num).toInt()}';
          }
          if (data['prizeDistribution'] != null) {
            final p = data['prizeDistribution'] as Map<String, dynamic>;
            final pool = (data['weeklyPrizePool'] as num?)?.toInt() ?? 1000;
            final r1 = (p['rank1Percent'] as num?)?.toInt() ?? 50;
            final r2 = (p['rank2Percent'] as num?)?.toInt() ?? 30;
            final r3 = (p['rank3Percent'] as num?)?.toInt() ?? 20;
            rank1Prize = '₹${(pool * r1 ~/ 100)}';
            rank2Prize = '₹${(pool * r2 ~/ 100)}';
            rank3Prize = '₹${(pool * r3 ~/ 100)}';
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching app config: $e');
    }
  }

  Future<void> _initUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNotice = prefs.getString('tournament_admin_notice');
      if (savedNotice != null && savedNotice.isNotEmpty) {
        tournamentNotice = savedNotice;
      }
      final savedSeason = prefs.getInt('tournament_season');
      if (savedSeason != null) season = savedSeason;
      final savedPrize = prefs.getString('tournament_prize_pool');
      if (savedPrize != null && savedPrize.isNotEmpty) prizePool = savedPrize;
      final userJson = prefs.getString(_userPrefsKey);
      if (userJson != null) {
        final Map<String, dynamic> data = jsonDecode(userJson);
        user = UserModel.fromJson(data);
      } else {
        user = UserModel.guest();
        await saveUser();
      }

      // 🛡️ Season 2 Financial Safeguard: Reset all wallet coins to 0 immediately
      final hasResetSeason2 = prefs.getBool('season2_wallet_hard_zero_v3') ?? false;
      if (!hasResetSeason2) {
        user.adCoins = 0;
        user.weeklyScore = 0;
        await prefs.setBool('season2_wallet_hard_zero_v3', true);
        await saveUser();
      }
    } catch (e) {
      debugPrint('Error loading user from prefs: $e');
      user = UserModel.guest();
    }
    notifyListeners();

    // Fetch live leaderboard, proofs, past winners, redeem data, and sync user with VPS
    await fetchLeaderboard();
    await fetchWinnerProofs();
    await fetchPastWinners();
    await fetchRedeemPackages();
    await fetchMyRedeemRequests();
    await fetchLiveRedeemFeed();
    await syncUserWithVPS();
    await fetchAppConfig();
    await FCMService.initialize(uid: user.uid);
    await fetchFFTournaments();
    await fetchWorldChat();
    await fetchMySupportTickets();
    await fetchMyReferrals();
  }

  Future<void> saveUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString(_userPrefsKey, userJson);
    } catch (e) {
      debugPrint('Error saving user to prefs: $e');
    }
    notifyListeners();
  }

  void _updateConfig(Map<String, dynamic>? config) {
    if (config == null) return;
    if (config['season'] != null) {
      season = (config['season'] as num).toInt();
    }
    if (config['tournamentType'] != null) {
      tournamentType = config['tournamentType'].toString();
    }
    if (config['prizePool'] != null) {
      prizePool = config['prizePool'].toString();
    }
    if (config['prizesBreakdown'] != null) {
      prizesBreakdown = (config['prizesBreakdown'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    if (config['notice'] != null && config['notice'].toString().trim().isNotEmpty) {
      tournamentNotice = config['notice'].toString().trim();
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('tournament_admin_notice', tournamentNotice);
      }).catchError((_) {});
    }
    notifyListeners();
  }

  String pinnedChatNotice = '🔥 Booyah Rewards में आपका स्वागत है! फेयर प्ले रखें और रूम आईडी टाइम पर चेक करें।';

  // ── USER SIGNUP WITH NAME, MOBILE, EMAIL, PASSWORD, REFERRAL ──
  Future<Map<String, dynamic>> signupUser({
    required String name,
    required String phone,
    required String email,
    required String password,
    String inGameName = '',
    String inGameId = '',
    String referralCode = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$vpsBaseUrl/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'phoneNumber': phone.trim(),
          'email': email.trim(),
          'password': password.trim(),
          'inGameName': inGameName.trim(),
          'inGameId': inGameId.trim(),
          'referralCode': referralCode.trim(),
        }),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['success'] == true && data['user'] != null) {
        user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await saveUser();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_email', email.trim());
        await prefs.setString('auth_password', password.trim());
        await prefs.setBool('is_logged_in', true);
        notifyListeners();
        return {'success': true, 'message': data['message'] ?? 'साइन-अप सफल!'};
      }
      return {'success': false, 'message': data['message'] ?? 'साइन-अप विफल रहा।'};
    } catch (e) {
      return {'success': false, 'message': 'नेटवर्क त्रुटि: $e'};
    }
  }

  // ── USER LOGIN WITH EMAIL/PHONE & PASSWORD ──
  Future<Map<String, dynamic>> loginUser({
    required String identifier,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$vpsBaseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': identifier.trim(),
          'password': password.trim(),
        }),
      );
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['success'] == true && data['user'] != null) {
        user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await saveUser();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_email', identifier.trim());
        await prefs.setString('auth_password', password.trim());
        await prefs.setBool('is_logged_in', true);
        notifyListeners();
        return {'success': true, 'message': data['message'] ?? 'लॉगिन सफल!'};
      }
      return {'success': false, 'message': data['message'] ?? 'गलत पासवर्ड या खाता नहीं मिला।'};
    } catch (e) {
      return {'success': false, 'message': 'नेटवर्क त्रुटि: $e'};
    }
  }

  // ── UPDATE FREE FIRE IN-GAME DETAILS ──
  Future<bool> updateFreeFireDetails(String ign, String uid) async {
    user.inGameName = ign.trim();
    user.inGameId = uid.trim();
    await saveUser();
    notifyListeners();

    try {
      await http.post(
        Uri.parse('$vpsBaseUrl/api/auth/update-ff-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': user.uid,
          'inGameName': user.inGameName,
          'inGameId': user.inGameId,
        }),
      );
      return true;
    } catch (e) {
      debugPrint('Error updating FF profile: $e');
      return false;
    }
  }

  // ── Sync Guest User with VPS Backend (Device ID based, No Password Needed) ──
  Future<void> syncUserWithVPS({int scoreToAdd = 0, int coinsToAdd = 0, String referralCode = ''}) async {
    try {
      final res = await http.post(
        Uri.parse('$vpsBaseUrl/api/tournament/sync-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': user.uid,
          'displayName': user.displayName,
          'scoreToAdd': scoreToAdd,
          'coinsToAdd': coinsToAdd,
          'referralCode': referralCode.isNotEmpty ? referralCode : user.referredBy,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['user'] != null) {
          final sUser = data['user'];
          user.weeklyScore = (sUser['weeklyScore'] as num?)?.toInt() ?? user.weeklyScore;
          final sCoins = (sUser['adCoins'] as num?)?.toInt();
          if (sCoins != null) {
            user.adCoins = sCoins;
          }
          final sWinCoins = (sUser['winningCoins'] as num?)?.toInt();
          if (sWinCoins != null) {
            user.winningCoins = sWinCoins;
          }
          if (sUser['referralCode'] != null) {
            user.referralCode = sUser['referralCode'].toString();
          }
          await saveUser();
        }
        if (data['config'] != null) {
          _updateConfig(data['config'] as Map<String, dynamic>);
        }
        if (data['season'] != null) {
          season = (data['season'] as num).toInt();
        }
        if (data['leaderboard'] != null) {
          final list = (data['leaderboard'] as List)
              .map((item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>))
              .toList();
          weeklyLeaderboard = list;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('VPS Sync error (offline fallback): $e');
    }
  }

  // ── Update Display Name on Leaderboard ──
  Future<void> updateDisplayName(String newName) async {
    if (newName.trim().isEmpty) return;
    user.displayName = newName.trim();
    await saveUser();

    try {
      await http.post(
        Uri.parse('$vpsBaseUrl/api/tournament/update-name'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': user.uid,
          'displayName': user.displayName,
        }),
      );
      await fetchLeaderboard();
    } catch (e) {
      debugPrint('Error updating name on VPS: $e');
    }
  }

  // ── 👥 REFERRAL TRACKING STATE & API ──
  List<Map<String, dynamic>> myReferrals = [];
  int referralTargetMatches = 5;
  int referralRewardPerUser = 50;
  int totalReferralCoinsEarned = 0;
  int pendingReferralsCount = 0;
  int unlockedReferralsCount = 0;

  Future<void> fetchMyReferrals() async {
    try {
      final res = await http.get(
        Uri.parse('$vpsBaseUrl/api/referral/my-referrals?uid=${user.uid}'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          referralTargetMatches = (data['targetMatches'] as num?)?.toInt() ?? 5;
          referralRewardPerUser = (data['rewardPerReferral'] as num?)?.toInt() ?? 50;
          totalReferralCoinsEarned = (data['totalCoinsEarned'] as num?)?.toInt() ?? 0;
          pendingReferralsCount = (data['pendingFriends'] as num?)?.toInt() ?? 0;
          unlockedReferralsCount = (data['unlockedFriends'] as num?)?.toInt() ?? 0;
          if (data['referrals'] is List) {
            myReferrals = List<Map<String, dynamic>>.from(data['referrals']);
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching my referrals: $e');
    }
  }

  // ── Apply Referral Code ──
  Future<bool> applyReferralCode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty || cleanCode == user.referralCode || user.referredBy.isNotEmpty) return false;
    user.referredBy = cleanCode;
    user.adCoins += 10; // +10 Bonus coins for entering friend's code
    await saveUser();
    await syncUserWithVPS(referralCode: cleanCode);
    await fetchMyReferrals();
    notifyListeners();
    return true;
  }

  // ── Submit Payout Claim (Allowed for Top 10 Winners) ──
  Future<Map<String, dynamic>> submitPayoutClaim({
    required String phoneNumber,
    required String email,
    String upiId = '',
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$vpsBaseUrl/api/tournament/submit-payout-details'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': user.uid,
          'phoneNumber': phoneNumber,
          'email': email,
          'upiId': upiId,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        await syncUserWithVPS();
        return {'success': true, 'message': data['message'] ?? 'Payout details submitted!'};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Submission failed.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ── Fetch Redeem Packages from VPS ──
  Future<void> fetchRedeemPackages() async {
    try {
      final res = await http.get(Uri.parse('$vpsBaseUrl/api/redeem/packages'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['packages'] != null) {
          redeemPackages = (data['packages'] as List)
              .map((p) => RedeemPackage.fromJson(Map<String, dynamic>.from(p as Map)))
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching redeem packages: $e');
    }
  }

  // ── Fetch User\'s Redeem Requests ──
  Future<void> fetchMyRedeemRequests() async {
    try {
      final res = await http.get(Uri.parse('$vpsBaseUrl/api/redeem/my-requests?deviceId=${user.uid}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['requests'] != null) {
          myRedeemRequests = (data['requests'] as List)
              .map((r) => RedeemRequestItem.fromJson(Map<String, dynamic>.from(r as Map)))
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching my redeem requests: $e');
    }
  }

  // ── Fetch Live Redeem Feed (Social Proof) ──
  Future<void> fetchLiveRedeemFeed() async {
    try {
      final res = await http.get(Uri.parse('$vpsBaseUrl/api/redeem/live-feed'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['feed'] != null) {
          liveRedeemFeed = (data['feed'] as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching live redeem feed: $e');
    }
  }

  // ── Submit Redeem Code Request (100 Coins = ₹1) ──
  Future<Map<String, dynamic>> submitRedeemRequest({
    required int amount,
    required String email,
    String phone = '',
    String upiId = '',
    String packageId = '',
  }) async {
    final pointsNeeded = amount * 100; // 100 Coins = ₹1
    final currentBalance = user.adCoins;
    if (currentBalance < pointsNeeded) {
      return {
        'success': false,
        'message': 'आपके वॉलेट में पर्याप्त कॉइन्स नहीं हैं! आवश्यक: $pointsNeeded कॉइन्स (₹$amount), वर्तमान: $currentBalance कॉइन्स।',
      };
    }

    isRedeemLoading = true;
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse('$vpsBaseUrl/api/redeem/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': user.uid,
          'displayName': user.displayName,
          'amount': amount,
          'email': email,
          'phone': phone,
          'upiId': upiId,
          'packageId': packageId,
        }),
      );

      final data = jsonDecode(res.body);
      isRedeemLoading = false;

      if (res.statusCode == 200 && data['success'] == true) {
        final newCoins = user.adCoins - pointsNeeded;
        user.adCoins = newCoins < 0 ? 0 : newCoins;
        await saveUser();
        await fetchMyRedeemRequests();
        notifyListeners();
        return {
          'success': true,
          'message': data['message'] ?? 'रिडीम रिक्वेस्ट सबमिट हो गई! 24-48 घंटे में कोड डिलीवर होगा।',
        };
      } else {
        notifyListeners();
        return {
          'success': false,
          'message': data['error'] ?? 'सबमिशन विफल हुआ। कृपया दोबारा प्रयास करें।',
        };
      }
    } catch (e) {
      isRedeemLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'नेटवर्क त्रुटि: $e',
      };
    }
  }

  // ── Fetch Live Tournament Leaderboard ──
  Future<void> fetchLeaderboard() async {
    try {
      final res = await http.get(Uri.parse('$vpsBaseUrl/api/leaderboard'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['prizePool'] != null) {
          prizePool = data['prizePool'].toString();
        }
        if (data['prizes'] != null) {
          final p = data['prizes'] as Map<String, dynamic>;
          if (p['rank1'] != null) rank1Prize = p['rank1'].toString();
          if (p['rank2'] != null) rank2Prize = p['rank2'].toString();
          if (p['rank3'] != null) rank3Prize = p['rank3'].toString();
        }
        if (data['season'] != null) {
          season = (data['season'] as num).toInt();
        }
        if (data['success'] == true && data['leaderboard'] != null) {
          final list = (data['leaderboard'] as List)
              .map((item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>))
              .toList();
          weeklyLeaderboard = list;
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
    }
  }

  Future<bool> canPlayFreeToday(String gameId) async {
    return true; // 100% Unlimited Free Play for all skill games
  }

  Future<void> markGamePlayedToday(String gameId) async {
    // No-op: Unlimited free play active
  }

  // ── Fetch Live Winner Proofs from VPS ──
  Future<void> fetchWinnerProofs() async {
    try {
      final res = await http.get(Uri.parse('$vpsBaseUrl/api/tournament/winner-proofs'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['proofs'] != null) {
          final list = (data['proofs'] as List)
              .map((item) => WinnerProofItem.fromJson(item as Map<String, dynamic>))
              .toList();
          winnerProofs = list;
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching proofs: $e');
    }
  }

  // ── Fetch Past Seasons Winners Archive (For 25th Payout Transparency) ──
  Future<void> fetchPastWinners() async {
    try {
      final res = await http.get(Uri.parse('$vpsBaseUrl/api/tournament/past-winners'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['pastWinners'] != null) {
          final list = (data['pastWinners'] as List)
              .map((item) => PastSeasonArchive.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          pastWinners = list;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching past winners: $e');
    }
  }

  bool get isDailyNight2XRush {
    // Daily Night 2X Rush every night from 9:00 PM to 11:00 PM (21:00 to 22:59:59)
    final now = DateTime.now();
    return now.hour >= 21 && now.hour < 23;
  }

  bool get isWeekend2XRush => isDailyNight2XRush;

  int get rushMultiplier => isDailyNight2XRush ? 2 : 1;
  int get weekendMultiplier => rushMultiplier;

  int get walletPoints => user.adCoins;

  void addGameScore(int score, String gameType) {
    final addedScore = isWeekend2XRush ? score * 2 : score;
    user.gameScore += score;
    user.weeklyScore += addedScore;
    if (gameType == 'knife_hit' && score > user.knifeHitHighScore) {
      user.knifeHitHighScore = score;
    } else if (gameType == 'fruit_slash' && score > user.fruitSlashHighScore) {
      user.fruitSlashHighScore = score;
    } else if (gameType == 'speed_math' && score > user.speedMathHighScore) {
      user.speedMathHighScore = score;
    }
    saveUser();
    syncUserWithVPS(scoreToAdd: addedScore);
  }

  // ── Add Coins to In-App Wallet ONLY (Disconnected from Leaderboard) ──
  void addWalletCoins(int coins) {
    if (coins <= 0) return;
    user.adCoins += coins;
    saveUser();
    notifyListeners();
    syncUserWithVPS(coinsToAdd: coins);
  }

  void addAdCoins(int coins) {
    addWalletCoins(coins);
  }

  void updateSpeedMathHighScore(int score) {
    if (score > user.speedMathHighScore) {
      user.speedMathHighScore = score;
    }
    final addedScore = isWeekend2XRush ? score * 2 : score;
    user.gameScore += score;
    user.weeklyScore += addedScore;
    saveUser();
    syncUserWithVPS(scoreToAdd: addedScore);
  }

  void updateKnifeHitHighScore(int score) {
    if (score > user.knifeHitHighScore) {
      user.knifeHitHighScore = score;
    }
    final addedScore = isWeekend2XRush ? score * 2 : score;
    user.gameScore += score;
    user.weeklyScore += addedScore;
    saveUser();
    syncUserWithVPS(scoreToAdd: addedScore);
  }

  void updateFruitSlashHighScore(int score) {
    if (score > user.fruitSlashHighScore) {
      user.fruitSlashHighScore = score;
    }
    final addedScore = isWeekend2XRush ? score * 2 : score;
    user.gameScore += score;
    user.weeklyScore += addedScore;
    saveUser();
    syncUserWithVPS(scoreToAdd: addedScore);
  }

  int get numericPrizePool {
    final cleaned = prizePool.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 1000;
  }

  String getPrizeForRank(int rank) {
    if (rank == 1) return '$rank1Prize Cash / Code';
    if (rank == 2) return '$rank2Prize Cash / Code';
    if (rank == 3) return '$rank3Prize Cash / Code';
    return '';
  }

  List<LeaderboardEntry> get dynamicWeeklyLeaderboard {
    // Clone base entries without duplicates of current user
    final list = weeklyLeaderboard
        .where((e) =>
            e.uid != user.uid &&
            e.name != user.displayName &&
            !e.name.contains('(YOU)'))
        .toList();

    // Insert current user with real-time weekly score
    list.add(LeaderboardEntry(
      uid: user.uid,
      name: user.displayName,
      weeklyScore: user.weeklyScore,
      rank: 0,
      prize: '',
    ));

    // Sort strictly descending by score
    list.sort((a, b) => b.weeklyScore.compareTo(a.weeklyScore));

    // Assign dynamic ranks 1..N
    final ranked = <LeaderboardEntry>[];
    for (int i = 0; i < list.length; i++) {
      final e = list[i];
      final rank = i + 1;
      final isSelf = e.uid == user.uid || e.name == user.displayName;
      ranked.add(LeaderboardEntry(
        uid: e.uid,
        name: isSelf ? '${user.displayName} (YOU)' : e.name,
        weeklyScore: e.weeklyScore,
        rank: rank,
        prize: getPrizeForRank(rank),
      ));
    }
    return ranked;
  }

  int get userWeeklyRank {
    final list = dynamicWeeklyLeaderboard;
    final index = list.indexWhere((e) => e.uid == user.uid || e.name.contains('(YOU)'));
    if (index != -1) {
      return list[index].rank;
    }
    return list.length;
  }

  int get rank10ThresholdScore {
    final list = dynamicWeeklyLeaderboard;
    if (list.length >= 10) {
      return list[9].weeklyScore;
    }
    return 100;
  }

  int get pointsNeededForTop10 {
    final gap = rank10ThresholdScore - user.weeklyScore + 5;
    return gap > 0 ? gap : 10;
  }

  // ============================================================================
  // 🏆 FREE FIRE INDIA TOURNAMENTS ENGINE METHODS
  // ============================================================================
  Future<void> fetchFFTournaments({String category = 'ALL'}) async {
    activeCategory = category;
    isLoadingTournaments = true;
    notifyListeners();
    try {
      final uri = Uri.parse('$vpsBaseUrl/api/ff/tournaments?category=$category&uid=${user.uid}');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['tournaments'] != null) {
          final list = (data['tournaments'] as List)
              .map((t) => FFTournament.fromJson(t as Map<String, dynamic>))
              .toList();
          ffTournaments = list;
        }
        if (data['coinEconomy'] != null) {
          coinEconomy = Map<String, dynamic>.from(data['coinEconomy'] as Map);
        }
        if (data['branding'] != null) {
          branding = Map<String, dynamic>.from(data['branding'] as Map);
        }
      }
    } catch (e) {
      debugPrint('Error fetching tournaments: $e');
    } finally {
      isLoadingTournaments = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> registerTournament({
    required String tournamentId,
    required String inGameName,
    required String inGameId,
  }) async {
    try {
      user.inGameName = inGameName;
      user.inGameId = inGameId;
      await saveUser();

      final res = await http.post(
        Uri.parse('$vpsBaseUrl/api/ff/tournaments/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tournamentId': tournamentId,
          'uid': user.uid,
          'inGameName': inGameName,
          'inGameId': inGameId,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        if (data['remainingCoins'] != null) {
          user.adCoins = (data['remainingCoins'] as num).toInt();
          await saveUser();
        }
        await fetchFFTournaments(category: activeCategory);
        return {'success': true, 'message': data['message'] ?? 'Slot registered!'};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> createSquadTeam({
    required String tournamentId,
    required String teamName,
    required String inGameName,
    required String inGameId,
  }) async {
    try {
      user.inGameName = inGameName;
      user.inGameId = inGameId;
      await saveUser();

      final res = await http.post(
        Uri.parse('$vpsBaseUrl/api/ff/teams/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tournamentId': tournamentId,
          'captainUid': user.uid,
          'captainInGameName': inGameName,
          'captainInGameId': inGameId,
          'teamName': teamName,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        if (data['remainingCoins'] != null) {
          user.adCoins = (data['remainingCoins'] as num).toInt();
          await saveUser();
        }
        await fetchFFTournaments(category: activeCategory);
        return {
          'success': true,
          'teamCode': data['teamCode'],
          'message': data['message'],
        };
      } else {
        return {'success': false, 'message': data['error'] ?? 'Could not create team'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> joinSquadTeam({
    required String teamCode,
    required String inGameName,
    required String inGameId,
  }) async {
    try {
      user.inGameName = inGameName;
      user.inGameId = inGameId;
      await saveUser();

      final res = await http.post(
        Uri.parse('$vpsBaseUrl/api/ff/teams/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'teamCode': teamCode.trim().toUpperCase(),
          'uid': user.uid,
          'inGameName': inGameName,
          'inGameId': inGameId,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        if (data['remainingCoins'] != null) {
          user.adCoins = (data['remainingCoins'] as num).toInt();
          await saveUser();
        }
        await fetchFFTournaments(category: activeCategory);
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to join team'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> fetchRoomCredentials(String tournamentId, String groupId) async {
    try {
      final res = await http.get(
        Uri.parse('$vpsBaseUrl/api/ff/room-credentials/$tournamentId/$groupId?uid=${user.uid}'),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'message': 'Failed to fetch credentials'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> watchAdEarnCoins() async {
    try {
      final res = await http.post(
        Uri.parse('$vpsBaseUrl/api/ff/watch-ad-coin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': user.uid}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        final coins = (data['coinsEarned'] as num?)?.toInt() ?? 10;
        user.adCoins += coins;
        await saveUser();
        notifyListeners();
        return {'success': true, 'coinsEarned': coins, 'message': data['message']};
      }
      return {'success': false, 'message': 'Ad reward failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> claimDailyStreak() async {
    try {
      final res = await http.post(
        Uri.parse('$vpsBaseUrl/api/ff/daily-checkin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': user.uid}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        user.adCoins = (data['totalCoins'] as num?)?.toInt() ?? (user.adCoins + 10);
        user.streakDays = (data['dayNumber'] as num?)?.toInt() ?? (user.streakDays + 1);
        user.lastCheckInDate = DateTime.now().toIso8601String();
        await saveUser();
        notifyListeners();
        return {'success': true, 'message': data['message'], 'coins': data['coinsAwarded']};
      }
      return {'success': false, 'message': data['error'] ?? 'Check-in failed'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<void> fetchWorldChat() async {
    try {
      final res = await http.get(Uri.parse('$vpsBaseUrl/api/ff/chat'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['messages'] != null) {
          chatMessages = (data['messages'] as List)
              .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
              .toList();
          if (data['pinned'] != null && data['pinned']['text'] != null) {
            pinnedChatNotice = data['pinned']['text'].toString();
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching chat: $e');
    }
  }

  Future<bool> sendChatMessage(String text) async {
    if (text.trim().isEmpty) return false;
    try {
      final res = await http.post(
        Uri.parse('$vpsBaseUrl/api/ff/chat/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': user.uid,
          'senderName': user.inGameName.isNotEmpty ? user.inGameName : user.displayName,
          'text': text.trim(),
        }),
      );
      if (res.statusCode == 200) {
        await fetchWorldChat();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchMySupportTickets() async {
    isSupportLoading = true;
    notifyListeners();
    try {
      final res = await http.get(Uri.parse('$vpsBaseUrl/api/support/user/${user.uid}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['tickets'] != null) {
          mySupportTickets = (data['tickets'] as List)
              .map((t) => SupportTicket.fromJson(t as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching support: $e');
    } finally {
      isSupportLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitSupportTicket(String category, String subject, String message) async {
    if (message.trim().isEmpty) return false;
    try {
      final res = await http.post(
        Uri.parse('$vpsBaseUrl/api/support/ticket'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': user.uid,
          'userName': user.inGameName.isNotEmpty ? user.inGameName : user.displayName,
          'category': category,
          'subject': subject,
          'message': message.trim(),
        }),
      );
      if (res.statusCode == 200) {
        await fetchMySupportTickets();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ── 🕹️ MINI-GAME ARCADE ZONE ──
  Future<Map<String, dynamic>> claimMiniGameReward({
    required String gameId,
    required int score,
    bool doubleReward = false,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$vpsBaseUrl/api/minigame/claim-reward'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': user.uid,
          'gameId': gameId,
          'score': score,
          'doubleReward': doubleReward,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final earned = (data['coinsEarned'] as num?)?.toInt() ?? 0;
          if (earned > 0) {
            user.adCoins = (data['totalCoins'] as num?)?.toInt() ?? (user.adCoins + earned);
            user.miniGameCoinsToday = (data['miniGameCoinsToday'] as num?)?.toInt() ?? (user.miniGameCoinsToday + earned);
            user.weeklyScore += score + (earned * 5);
            await saveUser();
            notifyListeners();
          }
        }
        return data;
      }
      return {'success': false, 'message': 'Network error. Try again.'};
    } catch (e) {
      debugPrint('claimMiniGameReward error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('auth_email');
    await prefs.remove('auth_password');
    user = UserModel.guest();
    await saveUser();
    notifyListeners();
  }

  Future<Map<String, dynamic>> fetchMiniGameStatus() async {
    try {
      final res = await http.get(Uri.parse('$vpsBaseUrl/api/minigame/status/${user.uid}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          user.miniGameCoinsToday = (data['miniGameCoinsToday'] as num?)?.toInt() ?? user.miniGameCoinsToday;
          notifyListeners();
        }
        return data;
      }
      return {'success': false};
    } catch (e) {
      debugPrint('fetchMiniGameStatus error: $e');
      return {'success': false};
    }
  }
}
