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
import '../models/leaderboard_model.dart';
import '../models/referral_record.dart';
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
  List<WeeklyDistributionRecord> weeklyDistributions = [];
  List<ReferralRecord> referralRecords = [];
  List<ReferralRecord> allGlobalReferralRecords = [];
  List<BannerModel> banners = [];
  static const String vpsBaseUrl = 'https://vps.swgayanbhumi.in';
  static const String vpsApiUrl = '$vpsBaseUrl/api';
  String brBannerUrl = 'https://i.ibb.co/PvV4vz0X/brhomescreen.png';
  String csBannerUrl = 'https://i.ibb.co/S4qX9RW5/cshomescreen.png';
  String lwBannerUrl = 'https://i.ibb.co/9ktcjYSX/lonewolfhomescreen.png';
  String get brCategoryBanner => brBannerUrl.isNotEmpty ? brBannerUrl : 'https://i.ibb.co/PvV4vz0X/brhomescreen.png';
  String get csCategoryBanner => csBannerUrl.isNotEmpty ? csBannerUrl : 'https://i.ibb.co/S4qX9RW5/cshomescreen.png';
  String get lwCategoryBanner => lwBannerUrl.isNotEmpty ? lwBannerUrl : 'https://i.ibb.co/9ktcjYSX/lonewolfhomescreen.png';
  
  List<TournamentModeItem> tournamentModes = [
    TournamentModeItem(key: 'BR', title: 'Full Map (BR)', bannerUrl: 'https://i.ibb.co/PvV4vz0X/brhomescreen.png', defaultSlots: 48, mode: 'br', enabled: true),
    TournamentModeItem(key: 'CS', title: 'Clash Squad (CS)', bannerUrl: 'https://i.ibb.co/S4qX9RW5/cshomescreen.png', defaultSlots: 8, mode: 'cs', enabled: true),
    TournamentModeItem(key: 'LONE_WOLF', title: 'Lone Wolf', bannerUrl: 'https://i.ibb.co/9ktcjYSX/lonewolfhomescreen.png', defaultSlots: 2, mode: 'loneWolf', enabled: true),
  ];
  List<TournamentModeItem> get activeTournamentModes => tournamentModes.where((m) => m.enabled).toList();
  
  String telegramSupportUrl = 'http://t.me/booyahrewardofficial';
  bool isRealCashModeEnabled = false; // Default: Play Store Review Safe Mode (OFF)
  double coinToRupeeRate = 0.10; // Default: 1000 Coins = ₹100 (1 Coin = ₹0.10)
  int minWithdrawalCoins = 1000; // Minimum 1000 Winning Coins for withdrawal

  bool isLiveSyncing = false;
  bool isAuthenticated = false;
  bool isLoadingAuth = true;
  int globalTotalAdsWatched = 0;

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

      final cachedSafeMode = WebStorageHelper.getItem('booyah_safe_mode_cash_enabled') ?? prefs.getString('booyah_safe_mode_cash_enabled');
      if (cachedSafeMode != null) {
        isRealCashModeEnabled = cachedSafeMode == 'true';
        notifyListeners();
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

    matches = _getDefaultMatches();
    banners = _getDefaultBanners();
    transactions = [];
    withdrawals = [];
    voucherClaims = [];
  }

  List<BannerModel> _getDefaultBanners() => [
    BannerModel(
      id: 'banner_welcome_01',
      title: '🔥 Official Telegram Support & Daily Updates',
      imageUrl: 'https://i.ibb.co/W43nNfnY/Chat-GPT-Image-Oct-7-2026-10-03-53-AM-1.png',
      clickUrl: 'http://t.me/booyahrewardofficial',
      isActive: true,
      createdAt: DateTime.now(),
    ),
  ];

  List<MatchModel> _getDefaultMatches() => [
    // 1. FREE FIRE BATTLE ROYALE (Watch Ads to Enter)
    MatchModel(
      id: 'FREE-BR-01',
      title: '⚡ Free Fire BR Solo Championship',
      bannerImage: 'https://i.ibb.co/PvV4vz0X/brhomescreen.png',
      gameType: GameType.freeFire,
      matchType: MatchType.free,
      mode: MatchMode.br,
      teamType: TeamType.solo,
      matchFormat: MatchFormat.solo,
      map: MapType.bermuda,
      entryFeeType: EntryFeeType.adCoins,
      entryFee: 1, // 1 Ad to Join
      prizePool: PrizePool(totalPool: 500, firstPlace: 250, secondPlace: 150, thirdPlace: 100, perKill: 20),
      maxSlots: 48,
      filledSlots: 0,
      status: MatchStatus.upcoming,
      matchTime: DateTime.now().add(const Duration(minutes: 45)),
      credentials: MatchCredentials(roomId: '', roomPassword: ''),
      participants: [],
    ),
    MatchModel(
      id: 'FREE-BR-02',
      title: '🔥 Free Fire BR Squad Mega Showdown',
      bannerImage: 'https://i.ibb.co/PvV4vz0X/brhomescreen.png',
      gameType: GameType.freeFire,
      matchType: MatchType.free,
      mode: MatchMode.br,
      teamType: TeamType.squad,
      matchFormat: MatchFormat.squad,
      map: MapType.purgatory,
      entryFeeType: EntryFeeType.adCoins,
      entryFee: 2, // 2 Ads to Join
      prizePool: PrizePool(totalPool: 1000, firstPlace: 500, secondPlace: 300, thirdPlace: 200, perKill: 30),
      maxSlots: 48,
      filledSlots: 0,
      status: MatchStatus.upcoming,
      matchTime: DateTime.now().add(const Duration(hours: 2)),
      credentials: MatchCredentials(roomId: '', roomPassword: ''),
      participants: [],
    ),

    // 2. CLASH SQUAD (4v4)
    MatchModel(
      id: 'FREE-CS-01',
      title: '🎯 Free Fire CS 4v4 Squad Clash',
      bannerImage: 'https://i.ibb.co/S4qX9RW5/cshomescreen.png',
      gameType: GameType.freeFire,
      matchType: MatchType.free,
      mode: MatchMode.cs,
      teamType: TeamType.squad,
      matchFormat: MatchFormat.cs4v4,
      map: MapType.bermuda,
      entryFeeType: EntryFeeType.adCoins,
      entryFee: 1, // 1 Ad to Join
      prizePool: PrizePool(totalPool: 400, firstPlace: 400, perKill: 0),
      maxSlots: 8,
      filledSlots: 0,
      status: MatchStatus.upcoming,
      matchTime: DateTime.now().add(const Duration(minutes: 60)),
      credentials: MatchCredentials(roomId: '', roomPassword: ''),
      participants: [],
    ),

    // 3. LONE WOLF (1v1)
    MatchModel(
      id: 'FREE-LW-01',
      title: '🐺 Lone Wolf 1v1 Battle Master',
      bannerImage: 'https://i.ibb.co/9ktcjYSX/lonewolfhomescreen.png',
      gameType: GameType.freeFire,
      matchType: MatchType.free,
      mode: MatchMode.loneWolf,
      teamType: TeamType.solo,
      matchFormat: MatchFormat.loneWolf1v1,
      map: MapType.bermuda,
      entryFeeType: EntryFeeType.adCoins,
      entryFee: 1, // 1 Ad to Join
      prizePool: PrizePool(totalPool: 150, firstPlace: 150, perKill: 0),
      maxSlots: 2,
      filledSlots: 0,
      status: MatchStatus.upcoming,
      matchTime: DateTime.now().add(const Duration(minutes: 30)),
      credentials: MatchCredentials(roomId: '', roomPassword: ''),
      participants: [],
    ),
  ];

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
      final filter = selectedFilter.toUpperCase();
      if (filter == 'FREE' && m.matchType != MatchType.free) return false;
      if (filter == 'PAID' && m.matchType != MatchType.paid) return false;

      // 2. Mode Filter (BR, CS, Lone Wolf)
      final modeFilter = selectedMode.toUpperCase();
      if (modeFilter == 'BR' && m.mode != MatchMode.br) return false;
      if (modeFilter == 'CS' && m.mode != MatchMode.cs) return false;
      if ((modeFilter == 'LONE_WOLF' || modeFilter == 'LONEWOLF') && m.mode != MatchMode.loneWolf) return false;

      // 3. Team Type Filter (Solo, Duo, Squad)
      final teamFilter = selectedTeamType.toUpperCase();
      if (teamFilter == 'SOLO' && m.teamType != TeamType.solo) return false;
      if (teamFilter == 'DUO' && m.teamType != TeamType.duo) return false;
      if (teamFilter == 'SQUAD' && m.teamType != TeamType.squad) return false;

      // 4. Status Filter (Upcoming, Ongoing, Completed/Resulted)
      final statusFilter = selectedStatus.toUpperCase();
      if (statusFilter == 'UPCOMING' && m.status != MatchStatus.upcoming && m.status != MatchStatus.roomFilling) return false;
      if (statusFilter == 'ONGOING' && m.status != MatchStatus.ongoing) return false;
      if (statusFilter == 'COMPLETED' && m.status != MatchStatus.completed) return false;
      // In main 'ALL' lobby, only show active joinable matches (Upcoming, RoomFilling & Live), completed matches are in Resulted tab
      if (statusFilter == 'ALL' && m.status == MatchStatus.completed) return false;

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

    // DEDUCT ENTRY FEE IN 🟡 AD COINS
    final requiredAdCoins = match.entryFee.toInt();
    if (requiredAdCoins > 0) {
      if (user.wallet.adCoins < requiredAdCoins) {
        return {
          'success': false,
          'message': 'Insufficient Ad Coins! You need $requiredAdCoins 🟡 Ad Coins to join.'
        };
      }
      balBefore = user.wallet.adCoins.toDouble();
      user.wallet.adCoins -= requiredAdCoins;
      balAfter = user.wallet.adCoins.toDouble();
      walletUsed = 'AD_COINS';
    } else {
      balBefore = user.wallet.adCoins.toDouble();
      balAfter = balBefore;
      walletUsed = 'FREE';
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

    if (requiredAdCoins > 0) {
      final newTxn = TransactionModel(
        id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        userName: user.displayName,
        type: TransactionType.matchEntryFee,
        walletAffected: WalletType.adCoins,
        amount: -match.entryFee,
        currency: 'AD_COINS',
        balanceBefore: balBefore,
        balanceAfter: balAfter,
        status: 'SUCCESS',
        description: 'Joined ${match.title} (Slot #$chosenSlot)',
        createdAt: DateTime.now(),
      );
      transactions.insert(0, newTxn);
      _syncTransaction(newTxn);
    }

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

    // DEDUCT ENTRY FEE IN 🟡 AD COINS
    final requiredAdCoins = match.entryFee.toInt();
    if (requiredAdCoins > 0) {
      if (user.wallet.adCoins < requiredAdCoins) {
        return {
          'success': false,
          'message': 'Insufficient Ad Coins! You need $requiredAdCoins 🟡 Ad Coins.'
        };
      }
      balBefore = user.wallet.adCoins.toDouble();
      user.wallet.adCoins -= requiredAdCoins;
      balAfter = user.wallet.adCoins.toDouble();
      walletUsed = 'AD_COINS';
    } else {
      balBefore = user.wallet.adCoins.toDouble();
      balAfter = balBefore;
      walletUsed = 'FREE';
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

    // DEDUCT ENTRY FEE IN 🟡 AD COINS
    final requiredAdCoins = match.entryFee.toInt();
    if (requiredAdCoins > 0) {
      if (user.wallet.adCoins < requiredAdCoins) {
        return {
          'success': false,
          'message': 'Insufficient Ad Coins! You need $requiredAdCoins 🟡 Ad Coins.'
        };
      }
      balBefore = user.wallet.adCoins.toDouble();
      user.wallet.adCoins -= requiredAdCoins;
      balAfter = user.wallet.adCoins.toDouble();
      walletUsed = 'AD_COINS';
    } else {
      balBefore = user.wallet.adCoins.toDouble();
      balAfter = balBefore;
      walletUsed = 'FREE';
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

  // --- WITHDRAWAL SYSTEM (WINNING COINS TO UPI CASH) ---
  Map<String, dynamic> requestWithdrawal(double coinsToWithdraw, String upiId) {
    if (coinsToWithdraw < minWithdrawalCoins) {
      return {
        'success': false,
        'message': 'Minimum withdrawal limit is $minWithdrawalCoins 🪙 Winning Coins (₹${(minWithdrawalCoins * coinToRupeeRate).toStringAsFixed(1)}).'
      };
    }
    if (user.wallet.winningCash < coinsToWithdraw) {
      return {
        'success': false,
        'message': 'Insufficient Winning Coins! You have ${user.wallet.winningCash.toInt()} 🪙 Winning Coins available.'
      };
    }
    if (!upiId.contains('@')) {
      return {
        'success': false,
        'message': 'Please enter a valid UPI ID (e.g. 9876543210@ybl or user@oksbi).'
      };
    }

    final double inrAmount = coinsToWithdraw * coinToRupeeRate;
    final balBefore = user.wallet.winningCash;
    user.wallet.winningCash -= coinsToWithdraw;

    final reqId = 'wreq_${DateTime.now().millisecondsSinceEpoch}';
    final newRequest = WithdrawalModel(
      id: reqId,
      userId: user.uid,
      userName: '${user.displayName} (${user.inGameName})',
      userPhone: user.phoneNumber,
      amount: inrAmount,
      coinAmount: coinsToWithdraw,
      upiId: upiId,
      status: WithdrawalStatus.pending,
      requestedAt: DateTime.now(),
      adminNotes: 'Redeemed ${coinsToWithdraw.toInt()} Winning Coins @ ₹$coinToRupeeRate/coin',
    );

    withdrawals.insert(0, newRequest);

    final withTxn = TransactionModel(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      userName: user.displayName,
      type: TransactionType.withdrawalRequest,
      walletAffected: WalletType.winningCash,
      amount: -coinsToWithdraw,
      currency: 'WINNING_COINS',
      balanceBefore: balBefore,
      balanceAfter: user.wallet.winningCash,
      status: 'PENDING',
      description: 'UPI Withdrawal: ₹${inrAmount.toStringAsFixed(1)} (${coinsToWithdraw.toInt()} Coins) to $upiId',
      createdAt: DateTime.now(),
    );
    transactions.insert(0, withTxn);

    _syncUser();
    _syncWithdrawal(newRequest);
    _syncTransaction(withTxn);

    notifyListeners();
    return {
      'success': true,
      'message': 'Withdrawal request for ₹${inrAmount.toStringAsFixed(1)} (${coinsToWithdraw.toInt()} Coins) submitted successfully! Payout will be sent to $upiId within 2-4 hours.',
    };
  }

  // --- ADMIN: UPDATE WINNING COIN CONVERSION RATE ---
  Future<void> adminUpdateCoinRate(double rate, {int? minCoins}) async {
    if (rate > 0) coinToRupeeRate = rate;
    if (minCoins != null && minCoins > 0) minWithdrawalCoins = minCoins;
    notifyListeners();

    try {
      await http.post(
        Uri.parse("$vpsApiUrl/config"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'coinToRupeeRate': coinToRupeeRate,
          'minWithdrawalCoins': minWithdrawalCoins,
          'isRealCashModeEnabled': isRealCashModeEnabled,
          'telegramSupportUrl': telegramSupportUrl,
          'brBannerUrl': brBannerUrl,
          'csBannerUrl': csBannerUrl,
          'lwBannerUrl': lwBannerUrl,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  // --- ADMIN: PUBLISH ROOM ID & PASSWORD ---
  void adminPublishRoomCredentials(String matchId, String roomId, String roomPass) {
    final match = matches.firstWhere((m) => m.id == matchId);
    match.credentials.roomId = roomId;
    match.credentials.roomPassword = roomPass;
    match.credentials.isRevealed = true;
    match.roomPublishedByAdminName = user.displayName.isNotEmpty ? user.displayName : 'Admin';
    match.roomPublishedByAdminUid = user.uid;
    match.roomPublishedAt = DateTime.now();
    match.hostName = user.displayName.isNotEmpty ? user.displayName : 'Admin Host';

    if (match.status == MatchStatus.upcoming || match.status == MatchStatus.roomFilling) {
      match.status = MatchStatus.ongoing;
    }
    _syncMatch(match);
    _notificationService.sendMatchAlert(
      matchId: matchId,
      title: '🔑 ROOM ID & PASSWORD LIVE! (${match.title})',
      body: 'Room ID: $roomId | Password: $roomPass. Join custom room immediately! Hosted by ${match.roomPublishedByAdminName}.',
    );
    notifyListeners();
  }

  // Helper to credit 25% host commission to the admin who published room credentials
  Future<void> _creditHostCommission({
    required MatchModel match,
    required double commissionAmount,
  }) async {
    if (commissionAmount <= 0) return;
    final hostUid = (match.roomPublishedByAdminUid != null && match.roomPublishedByAdminUid!.isNotEmpty)
        ? match.roomPublishedByAdminUid!
        : user.uid;
    final hostName = (match.roomPublishedByAdminName != null && match.roomPublishedByAdminName!.isNotEmpty)
        ? match.roomPublishedByAdminName!
        : (user.displayName.isNotEmpty ? user.displayName : 'Host Admin');

    match.hostCommissionPaid = true;
    match.hostCommissionAmount = commissionAmount;

    if (hostUid == user.uid) {
      final double balBefore = user.wallet.winningCash;
      user.wallet.winningCash += commissionAmount;
      user.stats.totalWinningsCash += commissionAmount;

      final hostTxn = TransactionModel(
        id: 'txn_host_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        userName: user.displayName,
        type: TransactionType.hostCommission,
        walletAffected: WalletType.winningCash,
        amount: commissionAmount,
        currency: 'INR',
        balanceBefore: balBefore,
        balanceAfter: user.wallet.winningCash,
        status: 'SUCCESS',
        description: '💰 25% Host Profit Commission for Match #${match.id} ("${match.title}")',
        createdAt: DateTime.now(),
      );
      transactions.insert(0, hostTxn);
      allGlobalTransactions.insert(0, hostTxn);
      _syncTransaction(hostTxn);
      _syncUser();
    } else {
      try {
        final hostDoc = await FirestoreRestService.getDocument(FirebaseConfig.usersCollection, hostUid);
        if (hostDoc != null && hostDoc.isNotEmpty) {
          final hostUser = UserModel.fromJson(hostDoc);
          final double balBefore = hostUser.wallet.winningCash;
          hostUser.wallet.winningCash += commissionAmount;
          hostUser.stats.totalWinningsCash += commissionAmount;
          await FirestoreRestService.setDocument(FirebaseConfig.usersCollection, hostUid, hostUser.toJson());

          final hostTxn = TransactionModel(
            id: 'txn_host_${DateTime.now().millisecondsSinceEpoch}_$hostUid',
            userId: hostUid,
            userName: hostUser.displayName.isNotEmpty ? hostUser.displayName : hostName,
            type: TransactionType.hostCommission,
            walletAffected: WalletType.winningCash,
            amount: commissionAmount,
            currency: 'INR',
            balanceBefore: balBefore,
            balanceAfter: hostUser.wallet.winningCash,
            status: 'SUCCESS',
            description: '💰 25% Host Profit Commission for Match #${match.id} ("${match.title}")',
            createdAt: DateTime.now(),
          );
          allGlobalTransactions.insert(0, hostTxn);
          await FirestoreRestService.setDocument(FirebaseConfig.transactionsCollection, hostTxn.id, hostTxn.toJson());
        }
      } catch (e) {
        debugPrint('[AppState] Failed to credit host commission to $hostUid: $e');
      }
    }
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
    String? imageUrl,
  }) async {
    return await _notificationService.sendPersonalNotification(
      userId: userId,
      title: title,
      body: body,
      imageUrl: imageUrl,
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
    if (match.hostName == null || match.hostName!.isEmpty) {
      match.hostName = user.displayName.isNotEmpty ? user.displayName : 'Admin Host';
    }
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

    final bool isCashPrize = match.prizePool.isCashPrize || isPaid;

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
        if (isCashPrize) {
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
          isPaid: isCashPrize,
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

    // 💰 Credit 25% Host Profit Commission
    if (isPaid && match.financialBreakdown != null) {
      final hostShare = match.financialBreakdown!.shares.host25;
      _creditHostCommission(match: match, commissionAmount: hostShare);
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
    if (match.hostName == null || match.hostName!.isEmpty) {
      match.hostName = user.displayName.isNotEmpty ? user.displayName : 'Admin Host';
    }
    final bool isPaid = match.matchType == MatchType.paid;
    final bool isCashPrize = match.prizePool.isCashPrize || isPaid;

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
          if (isCashPrize) {
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
          isPaid: isCashPrize,
          matchTitle: match.title,
          rank: rank,
          kills: kills,
        );
      }
    }

    // 💰 Credit 25% Host Profit Commission
    if (isPaid && match.financialBreakdown != null) {
      final hostShare = match.financialBreakdown!.shares.host25;
      _creditHostCommission(match: match, commissionAmount: hostShare);
    }

    _syncUser();
    _syncMatch(match);
    notifyListeners();
  }

  // --- ADMIN: RESPAWN / RESTART MATCH (FOR NEXT ROUND WITH 0 SLOTS) ---
  void adminRespawnMatch(String matchId) {
    final matchIndex = matches.indexWhere((m) => m.id == matchId);
    if (matchIndex == -1) return;

    final match = matches[matchIndex];
    match.status = MatchStatus.upcoming;
    match.filledSlots = 0;
    match.participants = [];
    match.registeredTeams = [];
    match.credentials = MatchCredentials(roomId: '', roomPassword: '');
    match.roomFillingStartedAt = null;
    match.completedAt = null;
    match.hostCommissionPaid = false;
    match.hostCommissionAmount = 0.0;
    match.matchTime = DateTime.now().add(const Duration(minutes: 45));

    _saveLocalMatchesCache();
    _syncMatch(match);
    notifyListeners();
  }

  // --- ADMIN: RESET SLOTS TO 0 (CLEAN PLAYERS) ---
  void adminResetMatchSlots(String matchId) {
    final matchIndex = matches.indexWhere((m) => m.id == matchId);
    if (matchIndex == -1) return;

    final match = matches[matchIndex];
    match.filledSlots = 0;
    match.participants = [];
    match.registeredTeams = [];
    match.status = MatchStatus.upcoming;
    match.roomFillingStartedAt = null;

    _saveLocalMatchesCache();
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
      } else if (dateFilter == 'Yesterday') {
        final yesterday = now.subtract(const Duration(days: 1));
        return completedTime.year == yesterday.year &&
            completedTime.month == yesterday.month &&
            completedTime.day == yesterday.day;
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

  // Multi-Admin / Host Earnings Aggregator with Real Names & UIDs
  List<Map<String, dynamic>> getAdminHostLeaderboard({List<UserModel>? registeredUsers}) {
    final Map<String, Map<String, dynamic>> hostMap = {};

    // 1. Ensure current active admin is present
    if (user.role == 'admin') {
      hostMap[user.uid] = {
        'hostUid': user.uid,
        'hostName': user.displayName.isNotEmpty ? user.displayName : 'Admin (${user.phoneNumber})',
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'avatarUrl': user.avatarUrl,
        'totalMatchesCreated': 0,
        'totalMatchesPublished': 0,
        'totalMatchesCompleted': 0,
        'totalRevenueGenerated': 0.0,
        'totalHostCommissionEarned': 0.0,
      };
    }

    // 2. Include any other registered admins
    if (registeredUsers != null) {
      for (var u in registeredUsers) {
        if (u.role == 'admin') {
          if (!hostMap.containsKey(u.uid)) {
            hostMap[u.uid] = {
              'hostUid': u.uid,
              'hostName': u.displayName.isNotEmpty ? u.displayName : 'Admin (${u.phoneNumber})',
              'email': u.email,
              'phoneNumber': u.phoneNumber,
              'avatarUrl': u.avatarUrl,
              'totalMatchesCreated': 0,
              'totalMatchesPublished': 0,
              'totalMatchesCompleted': 0,
              'totalRevenueGenerated': 0.0,
              'totalHostCommissionEarned': 0.0,
            };
          }
        }
      }
    }

    // 3. Aggregate all match publishing and completions
    for (var m in matches) {
      final hostUid = (m.roomPublishedByAdminUid != null && m.roomPublishedByAdminUid!.isNotEmpty)
          ? m.roomPublishedByAdminUid!
          : (m.createdByAdminUid ?? 'admin_default');
      
      String hostName = (m.roomPublishedByAdminName != null && m.roomPublishedByAdminName!.isNotEmpty)
          ? m.roomPublishedByAdminName!
          : (m.hostName ?? 'Official Admin');

      // Resolve real name from registered users or active user
      if (hostUid == user.uid && user.displayName.isNotEmpty) {
        hostName = user.displayName;
      } else if (registeredUsers != null) {
        final matchUser = registeredUsers.where((u) => u.uid == hostUid).firstOrNull;
        if (matchUser != null && matchUser.displayName.isNotEmpty) {
          hostName = matchUser.displayName;
        }
      }

      if (!hostMap.containsKey(hostUid)) {
        hostMap[hostUid] = {
          'hostUid': hostUid,
          'hostName': hostName,
          'email': hostUid == user.uid ? user.email : '',
          'phoneNumber': hostUid == user.uid ? user.phoneNumber : '',
          'avatarUrl': hostUid == user.uid ? user.avatarUrl : null,
          'totalMatchesCreated': 0,
          'totalMatchesPublished': 0,
          'totalMatchesCompleted': 0,
          'totalRevenueGenerated': 0.0,
          'totalHostCommissionEarned': 0.0,
        };
      }

      hostMap[hostUid]!['totalMatchesCreated'] = (hostMap[hostUid]!['totalMatchesCreated'] as int) + 1;

      if (m.credentials.roomId.isNotEmpty) {
        hostMap[hostUid]!['totalMatchesPublished'] = (hostMap[hostUid]!['totalMatchesPublished'] as int) + 1;
      }

      if (m.status == MatchStatus.completed) {
        hostMap[hostUid]!['totalMatchesCompleted'] = (hostMap[hostUid]!['totalMatchesCompleted'] as int) + 1;
        final fb = m.financialBreakdown ?? FinancialBreakdown.calculate(totalCollection: m.totalCollection);
        hostMap[hostUid]!['totalRevenueGenerated'] = (hostMap[hostUid]!['totalRevenueGenerated'] as double) + fb.totalEntryCollection;
        hostMap[hostUid]!['totalHostCommissionEarned'] = (hostMap[hostUid]!['totalHostCommissionEarned'] as double) + fb.shares.host25;
      }
    }

    final list = hostMap.values.toList();
    list.sort((a, b) => (b['totalHostCommissionEarned'] as double).compareTo(a['totalHostCommissionEarned'] as double));
    return list;
  }

  // Date-wise ledger breakdown
  List<Map<String, dynamic>> getDateWiseFinancialLedger(String dateFilter) {
    final completed = getCompletedMatchesByFilter(dateFilter);
    final Map<String, Map<String, dynamic>> dayMap = {};

    for (var m in completed) {
      final time = m.completedAt ?? m.matchTime;
      final dayKey = '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';

      final fb = m.financialBreakdown ?? FinancialBreakdown.calculate(totalCollection: m.totalCollection);

      if (!dayMap.containsKey(dayKey)) {
        dayMap[dayKey] = {
          'date': dayKey,
          'matchCount': 0,
          'totalCollection': 0.0,
          'grossCommission': 0.0,
          'gatewayFees': 0.0,
          'netProfit': 0.0,
          'founder60': 0.0,
          'host25': 0.0,
          'investor15': 0.0,
          'matches': <MatchModel>[],
        };
      }

      dayMap[dayKey]!['matchCount'] = (dayMap[dayKey]!['matchCount'] as int) + 1;
      dayMap[dayKey]!['totalCollection'] = (dayMap[dayKey]!['totalCollection'] as double) + fb.totalEntryCollection;
      dayMap[dayKey]!['grossCommission'] = (dayMap[dayKey]!['grossCommission'] as double) + fb.platformCommissionGross;
      dayMap[dayKey]!['gatewayFees'] = (dayMap[dayKey]!['gatewayFees'] as double) + fb.gatewayFeeDeduction;
      dayMap[dayKey]!['netProfit'] = (dayMap[dayKey]!['netProfit'] as double) + fb.netProfit;
      dayMap[dayKey]!['founder60'] = (dayMap[dayKey]!['founder60'] as double) + fb.shares.founder60;
      dayMap[dayKey]!['host25'] = (dayMap[dayKey]!['host25'] as double) + fb.shares.host25;
      dayMap[dayKey]!['investor15'] = (dayMap[dayKey]!['investor15'] as double) + fb.shares.investor15;
      (dayMap[dayKey]!['matches'] as List<MatchModel>).add(m);
    }

    final list = dayMap.values.toList();
    list.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return list;
  }

  // ==========================================
  // 🏆 WEEKLY LEADERBOARD & ₹100 PRIZE POOL SYSTEM
  // ==========================================

  /// Get time remaining until the weekly season reset (Sunday 23:59:59 IST)
  Duration getWeeklySeasonTimeRemaining() {
    final now = DateTime.now();
    // Monday = 1, Sunday = 7
    int daysUntilSunday = 7 - now.weekday;
    if (daysUntilSunday < 0) daysUntilSunday = 0;
    
    final endOfWeek = DateTime(now.year, now.month, now.day + daysUntilSunday, 23, 59, 59);
    final diff = endOfWeek.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Get season label (e.g. Week 41 - 05 Oct to 11 Oct)
  String getWeeklySeasonLabel() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${startOfWeek.day} ${months[startOfWeek.month - 1]} - ${endOfWeek.day} ${months[endOfWeek.month - 1]}';
  }

  /// Compute weekly leaderboard with dynamic top 3 ₹100 prize pool (₹50, ₹30, ₹20)
  List<LeaderboardEntry> getWeeklyLeaderboard({String filter = 'WEEKLY', List<UserModel>? registeredUsers}) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1), 0, 0, 0);

    // Map of UID -> aggregated stats
    final Map<String, Map<String, dynamic>> playerStats = {};

    // 1. Process completed matches
    for (var m in matches) {
      if (m.status != MatchStatus.completed) continue;

      final matchDate = m.completedAt ?? m.matchTime;
      final isThisWeek = matchDate.isAfter(startOfWeek) || filter == 'ALL_TIME';
      if (!isThisWeek && filter == 'WEEKLY') continue;

      for (var p in m.participants) {
        final uid = p.uid;
        if (uid.isEmpty) continue;

        if (!playerStats.containsKey(uid)) {
          playerStats[uid] = {
            'uid': uid,
            'displayName': p.inGameName.isNotEmpty ? p.inGameName : 'Player',
            'inGameName': p.inGameName,
            'inGameUid': p.inGameUid,
            'inGameLevel': 45,
            'avatarUrl': null,
            'kills': 0,
            'matchesWon': 0,
            'matchesPlayed': 0,
            'winningsCash': 0.0,
            'rewardCoins': 0,
            'totalReferrals': 0,
          };
        }

        playerStats[uid]!['kills'] = (playerStats[uid]!['kills'] as int) + p.kills;
        playerStats[uid]!['matchesPlayed'] = (playerStats[uid]!['matchesPlayed'] as int) + 1;
        if (p.isWinner || p.rank == 1) {
          playerStats[uid]!['matchesWon'] = (playerStats[uid]!['matchesWon'] as int) + 1;
        }
        playerStats[uid]!['winningsCash'] = (playerStats[uid]!['winningsCash'] as double) + (p.prizeAwarded ?? 0.0);
      }
    }

    // 2. Include registered users if supplied
    if (registeredUsers != null) {
      for (var u in registeredUsers) {
        if (!playerStats.containsKey(u.uid) && u.uid != 'user_guest') {
          playerStats[u.uid] = {
            'uid': u.uid,
            'displayName': u.displayName,
            'inGameName': u.inGameName ?? u.displayName,
            'inGameUid': u.inGameUid ?? '897654321',
            'inGameLevel': u.inGameLevel,
            'avatarUrl': u.avatarUrl,
            'kills': filter == 'WEEKLY' ? (u.stats.totalKills > 0 ? (u.stats.totalKills % 15) : 0) : u.stats.totalKills,
            'matchesWon': filter == 'WEEKLY' ? (u.stats.matchesWon > 0 ? (u.stats.matchesWon % 5) : 0) : u.stats.matchesWon,
            'matchesPlayed': filter == 'WEEKLY' ? (u.stats.matchesPlayed > 0 ? (u.stats.matchesPlayed % 8) : 0) : u.stats.matchesPlayed,
            'winningsCash': filter == 'WEEKLY' ? (u.stats.totalWinningsCash > 0 ? (u.stats.totalWinningsCash % 200) : 0.0) : u.stats.totalWinningsCash,
            'rewardCoins': u.wallet.rewardCoins,
            'totalReferrals': u.totalReferrals,
          };
        }
      }
    }

    // 3. Ensure current logged-in user is registered in the pool
    if (user.uid.isNotEmpty && user.uid != 'user_guest') {
      if (!playerStats.containsKey(user.uid)) {
        playerStats[user.uid] = {
          'uid': user.uid,
          'displayName': user.displayName,
          'inGameName': user.inGameName ?? user.displayName,
          'inGameUid': user.inGameUid ?? '897654321',
          'inGameLevel': user.inGameLevel,
          'avatarUrl': user.avatarUrl,
          'kills': filter == 'WEEKLY' ? (user.stats.totalKills > 0 ? (user.stats.totalKills % 15) : 0) : user.stats.totalKills,
          'matchesWon': filter == 'WEEKLY' ? (user.stats.matchesWon > 0 ? (user.stats.matchesWon % 5) : 0) : user.stats.matchesWon,
          'matchesPlayed': filter == 'WEEKLY' ? (user.stats.matchesPlayed > 0 ? (user.stats.matchesPlayed % 8) : 0) : user.stats.matchesPlayed,
          'winningsCash': filter == 'WEEKLY' ? (user.stats.totalWinningsCash > 0 ? (user.stats.totalWinningsCash % 200) : 0.0) : user.stats.totalWinningsCash,
          'rewardCoins': user.wallet.rewardCoins,
          'totalReferrals': user.totalReferrals,
        };
      } else {
        // Enhance with user model details
        playerStats[user.uid]!['displayName'] = user.displayName;
        playerStats[user.uid]!['inGameName'] = user.inGameName ?? user.displayName;
        playerStats[user.uid]!['inGameUid'] = user.inGameUid ?? playerStats[user.uid]!['inGameUid'];
        playerStats[user.uid]!['inGameLevel'] = user.inGameLevel;
        playerStats[user.uid]!['avatarUrl'] = user.avatarUrl;
        playerStats[user.uid]!['totalReferrals'] = user.totalReferrals;
      }
    }

    // 4. Calculate Leaderboard Points for REAL users only (Formula: (Kills * 10) + (Wins * 50) + (WinningsCash * 2) + (Referrals * 20))
    final List<LeaderboardEntry> rawList = [];
    playerStats.forEach((uid, data) {
      final kills = (data['kills'] ?? 0) as int;
      final wins = (data['matchesWon'] ?? 0) as int;
      final played = (data['matchesPlayed'] ?? 0) as int;
      final cash = ((data['winningsCash'] ?? 0) as num).toDouble();
      final coins = (data['rewardCoins'] ?? 0) as int;
      final referrals = (data['totalReferrals'] ?? 0) as int;
      final totalPoints = (kills * 10) + (wins * 50) + (cash * 2).toInt() + (referrals * 20);

      rawList.add(
        LeaderboardEntry(
          uid: uid,
          displayName: (data['displayName'] ?? 'Player').toString(),
          inGameName: data['inGameName']?.toString(),
          inGameUid: data['inGameUid']?.toString(),
          inGameLevel: (data['inGameLevel'] ?? 45) as int,
          avatarUrl: data['avatarUrl']?.toString(),
          rank: 0, // Assigned after sorting
          kills: kills,
          matchesWon: wins,
          matchesPlayed: played,
          winningsCash: cash,
          rewardCoins: coins,
          points: totalPoints,
          prizeAmount: 0.0, // Assigned after ranking
          isCurrentUser: (uid == user.uid),
        ),
      );
    });

    // 5. Sort descending by points (tie-breaker: kills, then wins)
    rawList.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.kills != a.kills) return b.kills.compareTo(a.kills);
      return b.matchesWon.compareTo(a.matchesWon);
    });

    // 6. Assign Ranks and Top 3 Prizes (Rank 1: 200 Coins, Rank 2: 150 Coins, Rank 3: 100 Coins)
    final List<LeaderboardEntry> rankedList = [];
    for (int i = 0; i < rawList.length; i++) {
      final item = rawList[i];
      final rank = i + 1;
      double prize = 0.0;
      if (rank == 1) {
        prize = 200.0;
      } else if (rank == 2) {
        prize = 150.0;
      } else if (rank == 3) {
        prize = 100.0;
      }

      rankedList.add(
        LeaderboardEntry(
          uid: item.uid,
          displayName: item.displayName,
          inGameName: item.inGameName,
          inGameUid: item.inGameUid,
          inGameLevel: item.inGameLevel,
          avatarUrl: item.avatarUrl,
          rank: rank,
          kills: item.kills,
          matchesWon: item.matchesWon,
          matchesPlayed: item.matchesPlayed,
          winningsCash: item.winningsCash,
          rewardCoins: item.rewardCoins,
          points: item.points,
          prizeAmount: prize,
          isCurrentUser: item.isCurrentUser,
        ),
      );
    }

    return rankedList;
  }

  /// Apply referral code: credits 10 Bonus Cash + 10 Ad Coins to BOTH users
  Future<Map<String, dynamic>> applyReferralCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      return {'success': false, 'message': 'Please enter a valid referral code'};
    }

    if (user.uid.isEmpty || user.uid == 'user_guest') {
      return {'success': false, 'message': 'Please login to apply a referral code'};
    }

    if (user.referredBy != null && user.referredBy!.isNotEmpty) {
      return {'success': false, 'message': 'You have already applied a referral code!'};
    }

    if (code == user.referralCode.toUpperCase()) {
      return {'success': false, 'message': 'You cannot use your own referral code!'};
    }

    // --- STEP 1: Fast Atomic VPS Referral Application ---
    try {
      final res = await http.post(
        Uri.parse("$vpsApiUrl/referrals/apply"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'referredUid': user.uid,
          'referralCode': code,
        }),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          if (data['referredUser'] != null && data['referredUser'] is Map) {
            user = UserModel.fromJson(Map<String, dynamic>.from(data['referredUser']));
            await AuthService.saveUser(user);
          } else {
            user.wallet.bonusCash += 10.0;
            user.wallet.adCoins += 10;
            user.referredBy = code;
            _syncUser();
          }

          if (data['refRecord'] != null && data['refRecord'] is Map) {
            final rec = ReferralRecord.fromJson(Map<String, dynamic>.from(data['refRecord']));
            allGlobalReferralRecords.removeWhere((r) => r.id == rec.id);
            allGlobalReferralRecords.insert(0, rec);
            referralRecords.removeWhere((r) => r.id == rec.id);
            if (rec.referrerUid == user.uid || rec.referrerCode == user.referralCode) {
              referralRecords.insert(0, rec);
            }
            _saveLocalReferralsCache();
          }

          notifyListeners();
          return {
            'success': true,
            'message': '🎁 Referral Code Applied! 10 Bonus Cash + 10 Ad Coins credited to both wallets!'
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Could not apply referral code.'
          };
        }
      }
    } catch (e) {
      debugPrint('[AppState] VPS referral apply notice: $e');
    }

    UserModel? referrer;
    // Check VPS /users endpoint for referrer
    try {
      final userRes = await http.get(Uri.parse("$vpsApiUrl/users")).timeout(const Duration(seconds: 4));
      if (userRes.statusCode == 200) {
        final uData = jsonDecode(userRes.body);
        if (uData['users'] is List) {
          for (var d in (uData['users'] as List)) {
            final u = UserModel.fromJson(Map<String, dynamic>.from(d));
            if (u.referralCode.toUpperCase() == code && u.uid != user.uid) {
              referrer = u;
              break;
            }
          }
        }
      }
    } catch (_) {}

    try {
      final userDocs = await FirestoreRestService.getCollectionDocuments(FirebaseConfig.usersCollection);
      for (var d in userDocs) {
        final u = UserModel.fromJson(d);
        if (u.referralCode.toUpperCase() == code && u.uid != user.uid) {
          referrer = u;
          break;
        }
      }
    } catch (_) {}

    // Fallback: Check standard 6-digit numeric or standard format
    if (referrer == null && (code.length < 5)) {
      return {'success': false, 'message': 'Invalid referral code. Please verify and try again.'};
    }

    // Reward: 10 Bonus Cash & 10 Ad Coins to BOTH users
    const rewardBonusCash = 10.0;
    const rewardAdCoins = 10;

    user.wallet.bonusCash += rewardBonusCash;
    user.wallet.adCoins += rewardAdCoins;
    user.referredBy = code;
    _syncUser();

    // Create persistent ReferralRecord
    final refRecord = ReferralRecord(
      id: 'ref_${DateTime.now().millisecondsSinceEpoch}',
      referrerUid: referrer?.uid ?? 'referrer_$code',
      referrerName: referrer?.displayName ?? (referrer?.inGameName ?? 'Inviter ($code)'),
      referrerCode: code,
      referredUid: user.uid,
      referredName: user.displayName.isNotEmpty ? user.displayName : (user.inGameName ?? 'New Player'),
      createdAt: DateTime.now(),
      bonusCashAwarded: rewardBonusCash,
      adCoinsAwarded: rewardAdCoins,
    );
    allGlobalReferralRecords.insert(0, refRecord);
    referralRecords.insert(0, refRecord);
    _syncReferralRecord(refRecord);

    // Transaction for current user
    final userTxn = TransactionModel(
      id: 'txn_ref_welcome_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      userName: user.displayName,
      type: TransactionType.referralReward,
      walletAffected: WalletType.bonusCash,
      amount: rewardBonusCash,
      currency: 'INR',
      balanceBefore: user.wallet.bonusCash - rewardBonusCash,
      balanceAfter: user.wallet.bonusCash,
      status: 'SUCCESS',
      description: '🎁 Referral Welcome Bonus (Code: $code) - ₹10 Bonus + 10 Ad Coins',
      createdAt: DateTime.now(),
    );
    transactions.insert(0, userTxn);
    allGlobalTransactions.insert(0, userTxn);
    _syncTransaction(userTxn);

    // Notification for current user
    final userNotif = AppNotification(
      id: 'notif_ref_user_${DateTime.now().millisecondsSinceEpoch}',
      title: '🎁 10 Bonus Coins Credited!',
      body: 'Welcome! You received 10 Bonus Cash + 10 Ad Coins for applying referral code $code.',
      createdAt: DateTime.now(),
      type: NotificationType.matchResult,
      targetType: 'user',
      targetId: user.uid,
    );
    notifications.insert(0, userNotif);
    allGlobalNotifications.insert(0, userNotif);

    // Credit referrer if located
    if (referrer != null) {
      referrer.wallet.bonusCash += rewardBonusCash;
      referrer.wallet.adCoins += rewardAdCoins;
      referrer.totalReferrals += 1;
      referrer.totalReferralCoins += 10;

      try {
        await FirestoreRestService.setDocument(FirebaseConfig.usersCollection, referrer.uid, referrer.toJson());
        await http.post(
          Uri.parse("$vpsApiUrl/users"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(referrer.toJson()),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}

      final refTxn = TransactionModel(
        id: 'txn_ref_bonus_${referrer.uid}_${DateTime.now().millisecondsSinceEpoch}',
        userId: referrer.uid,
        userName: referrer.displayName,
        type: TransactionType.referralReward,
        walletAffected: WalletType.bonusCash,
        amount: rewardBonusCash,
        currency: 'INR',
        balanceBefore: referrer.wallet.bonusCash - rewardBonusCash,
        balanceAfter: referrer.wallet.bonusCash,
        status: 'SUCCESS',
        description: '👥 Referral Reward from ${user.displayName} - ₹10 Bonus + 10 Ad Coins',
        createdAt: DateTime.now(),
      );
      allGlobalTransactions.insert(0, refTxn);
      _syncTransaction(refTxn);

      final refNotif = AppNotification(
        id: 'notif_ref_referrer_${DateTime.now().millisecondsSinceEpoch}',
        title: '👥 New Friend Joined via Your Referral!',
        body: '${user.displayName} joined using your referral code. ₹10 Bonus Cash + 10 Ad Coins credited to your wallet!',
        createdAt: DateTime.now(),
        type: NotificationType.matchResult,
        targetType: 'user',
        targetId: referrer.uid,
      );
      allGlobalNotifications.insert(0, refNotif);
    }

    notifyListeners();
    return {
      'success': true,
      'message': 'Success! 10 Bonus Coins & 10 Ad Coins credited to your wallet.',
      'bonusCash': rewardBonusCash,
      'adCoins': rewardAdCoins,
    };
  }

  /// Admin 1-Click Distribute 450 🪙 Weekly Championship Coins (Rank 1: 200 Coins, Rank 2: 150 Coins, Rank 3: 100 Coins)
  Future<Map<String, dynamic>> adminDistributeWeeklyLeaderboardPrizes() async {
    final leaderboard = getWeeklyLeaderboard(filter: 'WEEKLY');
    final top3 = leaderboard.take(3).toList();

    if (top3.isEmpty) {
      return {'success': false, 'message': 'No eligible players found on leaderboard'};
    }

    final seasonLabel = getWeeklySeasonLabel();
    final List<LeaderboardWinnerPayout> winnerPayouts = [];
    double totalDistributed = 0.0;

    for (var winner in top3) {
      final prize = winner.prizeAmount;
      if (prize <= 0) continue;

      totalDistributed += prize;
      winnerPayouts.add(
        LeaderboardWinnerPayout(
          rank: winner.rank,
          uid: winner.uid,
          name: winner.displayName,
          inGameName: winner.inGameName,
          prizeAmount: prize,
          points: winner.points,
        ),
      );

      // If winner is current active user, credit immediately
      if (winner.uid == user.uid) {
        user.wallet.winningCash += prize;
        user.stats.totalWinningsCash += prize;
        _syncUser();
      } else {
        // Attempt remote credit via Firestore & VPS
        try {
          final doc = await FirestoreRestService.getDocument(FirebaseConfig.usersCollection, winner.uid);
          if (doc != null) {
            final targetUser = UserModel.fromJson(doc);
            targetUser.wallet.winningCash += prize;
            targetUser.stats.totalWinningsCash += prize;
            await FirestoreRestService.setDocument(FirebaseConfig.usersCollection, winner.uid, targetUser.toJson());
          }
        } catch (_) {}
      }

      // Create Winner Ledger Transaction
      final txn = TransactionModel(
        id: 'txn_weekly_prize_${winner.rank}_${DateTime.now().millisecondsSinceEpoch}',
        userId: winner.uid,
        userName: winner.displayName,
        type: TransactionType.weeklyLeaderboardReward,
        walletAffected: WalletType.winningCash,
        amount: prize,
        currency: 'COINS',
        balanceBefore: (winner.uid == user.uid) ? (user.wallet.winningCash - prize) : 0,
        balanceAfter: (winner.uid == user.uid) ? user.wallet.winningCash : prize,
        status: 'SUCCESS',
        description: '🏆 Weekly Leaderboard Rank #${winner.rank} Championship Prize (${prize.toInt()} 🪙 Coins)',
        createdAt: DateTime.now(),
        metadata: {
          'rank': winner.rank,
          'points': winner.points,
          'season': seasonLabel,
        },
      );

      if (winner.uid == user.uid) {
        transactions.insert(0, txn);
      }
      allGlobalTransactions.insert(0, txn);
      _syncTransaction(txn);

      // Create Winner In-App Notification
      final notif = AppNotification(
        id: 'notif_weekly_win_${winner.rank}_${DateTime.now().millisecondsSinceEpoch}',
        title: '🎉 450 🪙 Weekly Leaderboard Reward Won!',
        body: 'Congratulations ${winner.displayName}! You secured Rank #${winner.rank} with ${winner.points} pts in the Weekly Esports Championship! ${prize.toInt()} 🪙 Winning Coins have been credited directly to your Winning Wallet.',
        createdAt: DateTime.now(),
        type: NotificationType.matchResult,
        targetType: 'user',
        targetId: winner.uid,
        isRead: false,
      );
      if (winner.uid == user.uid) {
        notifications.insert(0, notif);
      }
      allGlobalNotifications.insert(0, notif);
    }

    // Save distribution record
    final record = WeeklyDistributionRecord(
      id: 'dist_weekly_${DateTime.now().millisecondsSinceEpoch}',
      seasonLabel: seasonLabel,
      distributedAt: DateTime.now(),
      adminUid: user.uid,
      adminName: user.displayName,
      winners: winnerPayouts,
      totalDistributed: totalDistributed,
    );

    weeklyDistributions.insert(0, record);
    FirestoreRestService.setDocument('skillwinner_weekly_distributions', record.id, record.toJson());

    // Sync distribution with VPS backend
    try {
      await http.post(
        Uri.parse("$vpsApiUrl/leaderboard/distribute"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(record.toJson()),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    notifyListeners();
    return {
      'success': true,
      'winners': winnerPayouts,
      'totalDistributed': totalDistributed,
      'season': seasonLabel,
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

  /// Cancel match and automatically refund Ad Coins to ALL joined participants
  Future<Map<String, dynamic>> adminCancelAndRefundMatch(String matchId) async {
    final matchIndex = matches.indexWhere((m) => m.id == matchId);
    if (matchIndex == -1) return {'success': false, 'message': 'Match not found'};
    final match = matches[matchIndex];

    int refundedPlayersCount = 0;
    int totalCoinsRefunded = 0;

    // Refund each participant
    for (var p in match.participants) {
      final refundAmount = p.amountPaid > 0 ? p.amountPaid.toInt() : match.entryFee.toInt();
      if (refundAmount <= 0) continue;

      refundedPlayersCount++;
      totalCoinsRefunded += refundAmount;

      // If active user, credit immediately
      if (p.uid == user.uid) {
        final balBefore = user.wallet.adCoins.toDouble();
        user.wallet.adCoins += refundAmount;
        final balAfter = user.wallet.adCoins.toDouble();
        _syncUser();

        final refundTxn = TransactionModel(
          id: 'txn_refund_${DateTime.now().millisecondsSinceEpoch}_${p.uid}',
          userId: user.uid,
          userName: user.displayName,
          type: TransactionType.matchRefund,
          walletAffected: WalletType.adCoins,
          amount: refundAmount.toDouble(),
          currency: 'AD_COINS',
          balanceBefore: balBefore,
          balanceAfter: balAfter,
          status: 'SUCCESS',
          description: '🟡 Match Refund: "${match.title}" cancelled by Admin',
          createdAt: DateTime.now(),
        );
        transactions.insert(0, refundTxn);
        allGlobalTransactions.insert(0, refundTxn);
        _syncTransaction(refundTxn);

        final notif = AppNotification(
          id: 'notif_refund_${DateTime.now().millisecondsSinceEpoch}',
          title: '🟡 Match Cancelled: $refundAmount Coins Refunded',
          body: 'Match "${match.title}" was cancelled by Admin. Your entry fee of $refundAmount 🟡 Ad Coins has been credited back to your wallet.',
          createdAt: DateTime.now(),
          type: NotificationType.matchResult,
          targetType: 'user',
          targetId: user.uid,
        );
        notifications.insert(0, notif);
        allGlobalNotifications.insert(0, notif);
      } else {
        // Remote user credit via Firestore & VPS
        try {
          final doc = await FirestoreRestService.getDocument(FirebaseConfig.usersCollection, p.uid);
          if (doc != null) {
            final targetUser = UserModel.fromJson(doc);
            final balBefore = targetUser.wallet.adCoins.toDouble();
            targetUser.wallet.adCoins += refundAmount;
            final balAfter = targetUser.wallet.adCoins.toDouble();
            await FirestoreRestService.setDocument(FirebaseConfig.usersCollection, p.uid, targetUser.toJson());

            final remoteTxn = TransactionModel(
              id: 'txn_refund_${DateTime.now().millisecondsSinceEpoch}_${p.uid}',
              userId: targetUser.uid,
              userName: targetUser.displayName,
              type: TransactionType.matchRefund,
              walletAffected: WalletType.adCoins,
              amount: refundAmount.toDouble(),
              currency: 'AD_COINS',
              balanceBefore: balBefore,
              balanceAfter: balAfter,
              status: 'SUCCESS',
              description: '🟡 Match Refund: "${match.title}" cancelled by Admin',
              createdAt: DateTime.now(),
            );
            allGlobalTransactions.insert(0, remoteTxn);
            _syncTransaction(remoteTxn);
          }
        } catch (_) {}
      }
    }

    // Now remove match from matches list and sync delete
    matches.removeWhere((m) => m.id == matchId);
    _saveLocalMatchesCache();
    try {
      http.delete(Uri.parse("$vpsApiUrl/matches/$matchId")).timeout(const Duration(seconds: 4));
    } catch (_) {}
    FirestoreRestService.deleteDocument(FirebaseConfig.matchesCollection, matchId);
    notifyListeners();

    return {
      'success': true,
      'refundedPlayers': refundedPlayersCount,
      'totalCoinsRefunded': totalCoinsRefunded,
      'message': 'Match cancelled! Refunded $totalCoinsRefunded 🟡 Ad Coins to $refundedPlayersCount player(s).',
    };
  }

  void adminDeleteMatch(String matchId) {
    adminCancelAndRefundMatch(matchId);
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

      // --- ATTEMPT 1: High-Speed VPS Dedicated Server Sync (Zero Limit & Instant) ---
      bool backendSyncSuccess = false;
      try {
        final syncUrl = Uri.parse("$vpsApiUrl/sync?uid=${uidToSync ?? ''}");
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
            if (data['banners'] is List) {
              banners = (data['banners'] as List).map((d) => BannerModel.fromJson(Map<String, dynamic>.from(d))).where((b) => b.isActive).toList();
            }

            // 3. User Profile
            if (data['user'] != null && data['user'] is Map && (data['user'] as Map).isNotEmpty) {
              user = UserModel.fromJson(Map<String, dynamic>.from(data['user']));
              isAuthenticated = true;
              await AuthService.saveUser(user);
            }

            // 4. Dynamic Tournament Modes
            if (data['modes'] is List) {
              final modeList = (data['modes'] as List).map((d) => TournamentModeItem.fromJson(Map<String, dynamic>.from(d))).toList();
              if (modeList.isNotEmpty) {
                tournamentModes = modeList;
              }
            }

            // 5. Config
            if (data['config'] != null) {
              final cfg = data['config'];
              if (cfg['telegramSupportUrl'] != null) {
                telegramSupportUrl = cfg['telegramSupportUrl'].toString();
              }
              if (cfg['isRealCashModeEnabled'] != null) {
                isRealCashModeEnabled = cfg['isRealCashModeEnabled'] == true ||
                    cfg['isRealCashModeEnabled'].toString() == 'true';
                try {
                  WebStorageHelper.setItem('booyah_safe_mode_cash_enabled', isRealCashModeEnabled ? 'true' : 'false');
                  SharedPreferences.getInstance().then((prefs) => prefs.setString('booyah_safe_mode_cash_enabled', isRealCashModeEnabled ? 'true' : 'false'));
                } catch (_) {}
              }
              if (cfg['coinToRupeeRate'] != null) {
                final r = (cfg['coinToRupeeRate'] as num).toDouble();
                if (r > 0) coinToRupeeRate = r;
              }
              if (cfg['minWithdrawalCoins'] != null) {
                final m = (cfg['minWithdrawalCoins'] as num).toInt();
                if (m > 0) minWithdrawalCoins = m;
              }
              if (cfg['brBannerUrl'] != null && cfg['brBannerUrl'].toString().isNotEmpty) {
                brBannerUrl = cfg['brBannerUrl'].toString();
              }
              if (cfg['csBannerUrl'] != null && cfg['csBannerUrl'].toString().isNotEmpty) {
                csBannerUrl = cfg['csBannerUrl'].toString();
              }
              if (cfg['lwBannerUrl'] != null && cfg['lwBannerUrl'].toString().isNotEmpty) {
                lwBannerUrl = cfg['lwBannerUrl'].toString();
              }
            }

            // 6. Notifications
            if (data['notifications'] is List) {
              final parsed = (data['notifications'] as List).map((d) => AppNotification.fromJson(Map<String, dynamic>.from(d))).toList();
              allGlobalNotifications = parsed;
              notifications = allGlobalNotifications.where((n) {
                if (n.targetType == 'all') return true;
                if (n.targetType == 'match' && matches.any((m) => m.id == n.targetId && m.participants.any((p) => p.uid == user.uid))) return true;
                if (n.targetType == 'user' && n.targetId == user.uid) return true;
                if (n.targetType == 'admin' && user.role == 'admin') return true;
                return false;
              }).toList();
            }

            // 7. Referrals from VPS
            if (data['referrals'] is List) {
              final parsed = (data['referrals'] as List).map((d) => ReferralRecord.fromJson(Map<String, dynamic>.from(d))).toList();
              parsed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              allGlobalReferralRecords = parsed;
              referralRecords = allGlobalReferralRecords.where((r) => r.referrerUid == user.uid || r.referrerCode == user.referralCode).toList();
              _saveLocalReferralsCache();
            }

            // 8. Transactions from VPS
            if (data['transactions'] is List) {
              final parsed = (data['transactions'] as List).map((d) => TransactionModel.fromJson(Map<String, dynamic>.from(d))).toList();
              parsed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              allGlobalTransactions = parsed;
              transactions = allGlobalTransactions.where((t) => t.userId == user.uid).toList();
              _saveLocalTxnCache();
            }

            backendSyncSuccess = true;
          }
        }
      } catch (e) {
        debugPrint('[AppState] VPS backend sync notice: $e');
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
        banners = bannerDocs.map((d) => BannerModel.fromJson(d)).where((b) => b.isActive).toList();
      } catch (e) {
        debugPrint('[AppState] Sync banners error: $e');
      }

      // 8. Sync Telegram Support & App Config (Only if VPS failed)
      if (!backendSyncSuccess) {
        try {
          final configDoc = await FirestoreRestService.getDocument('skillwinner_settings', 'app_config');
          if (configDoc != null) {
            if (configDoc['telegramSupportUrl'] != null) {
              telegramSupportUrl = configDoc['telegramSupportUrl'].toString();
            }
            if (configDoc['isRealCashModeEnabled'] != null) {
              isRealCashModeEnabled = configDoc['isRealCashModeEnabled'] == true ||
                  configDoc['isRealCashModeEnabled'].toString() == 'true';
              try {
                WebStorageHelper.setItem('booyah_safe_mode_cash_enabled', isRealCashModeEnabled ? 'true' : 'false');
                SharedPreferences.getInstance().then((prefs) => prefs.setString('booyah_safe_mode_cash_enabled', isRealCashModeEnabled ? 'true' : 'false'));
              } catch (_) {}
            }
          }
        } catch (e) {
          debugPrint('[AppState] Sync telegram support & config error: $e');
        }
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

      // 10. Sync Referral Records
      try {
        final refDocs = await FirestoreRestService.getCollectionDocuments('skillwinner_referrals');
        if (refDocs.isNotEmpty) {
          final parsed = refDocs.map((d) => ReferralRecord.fromJson(d)).toList();
          parsed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          allGlobalReferralRecords = parsed;
          referralRecords = allGlobalReferralRecords.where((r) => r.referrerUid == user.uid || r.referrerCode == user.referralCode).toList();
          _saveLocalReferralsCache();
        }
      } catch (e) {
        debugPrint('[AppState] Sync referrals error: $e');
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
    try {
      WebStorageHelper.setItem('booyah_safe_mode_cash_enabled', enabled ? 'true' : 'false');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('booyah_safe_mode_cash_enabled', enabled ? 'true' : 'false');
    } catch (_) {}
    notifyListeners();

    // 1. Sync to VPS Backend
    try {
      await http.post(
        Uri.parse("$vpsApiUrl/config"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'isRealCashModeEnabled': enabled,
          'telegramSupportUrl': telegramSupportUrl,
          'brBannerUrl': brBannerUrl,
          'csBannerUrl': csBannerUrl,
          'lwBannerUrl': lwBannerUrl,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    // 2. Sync to Firestore as fallback
    try {
      await FirestoreRestService.setDocument('skillwinner_settings', 'app_config', {
        'isRealCashModeEnabled': enabled,
        'telegramSupportUrl': telegramSupportUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // --- ADMIN: CATEGORY BANNERS URL CONFIGURATION ---
  Future<void> adminUpdateCategoryBanners({String? br, String? cs, String? lw}) async {
    if (br != null && br.isNotEmpty) brBannerUrl = br.trim();
    if (cs != null && cs.isNotEmpty) csBannerUrl = cs.trim();
    if (lw != null && lw.isNotEmpty) lwBannerUrl = lw.trim();
    notifyListeners();

    try {
      await http.post(
        Uri.parse("$vpsApiUrl/config"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'brBannerUrl': brBannerUrl,
          'csBannerUrl': csBannerUrl,
          'lwBannerUrl': lwBannerUrl,
          'telegramSupportUrl': telegramSupportUrl,
          'isRealCashModeEnabled': isRealCashModeEnabled,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  // --- ADMIN: DYNAMIC TOURNAMENT MODES MANAGEMENT ---
  Future<void> adminSaveTournamentMode(TournamentModeItem modeItem) async {
    final index = tournamentModes.indexWhere((m) => m.key == modeItem.key);
    if (index >= 0) {
      tournamentModes[index] = modeItem;
    } else {
      tournamentModes.add(modeItem);
    }
    if (modeItem.key == 'BR') brBannerUrl = modeItem.bannerUrl;
    if (modeItem.key == 'CS') csBannerUrl = modeItem.bannerUrl;
    if (modeItem.key == 'LONE_WOLF') lwBannerUrl = modeItem.bannerUrl;
    notifyListeners();

    try {
      await http.post(
        Uri.parse("$vpsApiUrl/modes"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(modeItem.toJson()),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  Future<void> adminDeleteTournamentMode(String modeKey) async {
    tournamentModes.removeWhere((m) => m.key == modeKey);
    notifyListeners();

    try {
      await http.delete(
        Uri.parse("$vpsApiUrl/modes/$modeKey"),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }


  // --- ADMIN: DIRECT IMAGE UPLOAD TO VPS ---
  Future<String?> uploadBannerImageFile(Uint8List fileBytes, String filename) async {
    try {
      final uri = Uri.parse('$vpsApiUrl/upload');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        fileBytes,
        filename: filename,
      ));
      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['fileUrl'] != null) {
          return data['fileUrl'].toString();
        }
      }
    } catch (e) {
      debugPrint('[AppState] Upload image to VPS error: $e');
    }
    return null;
  }

  // --- ADMIN: FETCH UPLOADED GALLERY FROM VPS ---
  Future<List<Map<String, dynamic>>> getUploadedGallery() async {
    try {
      final res = await http.get(Uri.parse('$vpsApiUrl/uploads')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['files'] is List) {
          return List<Map<String, dynamic>>.from(data['files']);
        }
      }
    } catch (e) {
      debugPrint('[AppState] Get gallery error: $e');
    }
    return [];
  }

  // --- ADMIN: TELEGRAM CUSTOMER SUPPORT URL CONFIGURATION ---
  void adminUpdateTelegramUrl(String url) {
    telegramSupportUrl = url.trim();
    http.post(
      Uri.parse("$vpsApiUrl/config"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'telegramSupportUrl': telegramSupportUrl}),
    ).catchError((_) => http.Response('', 500));
    notifyListeners();
  }

  // --- ADMIN: DYNAMIC PROMO BANNERS ---
  void adminAddBanner(BannerModel newBanner) {
    banners.insert(0, newBanner);
    http.post(
      Uri.parse("$vpsApiUrl/banners"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(newBanner.toJson()),
    ).catchError((_) => http.Response('', 500));
    FirestoreRestService.setDocument('skillwinner_banners', newBanner.id, newBanner.toJson());
    notifyListeners();
  }

  void adminDeleteBanner(String bannerId) {
    banners.removeWhere((b) => b.id == bannerId);
    http.delete(Uri.parse("$vpsApiUrl/banners/$bannerId")).catchError((_) => http.Response('', 500));
    FirestoreRestService.deleteDocument('skillwinner_banners', bannerId);
    notifyListeners();
  }


  Future<void> _syncUser() async {
    await AuthService.saveUser(user);
    try {
      await http.post(
        Uri.parse("$vpsApiUrl/users"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
    await FirestoreRestService.setDocument(FirebaseConfig.usersCollection, user.uid, user.toJson());
  }

  Future<void> _syncMatch(MatchModel m) async {
    try {
      await http.put(
        Uri.parse("$vpsApiUrl/matches/${m.id}"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(m.toJson()),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
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

  void _saveLocalReferralsCache() {
    try {
      final list = allGlobalReferralRecords.map((r) => r.toJson()).toList();
      final jsonStr = jsonEncode(list);
      WebStorageHelper.setItem('booyah_cached_referrals', jsonStr);
      SharedPreferences.getInstance().then((prefs) => prefs.setString('booyah_cached_referrals', jsonStr));
    } catch (e) {
      debugPrint('[AppState] Save local referrals cache error: $e');
    }
  }

  Future<void> _syncReferralRecord(ReferralRecord rec) async {
    _saveLocalReferralsCache();
    await FirestoreRestService.setDocument('skillwinner_referrals', rec.id, rec.toJson());
    try {
      await http.post(
        Uri.parse("$vpsApiUrl/referrals"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(rec.toJson()),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }
}
