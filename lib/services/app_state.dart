import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../models/team_model.dart';
import '../models/transaction_model.dart';
import '../models/withdrawal_model.dart';
import '../models/voucher_model.dart';
import '../models/banner_model.dart';
import '../models/notification_model.dart';
import 'firestore_rest_service.dart';
import 'firebase_config.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'notification_bridge/notification_bridge.dart';
import 'web_storage/web_storage.dart';

class AppState extends ChangeNotifier {
  late UserModel user;
  final NotificationService _notificationService = NotificationService();
  NotificationService get notificationService => _notificationService;

  Timer? _liveSyncTimer;
  final Set<String> _alertedNotifIds = {};

  List<MatchModel> matches = [];
  List<TransactionModel> transactions = [];
  List<TransactionModel> allGlobalTransactions = [];
  List<WithdrawalModel> withdrawals = [];
  List<WithdrawalModel> allGlobalWithdrawals = [];
  List<VoucherClaim> voucherClaims = [];
  List<VoucherClaim> allGlobalVoucherClaims = [];
  List<AppNotification> notifications = [];
  List<AppNotification> allGlobalNotifications = [];
  int globalTotalAdsWatched = 0;
  List<BannerModel> banners = [];
  String telegramSupportUrl = 'https://t.me/swgayanmitra';
  bool isRealCashModeEnabled = false; // Google Play Review Safe Mode Toggle (False = Only Coins & Ads visible)
  bool isLiveSyncing = false;
  bool isAuthenticated = false;
  bool isLoadingAuth = true;

  // Rewards Store with exact rates (10 Reward Coins = ₹1 Value, Min ₹10 Play Code = 100 Coins)
  List<StoreItem> storeItems = [
    StoreItem(
      id: 'store_gp_10',
      title: '₹10 Google Play Redeem Code',
      description: 'Instant Google Play code sent to your WhatsApp.',
      imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=300&auto=format&fit=crop&q=80',
      iconEmoji: '🎟️',
      rewardCoinsPrice: 100, // 100 Winning Coins = ₹10 Play Code
      rewardValue: '₹10 Play Code',
    ),
    StoreItem(
      id: 'store_gp_40',
      title: '₹40 Google Play Redeem Code',
      description: 'Use for Free Fire Special Airdrop or Crates.',
      imageUrl: 'https://images.unsplash.com/photo-1612287233202-b2a637c3579e?w=300&auto=format&fit=crop&q=80',
      iconEmoji: '🎟️',
      rewardCoinsPrice: 400, // 400 Winning Coins = ₹40 Play Code
      rewardValue: '₹40 Play Code',
    ),
    StoreItem(
      id: 'store_ff_100',
      title: '100 Free Fire Diamonds 💎',
      description: 'Direct diamond top-up to your Free Fire Player UID.',
      imageUrl: 'https://images.unsplash.com/photo-1563089145-599997674d42?w=300&auto=format&fit=crop&q=80',
      iconEmoji: '💎',
      rewardCoinsPrice: 400, // 400 Winning Coins = 100 Free Fire Diamonds
      rewardValue: '100 Diamonds',
    ),
    StoreItem(
      id: 'store_gp_100',
      title: '₹100 Google Play Code',
      description: 'Purchase Free Fire Booyah Pass or Character bundles.',
      imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=300&auto=format&fit=crop&q=80',
      iconEmoji: '🎟️',
      rewardCoinsPrice: 1000,
      rewardValue: '₹100 Play Code',
    ),
    StoreItem(
      id: 'store_ff_210',
      title: '210 Free Fire Diamonds 💎',
      description: 'Diamond top-up with bonus event eligibility.',
      imageUrl: 'https://images.unsplash.com/photo-1563089145-599997674d42?w=300&auto=format&fit=crop&q=80',
      iconEmoji: '💎',
      rewardCoinsPrice: 800,
      rewardValue: '210 Diamonds',
    ),
  ];

  String selectedFilter = 'ALL';
  String selectedFormat = 'ALL';
  String selectedMode = 'ALL'; // 'ALL', 'BR', 'CS', 'LONE_WOLF'
  String selectedTeamType = 'ALL'; // 'ALL', 'SOLO', 'DUO', 'SQUAD'
  String selectedStatus = 'ALL'; // 'ALL', 'UPCOMING', 'ONGOING', 'COMPLETED'

  void setStatusFilter(String status) {
    selectedStatus = status;
    notifyListeners();
  }

  void setMode(String mode) {
    selectedMode = mode;
    notifyListeners();
  }

  void setTeamType(String teamType) {
    selectedTeamType = teamType;
    notifyListeners();
  }

  void setFilter(String filter) {
    selectedFilter = filter;
    notifyListeners();
  }

  void setFormat(String format) {
    selectedFormat = format;
    notifyListeners();
  }

  AppState() {
    _initData();
    _loadLocalDataCache();
    _initNotifications();
    _syncWithFirestore();
    _startLiveSyncTimer();
  }

  void _startLiveSyncTimer() {
    _liveSyncTimer?.cancel();
    _liveSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _syncWithFirestore();
    });
  }

  Future<void> _loadLocalDataCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedMatchesJson = WebStorageHelper.getItem('booyah_cached_matches') ?? prefs.getString('booyah_cached_matches');
      if (cachedMatchesJson != null && cachedMatchesJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(cachedMatchesJson);
        if (list.isNotEmpty && matches.isEmpty) {
          matches = list.map((d) => MatchModel.fromJson(Map<String, dynamic>.from(d))).toList();
          notifyListeners();
        }
      }

      final cachedTxnsJson = WebStorageHelper.getItem('booyah_cached_txns') ?? prefs.getString('booyah_cached_txns');
      if (cachedTxnsJson != null && cachedTxnsJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(cachedTxnsJson);
        if (list.isNotEmpty && allGlobalTransactions.isEmpty) {
          allGlobalTransactions = list.map((d) => TransactionModel.fromJson(Map<String, dynamic>.from(d))).toList();
          transactions = allGlobalTransactions.where((t) => t.userId == user.uid).toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[AppState] Load local cache error: $e');
    }
  }

  void _saveLocalMatchesCache() {
    try {
      final list = matches.map((m) => m.toJson()).toList();
      final jsonStr = jsonEncode(list);
      WebStorageHelper.setItem('booyah_cached_matches', jsonStr);
      SharedPreferences.getInstance().then((prefs) => prefs.setString('booyah_cached_matches', jsonStr));
    } catch (e) {
      debugPrint('[AppState] Save local matches cache error: $e');
    }
  }

  void _saveLocalTxnCache() {
    try {
      final list = allGlobalTransactions.map((t) => t.toJson()).toList();
      final jsonStr = jsonEncode(list);
      WebStorageHelper.setItem('booyah_cached_txns', jsonStr);
      SharedPreferences.getInstance().then((prefs) => prefs.setString('booyah_cached_txns', jsonStr));
    } catch (e) {
      debugPrint('[AppState] Save local txn cache error: $e');
    }
  }

  void _initNotifications() {
    _notificationService.initialize(userId: user.uid);
    _notificationService.onNotificationReceived.listen((notif) {
      _alertedNotifIds.add(notif.id);
      allGlobalNotifications.removeWhere((n) => n.id == notif.id || (n.title == notif.title && n.body == notif.body));
      allGlobalNotifications.insert(0, notif);

      final bool isRelevant = notif.targetType == 'all' ||
          (notif.targetType == 'match' && matches.any((m) => m.id == notif.targetId && m.participants.any((p) => p.uid == user.uid))) ||
          (notif.targetType == 'user' && notif.targetId == user.uid) ||
          (notif.targetType == 'admin' && user.role == 'admin');
      if (isRelevant) {
        notifications.removeWhere((n) => n.id == notif.id || (n.title == notif.title && n.body == notif.body));
        notifications.insert(0, notif);
        if (kIsWeb) {
          showBrowserNotification(notif.title, notif.body, imageUrl: notif.imageUrl);
        }
      }
      notifyListeners();
    });
  }

  void _checkAndTriggerMatchAutoStart(MatchModel match) {
    if (match.isFull && (match.status == MatchStatus.upcoming || match.status == MatchStatus.roomFilling)) {
      if (match.status != MatchStatus.roomFilling || match.roomFillingStartedAt == null) {
        match.status = MatchStatus.roomFilling;
        match.roomFillingStartedAt = DateTime.now();
        _syncMatch(match);
        _notificationService.triggerMatchFullAutoAlert(match: match);
        debugPrint('🚀 [Dynamic Auto-Start] Triggered for Match ${match.id} (${match.title}) - 15m Countdown Active');
      }
    }
  }

  void setUser(UserModel u) {
    user = u;
    isAuthenticated = true;
    _notificationService.initialize(userId: u.uid);
    notifyListeners();
    _syncUser();
    AuthService.saveUser(u);
  }

  Future<void> logout() async {
    await AuthService.logout();
    isAuthenticated = false;
    _initData();
    notifyListeners();
  }

  void _initData() {
    // 1. Initial Default Placeholder User
    user = UserModel(
      uid: 'user_guest',
      displayName: 'Free Fire Gamer',
      email: 'gamer@booyah.com',
      phoneNumber: '',
      inGameName: '⚡BOOYAH_WARRIOR⚡',
      inGameUid: '284719284',
      inGameLevel: 52,
      wallet: UserWallet(
        adCoins: 5,        // 5 Ad Coins Welcome Bonus
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
      role: 'user',
    );

    // Matches, Transactions, Withdrawals, Voucher Claims will be populated directly from Firestore
    matches = [];
    transactions = [];
    withdrawals = [];
    voucherClaims = [];
    banners = [
      BannerModel(
        id: 'banner_ff_01',
        title: '🔥 Free Fire Esports Tournament - Win Real Cash & Diamonds',
        imageUrl: 'imgasest/brhomescreen .png',
        clickUrl: telegramSupportUrl,
        createdAt: DateTime.now(),
      ),
      BannerModel(
        id: 'banner_ff_02',
        title: '💬 Join Official Telegram Community & 24/7 Support',
        imageUrl: 'imgasest/cshomescreen.png',
        clickUrl: telegramSupportUrl,
        createdAt: DateTime.now(),
      ),
    ];
  }

  List<BannerModel> get activeBanners {
    if (!isRealCashModeEnabled) {
      return banners.map((b) {
        final sanitizedTitle = b.title.replaceAll(RegExp(r'Real Cash|₹\d+|75/25|Instant UPI', caseSensitive: false), 'Redeem Codes & Diamonds');
        return BannerModel(
          id: b.id,
          title: sanitizedTitle,
          imageUrl: b.imageUrl,
          clickUrl: b.clickUrl,
          isActive: b.isActive,
          createdAt: b.createdAt,
        );
      }).toList();
    }
    return banners;
  }

  // --- GETTERS ---
  List<MatchModel> get myMatches {
    return matches.where((m) => m.participants.any((p) => p.uid == user.uid)).toList();
  }

  List<MatchModel> get filteredMatches {
    final list = matches.where((m) {
      // If Real Cash mode is disabled (Safe Review Mode), HIDE all paid matches
      if (!isRealCashModeEnabled && m.matchType != MatchType.free) return false;

      // 1. Free / Paid Filter
      if (selectedFilter == 'FREE' && m.matchType != MatchType.free) return false;
      if (selectedFilter == 'PAID' && m.matchType != MatchType.paid) return false;

      // 2. Mode Filter (BR, CS, Lone Wolf)
      if (selectedMode == 'BR' && m.mode != MatchMode.br) return false;
      if (selectedMode == 'CS' && m.mode != MatchMode.cs) return false;
      if (selectedMode == 'LONE_WOLF' && m.mode != MatchMode.loneWolf) return false;

      // 3. Team Type Filter (Solo, Duo, Squad)
      if (selectedTeamType == 'SOLO' && m.teamType != TeamType.solo) return false;
      if (selectedTeamType == 'DUO' && m.teamType != TeamType.duo) return false;
      if (selectedTeamType == 'SQUAD' && m.teamType != TeamType.squad) return false;

      // 4. Status Filter (Upcoming, Ongoing, Completed/Resulted)
      if (selectedStatus == 'UPCOMING' && m.status != MatchStatus.upcoming) return false;
      if (selectedStatus == 'ONGOING' && m.status != MatchStatus.ongoing) return false;
      if (selectedStatus == 'COMPLETED' && m.status != MatchStatus.completed) return false;
      // In main 'ALL' lobby, only show active joinable matches (Upcoming & Live), completed matches are in Resulted tab
      if (selectedStatus == 'ALL' && m.status == MatchStatus.completed) return false;

      return true;
    }).toList();

    // Sort: Upcoming & Ongoing first, Completed at end
    list.sort((a, b) {
      int scoreA = a.status == MatchStatus.upcoming ? 0 : (a.status == MatchStatus.ongoing ? 1 : 2);
      int scoreB = b.status == MatchStatus.upcoming ? 0 : (b.status == MatchStatus.ongoing ? 1 : 2);
      return scoreA.compareTo(scoreB);
    });

    return list;
  }

  // --- JOIN MATCH WITH SPECIFIC SLOT SELECTION ---
  Map<String, dynamic> joinMatchWithSlot({
    required String matchId,
    required int chosenSlot,
    required String inGameName,
    required String inGameUid,
  }) {
    final matchIndex = matches.indexWhere((m) => m.id == matchId);
    if (matchIndex == -1) {
      return {'success': false, 'message': 'Match not found'};
    }

    final match = matches[matchIndex];

    if (match.isSlotTaken(chosenSlot)) {
      return {'success': false, 'message': 'Slot #$chosenSlot is already taken! Please choose another slot.'};
    }

    if (match.participants.any((p) => p.uid == user.uid)) {
      return {'success': false, 'message': 'You have already joined this match!'};
    }

    user.inGameName = inGameName;
    user.inGameUid = inGameUid;

    double balBefore = 0.0;
    double balAfter = 0.0;
    String walletUsed = '';

    // DEDUCT ENTRY FEE WITH SMART PRIORITY (Bonus Cash -> Deposit Cash -> Winning Cash)
    if (match.matchType == MatchType.free) {
      if (user.wallet.adCoins < match.entryFee) {
        return {
          'success': false,
          'message': 'Insufficient Ad Coins! You need ${match.entryFee.toInt()} 🟡 Ad Coins. Watch ads to earn free coins.'
        };
      }
      balBefore = user.wallet.adCoins.toDouble();
      user.wallet.adCoins -= match.entryFee.toInt();
      balAfter = user.wallet.adCoins.toDouble();
      walletUsed = 'AD_COINS';
    } else {
      // PAID MATCH: Smart Priority Deduction
      final fee = match.entryFee;
      if (user.wallet.totalPlayableCash < fee) {
        return {
          'success': false,
          'message': 'Insufficient Balance! Entry fee is ₹${fee.toInt()}. Add cash via Razorpay.'
        };
      }

      double remaining = fee;
      balBefore = user.wallet.totalPlayableCash;

      // 1. Deduct from 🎁 Bonus Cash
      if (user.wallet.bonusCash > 0) {
        final deduct = user.wallet.bonusCash >= remaining ? remaining : user.wallet.bonusCash;
        user.wallet.bonusCash -= deduct;
        remaining -= deduct;
      }

      // 2. Deduct from 💵 Deposit Cash
      if (remaining > 0 && user.wallet.depositCash > 0) {
        final deduct = user.wallet.depositCash >= remaining ? remaining : user.wallet.depositCash;
        user.wallet.depositCash -= deduct;
        remaining -= deduct;
      }

      // 3. Deduct from 🏆 Winning Cash
      if (remaining > 0 && user.wallet.winningCash > 0) {
        final deduct = user.wallet.winningCash >= remaining ? remaining : user.wallet.winningCash;
        user.wallet.winningCash -= deduct;
        remaining -= deduct;
      }

      balAfter = user.wallet.totalPlayableCash;
      walletUsed = 'REAL_CASH';
    }

    final participant = MatchParticipant(
      uid: user.uid,
      inGameName: user.inGameName ?? inGameName,
      inGameUid: user.inGameUid ?? inGameUid,
      slotNumber: chosenSlot,
      paidWith: walletUsed,
      amountPaid: match.entryFee,
      joinedAt: DateTime.now(),
    );

    match.participants.add(participant);
    match.filledSlots += 1;
    user.stats.matchesPlayed += 1;

    transactions.insert(
      0,
      TransactionModel(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        userName: user.displayName,
        type: TransactionType.matchEntryFee,
        walletAffected: match.matchType == MatchType.free ? WalletType.adCoins : WalletType.depositCash,
        amount: -match.entryFee,
        currency: match.matchType == MatchType.free ? 'AD_COINS' : 'INR',
        balanceBefore: balBefore,
        balanceAfter: balAfter,
        status: 'SUCCESS',
        description: 'Joined ${match.title} (Slot #$chosenSlot)',
        createdAt: DateTime.now(),
      ),
    );

    _syncUser();
    _checkAndTriggerMatchAutoStart(match);
    _syncMatch(match);
    _syncTransaction(transactions.first);

    notifyListeners();
    return {
      'success': true,
      'message': 'Successfully joined match in Slot #$chosenSlot!',
    };
  }

  // Helper to generate 6-char random alphanumeric team code
  String _generateTeamCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(6, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  // --- SQUAD / DUO: CREATE A NEW TEAM & GET 6-CHAR TEAM CODE ---
  Map<String, dynamic> createSquadTeam({
    required String matchId,
    required String teamName,
    required String inGameName,
    required String inGameUid,
  }) {
    final matchIndex = matches.indexWhere((m) => m.id == matchId);
    if (matchIndex == -1) return {'success': false, 'message': 'Match not found'};
    final match = matches[matchIndex];

    if (match.participants.any((p) => p.uid == user.uid)) {
      return {'success': false, 'message': 'You have already joined this match!'};
    }

    user.inGameName = inGameName;
    user.inGameUid = inGameUid;

    double balBefore = 0.0;
    double balAfter = 0.0;
    String walletUsed = '';

    // DEDUCT ENTRY FEE (Free vs Paid Smart Priority)
    if (match.matchType == MatchType.free) {
      if (user.wallet.adCoins < match.entryFee) {
        return {
          'success': false,
          'message': 'Insufficient Ad Coins! You need ${match.entryFee.toInt()} 🟡 Ad Coins.'
        };
      }
      balBefore = user.wallet.adCoins.toDouble();
      user.wallet.adCoins -= match.entryFee.toInt();
      balAfter = user.wallet.adCoins.toDouble();
      walletUsed = 'AD_COINS';
    } else {
      final fee = match.entryFee;
      if (user.wallet.totalPlayableCash < fee) {
        return {
          'success': false,
          'message': 'Insufficient Cash! Entry fee is ₹${fee.toInt()}. Add cash via Razorpay.'
        };
      }

      double remaining = fee;
      balBefore = user.wallet.totalPlayableCash;

      if (user.wallet.bonusCash > 0) {
        final deduct = user.wallet.bonusCash >= remaining ? remaining : user.wallet.bonusCash;
        user.wallet.bonusCash -= deduct;
        remaining -= deduct;
      }

      if (remaining > 0 && user.wallet.depositCash > 0) {
        final deduct = user.wallet.depositCash >= remaining ? remaining : user.wallet.depositCash;
        user.wallet.depositCash -= deduct;
        remaining -= deduct;
      }

      if (remaining > 0 && user.wallet.winningCash > 0) {
        final deduct = user.wallet.winningCash >= remaining ? remaining : user.wallet.winningCash;
        user.wallet.winningCash -= deduct;
        remaining -= deduct;
      }

      balAfter = user.wallet.totalPlayableCash;
      walletUsed = 'REAL_CASH';
    }

    // Find next available slot
    int assignedSlot = 1;
    for (int s = 1; s <= match.maxSlots; s++) {
      if (!match.isSlotTaken(s)) {
        assignedSlot = s;
        break;
      }
    }

    final teamCode = _generateTeamCode();
    final teamMaxSize = match.teamSize; // 2 for Duo, 4 for Squad

    final teamMember = TeamMember(
      uid: user.uid,
      inGameName: user.inGameName ?? inGameName,
      inGameUid: user.inGameUid ?? inGameUid,
      isCaptain: true,
      slotNumber: assignedSlot,
      joinedAt: DateTime.now(),
      amountPaid: match.entryFee,
    );

    final newTeam = RegisteredTeam(
      teamId: 'team_${DateTime.now().millisecondsSinceEpoch}',
      matchId: match.id,
      teamCode: teamCode,
      captainUid: user.uid,
      captainName: user.inGameName ?? inGameName,
      maxSize: teamMaxSize,
      teamName: teamName.isNotEmpty ? teamName : 'Team $teamCode',
      members: [teamMember],
      createdAt: DateTime.now(),
    );

    match.registeredTeams.add(newTeam);

    final participant = MatchParticipant(
      uid: user.uid,
      inGameName: user.inGameName ?? inGameName,
      inGameUid: user.inGameUid ?? inGameUid,
      slotNumber: assignedSlot,
      paidWith: walletUsed,
      amountPaid: match.entryFee,
      joinedAt: DateTime.now(),
      teamName: newTeam.teamName,
    );

    match.participants.add(participant);
    match.filledSlots += 1;
    user.stats.matchesPlayed += 1;

    transactions.insert(
      0,
      TransactionModel(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        userName: user.displayName,
        type: TransactionType.matchEntryFee,
        walletAffected: match.matchType == MatchType.free ? WalletType.adCoins : WalletType.depositCash,
        amount: -match.entryFee,
        currency: match.matchType == MatchType.free ? 'AD_COINS' : 'INR',
        balanceBefore: balBefore,
        balanceAfter: balAfter,
        status: 'SUCCESS',
        description: 'Created Team "${newTeam.teamName}" [Code: $teamCode] for ${match.title}',
        createdAt: DateTime.now(),
      ),
    );

    _syncUser();
    _checkAndTriggerMatchAutoStart(match);
    _syncMatch(match);
    _syncTransaction(transactions.first);

    notifyListeners();
    return {
      'success': true,
      'team': newTeam,
      'teamCode': teamCode,
      'message': 'Team created successfully! Share code $teamCode with your squad.',
    };
  }

  // --- SQUAD / DUO: JOIN AN EXISTING TEAM WITH 6-CHAR CODE ---
  Map<String, dynamic> joinSquadTeamWithCode({
    required String matchId,
    required String teamCode,
    required String inGameName,
    required String inGameUid,
  }) {
    final matchIndex = matches.indexWhere((m) => m.id == matchId);
    if (matchIndex == -1) return {'success': false, 'message': 'Match not found'};
    final match = matches[matchIndex];

    if (match.participants.any((p) => p.uid == user.uid)) {
      return {'success': false, 'message': 'You have already joined this match!'};
    }

    final team = match.getTeamByCode(teamCode);
    if (team == null) {
      return {'success': false, 'message': 'Team Code "$teamCode" not found! Please check and try again.'};
    }

    if (team.isComplete) {
      return {'success': false, 'message': 'This team is already full (${team.maxSize}/${team.maxSize} players)!'};
    }

    user.inGameName = inGameName;
    user.inGameUid = inGameUid;

    double balBefore = 0.0;
    double balAfter = 0.0;
    String walletUsed = '';

    // DEDUCT ENTRY FEE (Free vs Paid Smart Priority)
    if (match.matchType == MatchType.free) {
      if (user.wallet.adCoins < match.entryFee) {
        return {
          'success': false,
          'message': 'Insufficient Ad Coins! You need ${match.entryFee.toInt()} 🟡 Ad Coins.'
        };
      }
      balBefore = user.wallet.adCoins.toDouble();
      user.wallet.adCoins -= match.entryFee.toInt();
      balAfter = user.wallet.adCoins.toDouble();
      walletUsed = 'AD_COINS';
    } else {
      final fee = match.entryFee;
      if (user.wallet.totalPlayableCash < fee) {
        return {
          'success': false,
          'message': 'Insufficient Cash! Entry fee is ₹${fee.toInt()}. Add cash via Razorpay.'
        };
      }

      double remaining = fee;
      balBefore = user.wallet.totalPlayableCash;

      if (user.wallet.bonusCash > 0) {
        final deduct = user.wallet.bonusCash >= remaining ? remaining : user.wallet.bonusCash;
        user.wallet.bonusCash -= deduct;
        remaining -= deduct;
      }

      if (remaining > 0 && user.wallet.depositCash > 0) {
        final deduct = user.wallet.depositCash >= remaining ? remaining : user.wallet.depositCash;
        user.wallet.depositCash -= deduct;
        remaining -= deduct;
      }

      if (remaining > 0 && user.wallet.winningCash > 0) {
        final deduct = user.wallet.winningCash >= remaining ? remaining : user.wallet.winningCash;
        user.wallet.winningCash -= deduct;
        remaining -= deduct;
      }

      balAfter = user.wallet.totalPlayableCash;
      walletUsed = 'REAL_CASH';
    }

    // Find next available slot
    int assignedSlot = 1;
    for (int s = 1; s <= match.maxSlots; s++) {
      if (!match.isSlotTaken(s)) {
        assignedSlot = s;
        break;
      }
    }

    final teamMember = TeamMember(
      uid: user.uid,
      inGameName: user.inGameName ?? inGameName,
      inGameUid: user.inGameUid ?? inGameUid,
      isCaptain: false,
      slotNumber: assignedSlot,
      joinedAt: DateTime.now(),
      amountPaid: match.entryFee,
    );

    team.members.add(teamMember);

    final participant = MatchParticipant(
      uid: user.uid,
      inGameName: user.inGameName ?? inGameName,
      inGameUid: user.inGameUid ?? inGameUid,
      slotNumber: assignedSlot,
      paidWith: walletUsed,
      amountPaid: match.entryFee,
      joinedAt: DateTime.now(),
      teamName: team.teamName,
    );

    match.participants.add(participant);
    match.filledSlots += 1;
    user.stats.matchesPlayed += 1;

    transactions.insert(
      0,
      TransactionModel(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        userName: user.displayName,
        type: TransactionType.matchEntryFee,
        walletAffected: match.matchType == MatchType.free ? WalletType.adCoins : WalletType.depositCash,
        amount: -match.entryFee,
        currency: match.matchType == MatchType.free ? 'AD_COINS' : 'INR',
        balanceBefore: balBefore,
        balanceAfter: balAfter,
        status: 'SUCCESS',
        description: 'Joined Team "${team.teamName}" [Code: ${team.teamCode}] for ${match.title}',
        createdAt: DateTime.now(),
      ),
    );

    _syncUser();
    _checkAndTriggerMatchAutoStart(match);
    _syncMatch(match);
    _syncTransaction(transactions.first);

    notifyListeners();
    return {
      'success': true,
      'team': team,
      'message': 'Joined team ${team.teamName} (${team.members.length}/${team.maxSize} players)!',
    };
  }

  // --- REDEEM REWARD COINS FOR VOUCHERS / DIAMONDS WITH WHATSAPP NUMBER ---
  Map<String, dynamic> redeemStoreItem({
    required StoreItem item,
    required String whatsappNumber,
    required String inGameUid,
  }) {
    if (user.wallet.rewardCoins < item.rewardCoinsPrice) {
      return {
        'success': false,
        'message': 'Insufficient Winning Coins! You have ${user.wallet.rewardCoins} 🎟️ coins, need ${item.rewardCoinsPrice} coins.'
      };
    }

    if (whatsappNumber.trim().length < 8) {
      return {
        'success': false,
        'message': 'Please enter a valid WhatsApp Number so Admin can deliver your code.'
      };
    }

    final balBefore = user.wallet.rewardCoins.toDouble();
    user.wallet.rewardCoins -= item.rewardCoinsPrice;
    final balAfter = user.wallet.rewardCoins.toDouble();

    final claimId = 'vclaim_${DateTime.now().millisecondsSinceEpoch}';
    final claim = VoucherClaim(
      id: claimId,
      userId: user.uid,
      userName: user.displayName,
      inGameUid: inGameUid.isNotEmpty ? inGameUid : (user.inGameUid ?? ''),
      whatsappNumber: whatsappNumber.trim(),
      itemTitle: item.title,
      rewardCoinsSpent: item.rewardCoinsPrice,
      status: VoucherClaimStatus.pending,
      requestedAt: DateTime.now(),
    );

    voucherClaims.insert(0, claim);

    transactions.insert(
      0,
      TransactionModel(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        userName: user.displayName,
        type: TransactionType.voucherRedeem,
        walletAffected: WalletType.rewardCoins,
        amount: -item.rewardCoinsPrice.toDouble(),
        currency: 'REWARD_COINS',
        balanceBefore: balBefore,
        balanceAfter: balAfter,
        status: 'SUCCESS',
        description: 'Redeemed ${item.title} (WhatsApp: $whatsappNumber)',
        createdAt: DateTime.now(),
      ),
    );

    _syncUser();
    _syncTransaction(transactions.first);
    _syncVoucherClaim(claim);

    notifyListeners();
    return {
      'success': true,
      'message': '2 hours ke andar Admin aapse WhatsApp par connect karenge aur aapka code/diamonds deliver karenge.',
    };
  }

  // --- ADMIN: ADD NEW ITEM TO REWARDS STORE ---
  void adminAddStoreItem({
    required String title,
    required String description,
    required String imageUrl,
    required int coinPrice,
    required String rewardValue,
  }) {
    final newItem = StoreItem(
      id: 'store_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=300&auto=format&fit=crop&q=80',
      iconEmoji: title.toLowerCase().contains('diamond') ? '💎' : '🎟️',
      rewardCoinsPrice: coinPrice,
      rewardValue: rewardValue,
    );

    storeItems.insert(0, newItem);
    notifyListeners();
  }

  // --- UNLOCK ROOM ID & PASSWORD VIA VIDEO AD GATE ---
  void unlockRoomCredentialsWithAd(String matchId) {
    final match = matches.firstWhere((m) => m.id == matchId);
    match.hasUserWatchedAdToUnlockRoom = true;
    notifyListeners();
  }

  // --- WATCH REWARDED AD (3 ADS = 1 COIN) ---
  Map<String, dynamic> watchRewardedAd() {
    user.adTracker.checkAndResetDaily();

    if (user.adTracker.dailyLimitRemaining <= 0) {
      return {
        'success': false,
        'coinAwarded': false,
        'message': 'Daily ad limit reached (30/30). Come back tomorrow!'
      };
    }

    user.adTracker.adsWatchedToday += 1;
    user.adTracker.dailyLimitRemaining -= 1;
    user.adTracker.adsWatchedSinceLastCoin += 1;
    user.adTracker.lastAdTimestamp = DateTime.now();
    globalTotalAdsWatched += 1;

    // Asynchronously update global ad stats in Firestore
    FirestoreRestService.setDocument(
      'skillwinner_stats',
      'ad_stats',
      {
        'totalAdsWatched': globalTotalAdsWatched,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
    );
    _syncUser();

    bool coinAwarded = false;
    String message = 'Ad completed (${user.adTracker.adsWatchedSinceLastCoin}/3). Watch ${3 - user.adTracker.adsWatchedSinceLastCoin} more for 1 🟡 Ad Coin!';

    if (user.adTracker.adsWatchedSinceLastCoin >= 3) {
      user.adTracker.adsWatchedSinceLastCoin = 0;
      final balBefore = user.wallet.adCoins.toDouble();
      user.wallet.adCoins += 1;
      user.stats.totalCoinsEarned += 1;
      coinAwarded = true;
      message = '🎉 Milestone Reached! You earned +1 🟡 Ad Coin!';

      final newTxn = TransactionModel(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        userName: user.displayName,
        type: TransactionType.adReward,
        walletAffected: WalletType.adCoins,
        amount: 1,
        currency: 'AD_COINS',
        balanceBefore: balBefore,
        balanceAfter: user.wallet.adCoins.toDouble(),
        status: 'SUCCESS',
        description: 'Earned 1 Ad Coin by watching 3 Rewarded Ads',
        createdAt: DateTime.now(),
      );

      transactions.insert(0, newTxn);
      allGlobalTransactions.insert(0, newTxn);

      _syncUser();
      _syncTransaction(newTxn);
    }

    notifyListeners();
    return {
      'success': true,
      'coinAwarded': coinAwarded,
      'message': message,
    };
  }

  // --- DEPOSIT CASH & AUTO-CREDIT WALLET (REAL CASH TO DEPOSIT, 10% BONUS TO BONUS CASH) ---
  void depositCash(double amount, String paymentId, {String description = ''}) {
    final extraBonus = (amount * 0.10);
    final depBefore = user.wallet.depositCash;
    final bonusBefore = user.wallet.bonusCash;

    // Real deposited money goes strictly to Deposit Cash (Match Entry Only)
    user.wallet.depositCash += amount;
    // 10% Extra Cashback goes strictly to Bonus Cash (Match Entry Only)
    user.wallet.bonusCash += extraBonus;

    // 1. Record Deposit Transaction
    final depositTxn = TransactionModel(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      userName: user.displayName,
      type: TransactionType.deposit,
      walletAffected: WalletType.depositCash,
      amount: amount,
      currency: 'INR',
      balanceBefore: depBefore,
      balanceAfter: user.wallet.depositCash,
      status: 'SUCCESS',
      description: description.isNotEmpty
          ? description
          : 'Deposit: Added ₹${amount.toInt()} Real Cash ($paymentId)',
      createdAt: DateTime.now(),
    );
    transactions.insert(0, depositTxn);
    _syncTransaction(depositTxn);

    // 2. Record 10% Extra Bonus Cashback Transaction
    if (extraBonus > 0) {
      final bonusTxn = TransactionModel(
        id: 'txn_bonus_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        userName: user.displayName,
        type: TransactionType.bonusCashback,
        walletAffected: WalletType.bonusCash,
        amount: extraBonus,
        currency: 'INR',
        balanceBefore: bonusBefore,
        balanceAfter: user.wallet.bonusCash,
        status: 'SUCCESS',
        description: '🎁 10% Extra Deposit Cashback (+₹${extraBonus.toStringAsFixed(1)} Bonus Cash)',
        createdAt: DateTime.now(),
      );
      transactions.insert(0, bonusTxn);
      _syncTransaction(bonusTxn);
    }

    _syncUser();
    notifyListeners();
  }

  // --- WITHDRAWAL SYSTEM (UPI) ---
  Map<String, dynamic> requestWithdrawal(double amount, String upiId) {
    if (amount < 50) {
      return {'success': false, 'message': 'Minimum withdrawal limit is ₹50.'};
    }
    if (user.wallet.winningCash < amount) {
      return {'success': false, 'message': 'Insufficient Winning Cash (Available: ₹${user.wallet.winningCash.toInt()}). (Note: Free match Reward Coins are redeemed in Store).'};
    }
    if (!upiId.contains('@')) {
      return {'success': false, 'message': 'Please enter a valid UPI ID (e.g. 9876543210@ybl or user@oksbi).'};
    }

    final balBefore = user.wallet.winningCash;
    user.wallet.winningCash -= amount;

    final reqId = 'wreq_${DateTime.now().millisecondsSinceEpoch}';
    final newRequest = WithdrawalModel(
      id: reqId,
      userId: user.uid,
      userName: '${user.displayName} (${user.inGameName})',
      userPhone: user.phoneNumber,
      amount: amount,
      upiId: upiId,
      status: WithdrawalStatus.pending,
      requestedAt: DateTime.now(),
    );

    withdrawals.insert(0, newRequest);

    final withTxn = TransactionModel(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      userName: user.displayName,
      type: TransactionType.withdrawalRequest,
      walletAffected: WalletType.winningCash,
      amount: -amount,
      currency: 'INR',
      balanceBefore: balBefore,
      balanceAfter: user.wallet.winningCash,
      status: 'PENDING',
      description: 'Withdrawal Request to UPI $upiId',
      createdAt: DateTime.now(),
    );
    transactions.insert(0, withTxn);

    _syncUser();
    _syncWithdrawal(newRequest);
    _syncTransaction(withTxn);

    notifyListeners();
    return {
      'success': true,
      'message': 'Withdrawal request for ₹${amount.toInt()} submitted! Status: PENDING',
    };
  }

  // --- ADMIN: PUBLISH ROOM ID & PASSWORD ---
  void adminPublishRoomCredentials(String matchId, String roomId, String roomPass) {
    final match = matches.firstWhere((m) => m.id == matchId);
    match.credentials.roomId = roomId;
    match.credentials.roomPassword = roomPass;
    match.credentials.isRevealed = true;
    if (match.status == MatchStatus.upcoming || match.status == MatchStatus.roomFilling) {
      match.status = MatchStatus.ongoing;
    }
    _syncMatch(match);
    _notificationService.sendMatchAlert(
      matchId: matchId,
      title: '🔑 ROOM ID & PASSWORD LIVE! (${match.title})',
      body: 'Room ID: $roomId | Password: $roomPass. Join custom room immediately!',
    );
    notifyListeners();
  }

  // --- ADMIN: PUSH NOTIFICATION BROADCAST & TARGETED DISPATCH ---
  Future<bool> adminSendBroadcastNotification({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    return await _notificationService.sendBroadcastAnnouncement(
      title: title,
      body: body,
      imageUrl: imageUrl,
    );
  }

  Future<bool> adminSendMatchNotification({
    required String matchId,
    required String title,
    required String body,
  }) async {
    return await _notificationService.sendMatchAlert(
      matchId: matchId,
      title: title,
      body: body,
    );
  }

  Future<bool> adminSendPersonalNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    return await _notificationService.sendPersonalNotification(
      userId: userId,
      title: title,
      body: body,
    );
  }

  // Helper to credit prize to other players' Firestore user wallets and create transactions
  Future<void> _creditWinningToParticipant({
    required String uid,
    required String inGameName,
    required double amount,
    required bool isPaid,
    required String matchTitle,
    required int? rank,
    required int kills,
  }) async {
    if (uid.isEmpty || uid == user.uid) return;
    try {
      final userDoc = await FirestoreRestService.getDocument(FirebaseConfig.usersCollection, uid);
      if (userDoc != null && userDoc.isNotEmpty) {
        final targetUser = UserModel.fromJson(userDoc);
        final double balBefore = isPaid ? targetUser.wallet.winningCash : targetUser.wallet.rewardCoins.toDouble();
        if (isPaid) {
          targetUser.wallet.winningCash += amount;
          targetUser.stats.totalWinningsCash += amount;
        } else {
          targetUser.wallet.rewardCoins += amount.toInt();
          targetUser.stats.totalRewardCoinsWon += amount.toInt();
        }
        targetUser.stats.totalKills += kills;
        if (rank == 1) targetUser.stats.matchesWon += 1;

        await FirestoreRestService.setDocument(FirebaseConfig.usersCollection, uid, targetUser.toJson());

        final winTxn = TransactionModel(
          id: 'txn_${DateTime.now().millisecondsSinceEpoch}_$uid',
          userId: uid,
          userName: targetUser.displayName.isNotEmpty ? targetUser.displayName : inGameName,
          type: isPaid ? TransactionType.matchWinningCash : TransactionType.matchWinningRewardCoins,
          walletAffected: isPaid ? WalletType.winningCash : WalletType.rewardCoins,
          amount: amount,
          currency: isPaid ? 'INR' : 'REWARD_COINS',
          balanceBefore: balBefore,
          balanceAfter: isPaid ? targetUser.wallet.winningCash : targetUser.wallet.rewardCoins.toDouble(),
          status: 'SUCCESS',
          description: '🏆 Rank #${rank ?? 1} (+${isPaid ? "₹${amount.toInt()} Winning Cash" : "${amount.toInt()} 🎟️ Coins"}) in "$matchTitle"',
          createdAt: DateTime.now(),
        );
        allGlobalTransactions.insert(0, winTxn);
        await FirestoreRestService.setDocument(FirebaseConfig.transactionsCollection, winTxn.id, winTxn.toJson());
      }
    } catch (e) {
      debugPrint('[AppState] Failed to credit winning to participant $uid: $e');
    }
  }

  // --- ADMIN: CLASH SQUAD / LONE WOLF 1-CLICK TEAM WINNER DECLARATION ---
  void adminDeclareCSTeamWinner({
    required String matchId,
    required String winningTeam, // 'Team A' or 'Team B'
  }) {
    final match = matches.firstWhere((m) => m.id == matchId);
    match.status = MatchStatus.completed;
    match.completedAt = DateTime.now();
    match.hostName = user.displayName.isNotEmpty ? user.displayName : 'Admin Host';
    final bool isPaid = match.matchType == MatchType.paid;

    // Automated Profit Sharing Calculation Engine (Stored & Sealed immutably)
    final double actualCollection = isPaid
        ? (match.participants.isNotEmpty
            ? match.participants.fold(0.0, (s, p) => s + p.amountPaid)
            : match.totalCollection)
        : 0.0;
    match.financialBreakdown = FinancialBreakdown.calculate(totalCollection: actualCollection);

    final winningParticipants = (winningTeam == 'Team A') ? match.teamAParticipants : match.teamBParticipants;
    final losingParticipants = (winningTeam == 'Team A') ? match.teamBParticipants : match.teamAParticipants;

    // Distributable Prize Pool (75% for paid, totalPool for free)
    final double totalPrizePool = isPaid ? match.distributablePrizePool : match.prizePool.totalPool;
    final int winningCount = winningParticipants.isNotEmpty ? winningParticipants.length : (match.maxSlots / 2).ceil();
    final double prizePerPlayer = totalPrizePool / (winningCount > 0 ? winningCount : 1);

    // Update winners
    for (var p in winningParticipants) {
      p.isWinner = true;
      p.rank = 1;
      p.prizeAwarded = prizePerPlayer;

      if (p.uid == user.uid || p.inGameName == user.inGameName) {
        if (isPaid) {
          final balBefore = user.wallet.winningCash;
          user.wallet.winningCash += prizePerPlayer;
          user.stats.totalWinningsCash += prizePerPlayer;
          user.stats.matchesWon += 1;

          final winTxn = TransactionModel(
            id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
            userId: user.uid,
            userName: user.displayName,
            type: TransactionType.matchWinningCash,
            walletAffected: WalletType.winningCash,
            amount: prizePerPlayer,
            currency: 'INR',
            balanceBefore: balBefore,
            balanceAfter: user.wallet.winningCash,
            status: 'SUCCESS',
            description: '🏆 $winningTeam Winner (+₹${prizePerPlayer.toInt()} Winning Cash) in "${match.title}"',
            createdAt: DateTime.now(),
          );
          transactions.insert(0, winTxn);
          _syncTransaction(winTxn);
        } else {
          final balBefore = user.wallet.rewardCoins.toDouble();
          user.wallet.rewardCoins += prizePerPlayer.toInt();
          user.stats.totalRewardCoinsWon += prizePerPlayer.toInt();
          user.stats.matchesWon += 1;

          final winTxn = TransactionModel(
            id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
            userId: user.uid,
            userName: user.displayName,
            type: TransactionType.matchWinningRewardCoins,
            walletAffected: WalletType.rewardCoins,
            amount: prizePerPlayer,
            currency: 'REWARD_COINS',
            balanceBefore: balBefore,
            balanceAfter: user.wallet.rewardCoins.toDouble(),
            status: 'SUCCESS',
            description: '🏆 $winningTeam Winner (+${prizePerPlayer.toInt()} 🎟️ Reward Coins) in "${match.title}"',
            createdAt: DateTime.now(),
          );
          transactions.insert(0, winTxn);
          _syncTransaction(winTxn);
        }
      } else if (p.uid.isNotEmpty) {
        _creditWinningToParticipant(
          uid: p.uid,
          inGameName: p.inGameName,
          amount: prizePerPlayer,
          isPaid: isPaid,
          matchTitle: match.title,
          rank: 1,
          kills: 0,
        );
      }
    }

    // Update losers
    for (var p in losingParticipants) {
      p.isWinner = false;
      p.rank = 2;
      p.prizeAwarded = 0;
    }

    _syncUser();
    _syncMatch(match);
    notifyListeners();
  }

  // --- ADMIN: FULL MAP BR DYNAMIC RESULT DECLARATION ---
  void adminDeclareBRWinners({
    required String matchId,
    required List<Map<String, dynamic>> results,
  }) {
    final match = matches.firstWhere((m) => m.id == matchId);
    match.status = MatchStatus.completed;
    match.completedAt = DateTime.now();
    match.hostName = user.displayName.isNotEmpty ? user.displayName : 'Admin Host';
    final bool isPaid = match.matchType == MatchType.paid;

    // Automated Profit Sharing Calculation Engine (Stored & Sealed immutably)
    final double actualCollection = isPaid
        ? (match.participants.isNotEmpty
            ? match.participants.fold(0.0, (s, p) => s + p.amountPaid)
            : match.totalCollection)
        : 0.0;
    match.financialBreakdown = FinancialBreakdown.calculate(totalCollection: actualCollection);

    for (var res in results) {
      final participant = res['participant'] as MatchParticipant;
      final int rank = res['rank'] ?? 1;
      final int kills = res['kills'] ?? 0;

      // Automated Auto-Distribution Engine: (Rank_Percentage_Amount / Team_Type) + (Individual Kills * Per_Kill_Reward)
      final double totalPrize = match.calculatePlayerPayout(rank: rank, kills: kills);

      participant.rank = rank;
      participant.kills = kills;
      participant.prizeAwarded = totalPrize;
      participant.isWinner = (rank == 1);

      if (participant.uid == user.uid || participant.inGameName == user.inGameName) {
        if (totalPrize > 0) {
          if (isPaid) {
            final balBefore = user.wallet.winningCash;
            user.wallet.winningCash += totalPrize;
            user.stats.totalWinningsCash += totalPrize;
            user.stats.totalKills += kills;
            if (rank == 1) user.stats.matchesWon += 1;

            final winTxn = TransactionModel(
              id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
              userId: user.uid,
              userName: user.displayName,
              type: TransactionType.matchWinningCash,
              walletAffected: WalletType.winningCash,
              amount: totalPrize,
              currency: 'INR',
              balanceBefore: balBefore,
              balanceAfter: user.wallet.winningCash,
              status: 'SUCCESS',
              description: '🏆 Rank #$rank (+₹${totalPrize.toInt()} Cash) in "${match.title}"',
              createdAt: DateTime.now(),
            );
            transactions.insert(0, winTxn);
            _syncTransaction(winTxn);
          } else {
            final balBefore = user.wallet.rewardCoins.toDouble();
            user.wallet.rewardCoins += totalPrize.toInt();
            user.stats.totalRewardCoinsWon += totalPrize.toInt();
            user.stats.totalKills += kills;
            if (rank == 1) user.stats.matchesWon += 1;

            final winTxn = TransactionModel(
              id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
              userId: user.uid,
              userName: user.displayName,
              type: TransactionType.matchWinningRewardCoins,
              walletAffected: WalletType.rewardCoins,
              amount: totalPrize,
              currency: 'REWARD_COINS',
              balanceBefore: balBefore,
              balanceAfter: user.wallet.rewardCoins.toDouble(),
              status: 'SUCCESS',
              description: '🏆 Rank #$rank (+${totalPrize.toInt()} 🎟️ Coins) in "${match.title}"',
              createdAt: DateTime.now(),
            );
            transactions.insert(0, winTxn);
            _syncTransaction(winTxn);
          }
        }
      } else if (participant.uid.isNotEmpty && totalPrize > 0) {
        _creditWinningToParticipant(
          uid: participant.uid,
          inGameName: participant.inGameName,
          amount: totalPrize,
          isPaid: isPaid,
          matchTitle: match.title,
          rank: rank,
          kills: kills,
        );
      }
    }

    _syncUser();
    _syncMatch(match);
    notifyListeners();
  }

  // --- IMMUTABLE MATCH LEDGER & FINANCIAL AGGREGATE FILTERS ---
  List<MatchModel> getCompletedMatchesByFilter(String dateFilter) {
    final now = DateTime.now();
    return matches.where((m) {
      if (m.status != MatchStatus.completed) return false;
      final completedTime = m.completedAt ?? m.matchTime;
      if (dateFilter == 'Today') {
        return completedTime.year == now.year &&
            completedTime.month == now.month &&
            completedTime.day == now.day;
      } else if (dateFilter == 'Last 7 Days') {
        return completedTime.isAfter(now.subtract(const Duration(days: 7)));
      } else if (dateFilter == 'This Month') {
        return completedTime.year == now.year && completedTime.month == now.month;
      }
      // 'All Time'
      return true;
    }).toList()
      ..sort((a, b) => (b.completedAt ?? b.matchTime).compareTo(a.completedAt ?? a.matchTime));
  }

  Map<String, double> getFinancialAggregates(String dateFilter) {
    final completedList = getCompletedMatchesByFilter(dateFilter);
    double totalNetProfit = 0;
    double founderTotal = 0;
    double hostTotal = 0;
    double investorTotal = 0;
    double totalCollection = 0;
    double grossCommission = 0;
    double gatewayFees = 0;

    for (var m in completedList) {
      final fb = m.financialBreakdown ?? FinancialBreakdown.calculate(totalCollection: m.totalCollection);
      totalNetProfit += fb.netProfit;
      founderTotal += fb.shares.founder60;
      hostTotal += fb.shares.host25;
      investorTotal += fb.shares.investor15;
      totalCollection += fb.totalEntryCollection;
      grossCommission += fb.platformCommissionGross;
      gatewayFees += fb.gatewayFeeDeduction;
    }

    return {
      'totalNetProfit': totalNetProfit,
      'founderTotal': founderTotal,
      'hostTotal': hostTotal,
      'investorTotal': investorTotal,
      'totalCollection': totalCollection,
      'grossCommission': grossCommission,
      'gatewayFees': gatewayFees,
      'completedCount': completedList.length.toDouble(),
    };
  }

  // Legacy fallback
  void adminDeclareMatchWinners({
    required String matchId,
    required List<Map<String, dynamic>> winnersData,
  }) {
    adminDeclareBRWinners(matchId: matchId, results: winnersData);
  }

  // --- ADMIN: WITHDRAWAL APPROVE & REJECT ---
  void adminApproveWithdrawal(String reqId, String utrRef, String notes) {
    final req = withdrawals.firstWhere((w) => w.id == reqId);
    req.status = WithdrawalStatus.completed;
    req.payoutTxnRef = utrRef.isEmpty ? 'UTR-${DateTime.now().millisecondsSinceEpoch}' : utrRef;
    req.adminNotes = notes.isEmpty ? 'Paid via UPI Transfer' : notes;
    req.processedAt = DateTime.now();
    _syncWithdrawal(req);
    notifyListeners();
  }

  void adminRejectWithdrawal(String reqId, String reason) {
    final req = withdrawals.firstWhere((w) => w.id == reqId);
    req.status = WithdrawalStatus.rejected;
    req.adminNotes = reason.isEmpty ? 'Invalid UPI details. Amount refunded.' : reason;
    req.processedAt = DateTime.now();

    if (req.userId == user.uid) {
      final balBefore = user.wallet.winningCash;
      user.wallet.winningCash += req.amount;

      final refTxn = TransactionModel(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        userName: user.displayName,
        type: TransactionType.withdrawalRefund,
        walletAffected: WalletType.winningCash,
        amount: req.amount,
        currency: 'INR',
        balanceBefore: balBefore,
        balanceAfter: user.wallet.winningCash,
        status: 'SUCCESS',
        description: 'Refund for rejected withdrawal: $reason',
        createdAt: DateTime.now(),
      );
      transactions.insert(0, refTxn);
      _syncTransaction(refTxn);
      _syncUser();
    }

    _syncWithdrawal(req);
    notifyListeners();
  }

  // --- ADMIN: DELIVER VOUCHER CODE VIA WHATSAPP ---
  void adminDeliverVoucher(String claimId, String code) {
    final claim = voucherClaims.firstWhere((c) => c.id == claimId);
    claim.status = VoucherClaimStatus.delivered;
    claim.redeemCode = code.isEmpty ? 'GP-${DateTime.now().millisecondsSinceEpoch.toString().substring(4)}' : code;
    claim.deliveredAt = DateTime.now();
    _syncVoucherClaim(claim);
    notifyListeners();
  }

  void adminCreateMatch(MatchModel newMatch) {
    matches.insert(0, newMatch);
    _saveLocalMatchesCache();
    _syncMatch(newMatch);
    notifyListeners();
  }

  void adminDeleteMatch(String matchId) {
    matches.removeWhere((m) => m.id == matchId);
    _saveLocalMatchesCache();
    FirestoreRestService.deleteDocument(FirebaseConfig.matchesCollection, matchId);
    notifyListeners();
  }

  // --- ADMIN FINANCIAL & ECONOMY ANALYTICS ---
  Map<String, dynamic> get adminFinancialMetrics {
    // 💵 PAID MATCHES METRICS (GLOBAL PLATFORM LEVEL)
    double totalDeposits = allGlobalTransactions
        .where((t) => (t.type == TransactionType.deposit || t.description.toLowerCase().contains('deposit')) && t.status == 'SUCCESS')
        .fold(0.0, (sum, t) => sum + t.amount);

    double totalCashEntryFees = allGlobalTransactions
        .where((t) => t.type == TransactionType.matchEntryFee && (t.walletAffected == WalletType.depositCash || t.currency == 'INR'))
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    // Also calculate from paid matches participants if no transactions recorded yet
    double matchCalculatedPaidEntry = 0;
    int paidPlayersJoined = 0;
    int paidMatchesCount = 0;
    for (var m in matches.where((m) => m.matchType == MatchType.paid)) {
      paidMatchesCount++;
      paidPlayersJoined += m.participants.length;
      matchCalculatedPaidEntry += m.participants.fold(0.0, (s, p) => s + p.amountPaid);
    }
    if (totalCashEntryFees == 0) totalCashEntryFees = matchCalculatedPaidEntry;

    double totalCashPrizesWon = allGlobalTransactions
        .where((t) => t.type == TransactionType.matchWinningCash && t.walletAffected == WalletType.winningCash)
        .fold(0.0, (sum, t) => sum + t.amount);

    final pendingList = allGlobalWithdrawals.where((w) => w.status == WithdrawalStatus.pending).toList();
    double totalPendingPayout = pendingList.fold(0.0, (sum, w) => sum + w.amount);

    double totalPaidOut = allGlobalWithdrawals
        .where((w) => w.status == WithdrawalStatus.completed)
        .fold(0.0, (sum, w) => sum + w.amount);

    double netCashMargin = totalCashEntryFees - totalCashPrizesWon;

    // 🟡 FREE MATCHES (AD-BASED) METRICS
    int freeMatchesCount = 0;
    int freePlayersJoined = 0;
    double totalAdCoinsCollected = 0;
    for (var m in matches.where((m) => m.matchType == MatchType.free)) {
      freeMatchesCount++;
      freePlayersJoined += m.participants.length;
      totalAdCoinsCollected += m.participants.fold(0.0, (s, p) => s + p.amountPaid);
    }

    double totalRewardCoinsIssued = allGlobalTransactions
        .where((t) => t.type == TransactionType.matchWinningRewardCoins)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Global Ads Watched: Real count from global ad stats & conversions
    int totalEstimatedAdsWatched = globalTotalAdsWatched > 0
        ? globalTotalAdsWatched
        : ((totalAdCoinsCollected * 3).toInt() + user.adTracker.adsWatchedToday);

    // Estimated AdMob revenue: eCPM ~ ₹60 per 1000 ads = ₹0.06 per ad
    double estimatedAdRevenue = totalEstimatedAdsWatched * 0.06;
    // Reward coins cost: 10 coins = ₹1
    double estimatedRewardCost = totalRewardCoinsIssued / 10.0;
    double netAdMargin = estimatedAdRevenue - estimatedRewardCost;

    // 🏆 WINNERS METRICS
    int totalWinnersCount = 0;
    for (var m in matches) {
      for (var p in m.participants) {
        if (p.isWinner || (p.prizeAwarded != null && p.prizeAwarded! > 0) || (p.rank != null && p.rank! <= 3)) {
          totalWinnersCount += 1;
        }
      }
    }

    int pendingVouchers = allGlobalVoucherClaims.where((v) => v.status == VoucherClaimStatus.pending).length;
    int deliveredVouchers = allGlobalVoucherClaims.where((v) => v.status == VoucherClaimStatus.delivered).length;

    return {
      // Combined / General
      'totalDeposits': totalDeposits,
      'totalPendingPayout': totalPendingPayout,
      'pendingCount': pendingList.length,
      'totalWinnersCount': totalWinnersCount,
      'totalPaidOut': totalPaidOut,
      'totalMatches': matches.length,
      'combinedNetProfit': netCashMargin + netAdMargin,

      // Paid Matches Specific
      'paidMatchesCount': paidMatchesCount,
      'paidPlayersJoined': paidPlayersJoined,
      'totalCashEntryFees': totalCashEntryFees,
      'totalCashPrizesWon': totalCashPrizesWon,
      'netCashMargin': netCashMargin,

      // Free Matches Specific
      'freeMatchesCount': freeMatchesCount,
      'freePlayersJoined': freePlayersJoined,
      'totalAdCoinsCollected': totalAdCoinsCollected.toInt(),
      'totalRewardCoinsIssued': totalRewardCoinsIssued.toInt(),
      'totalEstimatedAdsWatched': totalEstimatedAdsWatched,
      'estimatedAdRevenue': estimatedAdRevenue,
      'estimatedRewardCost': estimatedRewardCost,
      'netAdMargin': netAdMargin,

      // Store Voucher Claims
      'pendingVoucherClaims': pendingVouchers,
      'deliveredVoucherClaims': deliveredVouchers,
      'totalVouchersClaimed': allGlobalVoucherClaims.length,
    };
  }

  void toggleRole() {
    user.role = user.role == 'admin' ? 'user' : 'admin';
    notifyListeners();
  }

  void updateUserProfile({
    required String inGameName,
    required String inGameUid,
    int? inGameLevel,
  }) {
    user.inGameName = inGameName;
    user.inGameUid = inGameUid;
    if (inGameLevel != null) {
      user.inGameLevel = inGameLevel;
    }
    _syncUser();
    notifyListeners();
  }

  // --- LIVE FIRESTORE DATABASE SYNCHRONIZATION (SW-GYANMITRA-FINALL2) ---
  Future<void> refreshFromFirestore() => _syncWithFirestore();

  Future<void> _syncWithFirestore() async {
    isLiveSyncing = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString('saved_uid');
      final activeUser = await AuthService.getActiveUser();
      
      if (!isAuthenticated && activeUser != null) {
        user = activeUser;
        isAuthenticated = true;
      }

      final uidToSync = (user.uid.isNotEmpty && user.uid != 'user_guest')
          ? user.uid
          : (savedUid ?? activeUser?.uid);

      // --- ATTEMPT 1: High-Speed Cached Server Proxy Sync (Zero Quota Loss) ---
      bool backendSyncSuccess = false;
      try {
        final syncUrl = Uri.parse("https://www.swgayanbhumi.in/api/skillwinner/sync?userId=${uidToSync ?? ''}");
        final res = await http.get(syncUrl).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['success'] == true) {
            // 1. Matches
            if (data['matches'] is List) {
              final list = (data['matches'] as List).map((d) => MatchModel.fromJson(Map<String, dynamic>.from(d))).toList();
              matches = list;
              for (var m in matches) {
                _checkAndTriggerMatchAutoStart(m);
              }
              _saveLocalMatchesCache();
            }

            // 2. Dynamic Banners
            if (data['banners'] is List && (data['banners'] as List).isNotEmpty) {
              banners = (data['banners'] as List).map((d) => BannerModel.fromJson(Map<String, dynamic>.from(d))).where((b) => b.isActive).toList();
            }

            // 3. User Profile
            if (data['user'] != null && data['user'] is Map && (data['user'] as Map).isNotEmpty) {
              user = UserModel.fromJson(Map<String, dynamic>.from(data['user']));
              isAuthenticated = true;
              await AuthService.saveUser(user);
            }

            // 4. Transactions
            if (data['transactions'] is List) {
              transactions = (data['transactions'] as List).map((d) => TransactionModel.fromJson(Map<String, dynamic>.from(d))).toList();
              transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              _saveLocalTxnCache();
            }

            // 5. Config
            if (data['config'] != null) {
              if (data['config']['telegramSupportUrl'] != null) {
                telegramSupportUrl = data['config']['telegramSupportUrl'].toString();
              }
              if (data['config']['isRealCashModeEnabled'] != null) {
                isRealCashModeEnabled = data['config']['isRealCashModeEnabled'] == true ||
                    data['config']['isRealCashModeEnabled'].toString() == 'true';
              }
            }

            backendSyncSuccess = true;
          }
        }
      } catch (e) {
        debugPrint('[AppState] Backend sync proxy notice (fallback to Firestore REST): $e');
      }

      // --- ATTEMPT 2: Fallback to Direct Firestore REST if Backend Proxy was skipped/offline ---
      if (!backendSyncSuccess) {
        if (uidToSync != null && uidToSync.isNotEmpty && uidToSync != 'user_guest') {
          try {
            final userDoc = await FirestoreRestService.getDocument(FirebaseConfig.usersCollection, uidToSync);
            if (userDoc != null && userDoc.isNotEmpty) {
              user = UserModel.fromJson(userDoc);
              isAuthenticated = true;
              await AuthService.saveUser(user);
            }
          } catch (e) {
            debugPrint('[AppState] Remote user doc sync error: $e');
          }
        }

        // 2. Sync Live Matches from Firestore
        try {
          final matchDocs = await FirestoreRestService.getCollectionDocuments(FirebaseConfig.matchesCollection);
          if (matchDocs.isNotEmpty) {
            final firestoreMatches = matchDocs.map((d) => MatchModel.fromJson(d)).toList();
            matches = firestoreMatches;
            for (var m in matches) {
              _checkAndTriggerMatchAutoStart(m);
            }
            _saveLocalMatchesCache();
          }
        } catch (e) {
          debugPrint('[AppState] Sync matches error: $e');
        }

        // 3. Sync Transactions
        try {
          final txnDocs = await FirestoreRestService.getCollectionDocuments(FirebaseConfig.transactionsCollection);
          if (txnDocs.isNotEmpty) {
            allGlobalTransactions = txnDocs.map((d) => TransactionModel.fromJson(d)).toList();
            allGlobalTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            transactions = allGlobalTransactions.where((t) => t.userId == user.uid).toList();
            _saveLocalTxnCache();
          }
        } catch (e) {
          debugPrint('[AppState] Sync txns error: $e');
        }
      }

      // 4. Sync Withdrawals (Global Collection for Admin, Filtered for User)
      try {
        final withDocs = await FirestoreRestService.getCollectionDocuments('skillwinner_withdrawals');
        if (withDocs.isNotEmpty) {
          allGlobalWithdrawals = withDocs.map((d) => WithdrawalModel.fromJson(d)).toList();
          allGlobalWithdrawals.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          withdrawals = allGlobalWithdrawals.where((w) => w.userId == user.uid).toList();
        }
      } catch (e) {
        debugPrint('[AppState] Sync withdrawals error: $e');
      }

      // 5. Sync Voucher Claims (Global Collection for Admin, Filtered for User)
      try {
        final claimDocs = await FirestoreRestService.getCollectionDocuments('skillwinner_voucher_claims');
        if (claimDocs.isNotEmpty) {
          allGlobalVoucherClaims = claimDocs.map((d) => VoucherClaim.fromJson(d)).toList();
          allGlobalVoucherClaims.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          voucherClaims = allGlobalVoucherClaims.where((c) => c.userId == user.uid).toList();
        }
      } catch (e) {
        debugPrint('[AppState] Sync vouchers error: $e');
      }

      // 6. Sync Global Ad Stats (skillwinner_stats/ad_stats)
      try {
        final adDoc = await FirestoreRestService.getDocument('skillwinner_stats', 'ad_stats');
        if (adDoc != null && adDoc['totalAdsWatched'] != null) {
          globalTotalAdsWatched = (adDoc['totalAdsWatched'] as num).toInt();
        } else {
          final totalAdRewardCoins = allGlobalTransactions
              .where((t) => t.type == TransactionType.adReward || t.walletAffected == WalletType.adCoins)
              .fold(0, (sum, t) => sum + t.amount.abs().toInt());
          globalTotalAdsWatched = (totalAdRewardCoins * 3) + user.adTracker.adsWatchedToday;
        }
      } catch (e) {
        debugPrint('[AppState] Sync ad stats error: $e');
      }

      // 7. Sync Dynamic Banners from Firestore
      try {
        final bannerDocs = await FirestoreRestService.getCollectionDocuments('skillwinner_banners');
        if (bannerDocs.isNotEmpty) {
          banners = bannerDocs.map((d) => BannerModel.fromJson(d)).where((b) => b.isActive).toList();
        }
      } catch (e) {
        debugPrint('[AppState] Sync banners error: $e');
      }

      // 8. Sync Telegram Support & App Config
      try {
        final configDoc = await FirestoreRestService.getDocument('skillwinner_settings', 'app_config');
        if (configDoc != null) {
          if (configDoc['telegramSupportUrl'] != null) {
            telegramSupportUrl = configDoc['telegramSupportUrl'].toString();
          }
          if (configDoc['isRealCashModeEnabled'] != null) {
            isRealCashModeEnabled = configDoc['isRealCashModeEnabled'] == true ||
                configDoc['isRealCashModeEnabled'].toString() == 'true';
          }
        }
      } catch (e) {
        debugPrint('[AppState] Sync telegram support & config error: $e');
      }

      // 9. Sync Realtime Push Notifications
      try {
        final notifDocs = await FirestoreRestService.getCollectionDocuments('skillwinner_notifications');
        if (notifDocs.isNotEmpty) {
          final parsed = notifDocs.map((d) => AppNotification.fromJson(d)).toList();
          final Map<String, AppNotification> dedupMap = {};
          for (final item in parsed) {
            final dedupKey = '${item.title.trim()}||${item.body.trim()}';
            if (!dedupMap.containsKey(dedupKey) || item.createdAt.isAfter(dedupMap[dedupKey]!.createdAt)) {
              dedupMap[dedupKey] = item;
            }
          }
          allGlobalNotifications = dedupMap.values.toList();
          allGlobalNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final newRelevantNotifs = allGlobalNotifications.where((n) {
            if (n.targetType == 'all') return true;
            if (n.targetType == 'match' && matches.any((m) => m.id == n.targetId && m.participants.any((p) => p.uid == user.uid))) return true;
            if (n.targetType == 'user' && n.targetId == user.uid) return true;
            if (n.targetType == 'admin' && user.role == 'admin') return true;
            return false;
          }).toList();

          // Trigger native desktop notification for any new arrived notification
          for (final n in newRelevantNotifs) {
            if (!_alertedNotifIds.contains(n.id)) {
              _alertedNotifIds.add(n.id);
              if (DateTime.now().difference(n.createdAt).inMinutes.abs() <= 2) {
                if (kIsWeb) {
                  showBrowserNotification(n.title, n.body, imageUrl: n.imageUrl);
                }
              }
            }
          }

          notifications = newRelevantNotifs;
        }
      } catch (e) {
        debugPrint('[AppState] Sync notifications error: $e');
      }
    } catch (e) {
      debugPrint('[AppState] Firestore live sync error: $e');
    } finally {
      isLoadingAuth = false;
      isLiveSyncing = false;
      notifyListeners();
    }
  }

  // --- ADMIN: GOOGLE PLAY REVIEW SAFE MODE TOGGLE (REAL CASH ON/OFF) ---
  Future<void> adminSetRealCashMode(bool enabled) async {
    isRealCashModeEnabled = enabled;
    notifyListeners();

    // 1. Sync to high-speed backend proxy
    try {
      http.post(
        Uri.parse("https://www.swgayanbhumi.in/api/skillwinner/sync"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'set_real_cash_mode',
          'data': {'isRealCashModeEnabled': enabled},
        }),
      ).timeout(const Duration(seconds: 4)).catchError((_) => http.Response('', 500));
    } catch (_) {}

    // 2. Sync directly to Firestore
    await FirestoreRestService.setDocument('skillwinner_settings', 'app_config', {
      'isRealCashModeEnabled': enabled,
      'telegramSupportUrl': telegramSupportUrl,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // --- ADMIN: TELEGRAM CUSTOMER SUPPORT URL CONFIGURATION ---
  void adminUpdateTelegramUrl(String url) {
    telegramSupportUrl = url.trim();
    FirestoreRestService.setDocument('skillwinner_settings', 'app_config', {
      'telegramSupportUrl': telegramSupportUrl,
      'isRealCashModeEnabled': isRealCashModeEnabled,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  // --- ADMIN: DYNAMIC PROMO BANNERS ---
  void adminAddBanner(BannerModel newBanner) {
    banners.insert(0, newBanner);
    FirestoreRestService.setDocument('skillwinner_banners', newBanner.id, newBanner.toJson());
    notifyListeners();
  }

  void adminDeleteBanner(String bannerId) {
    banners.removeWhere((b) => b.id == bannerId);
    FirestoreRestService.deleteDocument('skillwinner_banners', bannerId);
    notifyListeners();
  }

  Future<void> _syncUser() async {
    await AuthService.saveUser(user);
    await FirestoreRestService.setDocument(FirebaseConfig.usersCollection, user.uid, user.toJson());
  }

  Future<void> _syncMatch(MatchModel m) async {
    await FirestoreRestService.setDocument(FirebaseConfig.matchesCollection, m.id, m.toJson());
  }

  Future<void> _syncTransaction(TransactionModel txn) async {
    await FirestoreRestService.setDocument(FirebaseConfig.transactionsCollection, txn.id, txn.toJson());
  }

  Future<void> _syncWithdrawal(WithdrawalModel w) async {
    await FirestoreRestService.setDocument('skillwinner_withdrawals', w.id, w.toJson());
  }

  Future<void> _syncVoucherClaim(VoucherClaim claim) async {
    await FirestoreRestService.setDocument('skillwinner_voucher_claims', claim.id, claim.toJson());
  }
}
