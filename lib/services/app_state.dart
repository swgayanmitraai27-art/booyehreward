import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/match_model.dart';
import '../models/team_model.dart';
import '../models/transaction_model.dart';
import '../models/withdrawal_model.dart';
import '../models/voucher_model.dart';
import 'firestore_rest_service.dart';
import 'firebase_config.dart';
import 'auth_service.dart';

class AppState extends ChangeNotifier {
  late UserModel user;
  List<MatchModel> matches = [];
  List<TransactionModel> transactions = [];
  List<WithdrawalModel> withdrawals = [];
  List<VoucherClaim> voucherClaims = [];
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
    _syncWithFirestore();
  }

  void setUser(UserModel u) {
    user = u;
    isAuthenticated = true;
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
  }

  // --- GETTERS ---
  List<MatchModel> get myMatches {
    return matches.where((m) => m.participants.any((p) => p.uid == user.uid)).toList();
  }

  List<MatchModel> get filteredMatches {
    return matches.where((m) {
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

      return true;
    }).toList();
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

    String walletUsed = 'AD_COINS';
    double balBefore = 0;
    double balAfter = 0;

    // VALIDATE WALLET (Free vs Paid)
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
      // PAID MATCH
      final fee = match.entryFee;
      if (user.wallet.depositCash >= fee) {
        balBefore = user.wallet.depositCash;
        user.wallet.depositCash -= fee;
        balAfter = user.wallet.depositCash;
        walletUsed = 'DEPOSIT_CASH';
      } else if (user.wallet.depositCash + user.wallet.winningCash >= fee) {
        final fromDeposit = user.wallet.depositCash;
        final fromWinning = fee - fromDeposit;
        user.wallet.depositCash = 0;
        user.wallet.winningCash -= fromWinning;
        balBefore = fromDeposit + fromWinning;
        balAfter = user.wallet.winningCash;
        walletUsed = 'DEPOSIT_CASH';
      } else {
        return {
          'success': false,
          'message': 'Insufficient Cash! Entry fee is ₹${fee.toInt()}. Add cash via Razorpay.'
        };
      }
    }

    final participant = MatchParticipant(
      uid: user.uid,
      inGameName: user.inGameName,
      inGameUid: user.inGameUid,
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

    String walletUsed = 'AD_COINS';
    double balBefore = 0;
    double balAfter = 0;

    // Deduct entry fee
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
      if (user.wallet.depositCash >= fee) {
        balBefore = user.wallet.depositCash;
        user.wallet.depositCash -= fee;
        balAfter = user.wallet.depositCash;
        walletUsed = 'DEPOSIT_CASH';
      } else if (user.wallet.depositCash + user.wallet.winningCash >= fee) {
        final fromDeposit = user.wallet.depositCash;
        final fromWinning = fee - fromDeposit;
        user.wallet.depositCash = 0;
        user.wallet.winningCash -= fromWinning;
        balBefore = fromDeposit + fromWinning;
        balAfter = user.wallet.winningCash;
        walletUsed = 'DEPOSIT_CASH';
      } else {
        return {
          'success': false,
          'message': 'Insufficient Cash! Entry fee is ₹${fee.toInt()}. Add cash via Razorpay.'
        };
      }
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
      inGameName: user.inGameName,
      inGameUid: user.inGameUid,
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
      captainName: user.inGameName,
      maxSize: teamMaxSize,
      teamName: teamName.isNotEmpty ? teamName : 'Team $teamCode',
      members: [teamMember],
      createdAt: DateTime.now(),
    );

    match.registeredTeams.add(newTeam);

    final participant = MatchParticipant(
      uid: user.uid,
      inGameName: user.inGameName,
      inGameUid: user.inGameUid,
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

    String walletUsed = 'AD_COINS';
    double balBefore = 0;
    double balAfter = 0;

    // Deduct entry fee
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
      if (user.wallet.depositCash >= fee) {
        balBefore = user.wallet.depositCash;
        user.wallet.depositCash -= fee;
        balAfter = user.wallet.depositCash;
        walletUsed = 'DEPOSIT_CASH';
      } else if (user.wallet.depositCash + user.wallet.winningCash >= fee) {
        final fromDeposit = user.wallet.depositCash;
        final fromWinning = fee - fromDeposit;
        user.wallet.depositCash = 0;
        user.wallet.winningCash -= fromWinning;
        balBefore = fromDeposit + fromWinning;
        balAfter = user.wallet.winningCash;
        walletUsed = 'DEPOSIT_CASH';
      } else {
        return {
          'success': false,
          'message': 'Insufficient Cash! Entry fee is ₹${fee.toInt()}. Add cash via Razorpay.'
        };
      }
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
      inGameName: user.inGameName,
      inGameUid: user.inGameUid,
      isCaptain: false,
      slotNumber: assignedSlot,
      joinedAt: DateTime.now(),
      amountPaid: match.entryFee,
    );

    team.members.add(teamMember);

    final participant = MatchParticipant(
      uid: user.uid,
      inGameName: user.inGameName,
      inGameUid: user.inGameUid,
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
      inGameUid: inGameUid.isNotEmpty ? inGameUid : user.inGameUid,
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
    if (user.adTracker.dailyLimitRemaining <= 0) {
      return {
        'success': false,
        'coinAwarded': false,
        'message': 'Daily ad limit reached. Come back tomorrow!'
      };
    }

    user.adTracker.adsWatchedToday += 1;
    user.adTracker.dailyLimitRemaining -= 1;
    user.adTracker.adsWatchedSinceLastCoin += 1;
    user.adTracker.lastAdTimestamp = DateTime.now();

    bool coinAwarded = false;
    String message = 'Ad completed (${user.adTracker.adsWatchedSinceLastCoin}/3). Watch ${3 - user.adTracker.adsWatchedSinceLastCoin} more for 1 🟡 Ad Coin!';

    if (user.adTracker.adsWatchedSinceLastCoin >= 3) {
      user.adTracker.adsWatchedSinceLastCoin = 0;
      final balBefore = user.wallet.adCoins.toDouble();
      user.wallet.adCoins += 1;
      user.stats.totalCoinsEarned += 1;
      coinAwarded = true;
      message = '🎉 Milestone Reached! You earned +1 🟡 Ad Coin!';

      transactions.insert(
        0,
        TransactionModel(
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
        ),
      );

      _syncUser();
      _syncTransaction(transactions.first);
    }

    notifyListeners();
    return {
      'success': true,
      'coinAwarded': coinAwarded,
      'message': message,
    };
  }

  // --- DEPOSIT CASH VIA RAZORPAY & AUTO-CREDIT WALLET (SWGAYANBHUMI API) ---
  void depositCash(double amount, String paymentId, {double bonusCoins = 0}) {
    final balBefore = user.wallet.depositCash;
    user.wallet.depositCash += amount;

    final depositTxn = TransactionModel(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.uid,
      userName: user.displayName,
      type: TransactionType.deposit,
      walletAffected: WalletType.depositCash,
      amount: amount,
      currency: 'INR',
      balanceBefore: balBefore,
      balanceAfter: user.wallet.depositCash,
      status: 'SUCCESS',
      description: 'Added ₹${amount.toInt()} Real Cash via Razorpay ($paymentId)',
      createdAt: DateTime.now(),
    );
    transactions.insert(0, depositTxn);
    _syncTransaction(depositTxn);

    if (bonusCoins > 0) {
      final adBalBefore = user.wallet.adCoins.toDouble();
      user.wallet.adCoins += bonusCoins.toInt();
      user.stats.totalCoinsEarned += bonusCoins.toInt();

      final bonusTxn = TransactionModel(
        id: 'txn_bonus_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        userName: user.displayName,
        type: TransactionType.adReward,
        walletAffected: WalletType.adCoins,
        amount: bonusCoins,
        currency: 'AD_COINS',
        balanceBefore: adBalBefore,
        balanceAfter: user.wallet.adCoins.toDouble(),
        status: 'SUCCESS',
        description: '🎁 50% Instant Bonus: +${bonusCoins.toInt()} 🟡 Ad Coins on ₹${amount.toInt()} Recharge',
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
    _syncMatch(match);
    notifyListeners();
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

    // Distributable Prize Pool (70% for paid, totalPool for free)
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
    _syncMatch(newMatch);
    notifyListeners();
  }

  // --- ADMIN FINANCIAL & ECONOMY ANALYTICS ---
  Map<String, dynamic> get adminFinancialMetrics {
    // 💵 PAID MATCHES METRICS
    double totalDeposits = transactions
        .where((t) => t.type == TransactionType.deposit && t.status == 'SUCCESS')
        .fold(0.0, (sum, t) => sum + t.amount);

    double totalCashEntryFees = transactions
        .where((t) => t.type == TransactionType.matchEntryFee && t.walletAffected == WalletType.depositCash)
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

    double totalCashPrizesWon = transactions
        .where((t) => t.type == TransactionType.matchWinningCash && t.walletAffected == WalletType.winningCash)
        .fold(0.0, (sum, t) => sum + t.amount);

    final pendingList = withdrawals.where((w) => w.status == WithdrawalStatus.pending).toList();
    double totalPendingPayout = pendingList.fold(0.0, (sum, w) => sum + w.amount);

    double totalPaidOut = withdrawals
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

    double totalRewardCoinsIssued = transactions
        .where((t) => t.type == TransactionType.matchWinningRewardCoins)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Each Ad Coin requires 3 ads watched, plus direct ad watching
    int totalEstimatedAdsWatched = (totalAdCoinsCollected * 3).toInt() + user.adTracker.adsWatchedToday;
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

    int pendingVouchers = voucherClaims.where((v) => v.status == VoucherClaimStatus.pending).length;
    int deliveredVouchers = voucherClaims.where((v) => v.status == VoucherClaimStatus.delivered).length;

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
      'totalVouchersClaimed': voucherClaims.length,
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
  Future<void> _syncWithFirestore() async {
    isLiveSyncing = true;
    notifyListeners();

    try {
      // 1. Sync User Profile from AuthService local cache and Firestore
      final activeUser = await AuthService.getActiveUser();
      if (activeUser != null) {
        user = activeUser;
        isAuthenticated = true;
      }

      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString('saved_uid') ?? (activeUser?.uid);

      if (savedUid != null && savedUid.isNotEmpty) {
        try {
          final userDoc = await FirestoreRestService.getDocument(FirebaseConfig.usersCollection, savedUid);
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
      final matchDocs = await FirestoreRestService.getCollectionDocuments(FirebaseConfig.matchesCollection);
      if (matchDocs.isNotEmpty) {
        final firestoreMatches = matchDocs.map((d) => MatchModel.fromJson(d)).toList();
        matches = firestoreMatches;
      } else {
        matches = []; // Real live: empty if admin hasn't created any
      }

      // 3. Sync Transactions
      final txnDocs = await FirestoreRestService.getCollectionDocuments(FirebaseConfig.transactionsCollection);
      if (txnDocs.isNotEmpty) {
        transactions = txnDocs.map((d) => TransactionModel.fromJson(d)).toList();
      } else {
        transactions = [];
      }

      // 4. Sync Withdrawals
      final withDocs = await FirestoreRestService.getCollectionDocuments('skillwinner_withdrawals');
      if (withDocs.isNotEmpty) {
        withdrawals = withDocs.map((d) => WithdrawalModel.fromJson(d)).toList();
      } else {
        withdrawals = [];
      }

      // 5. Sync Voucher Claims
      final claimDocs = await FirestoreRestService.getCollectionDocuments('skillwinner_voucher_claims');
      if (claimDocs.isNotEmpty) {
        voucherClaims = claimDocs.map((d) => VoucherClaim.fromJson(d)).toList();
      } else {
        voucherClaims = [];
      }
    } catch (e) {
      debugPrint('[AppState] Firestore live sync error: $e');
    } finally {
      isLoadingAuth = false;
      isLiveSyncing = false;
      notifyListeners();
    }
  }

  void _syncUser() {
    AuthService.saveUser(user);
    FirestoreRestService.setDocument(FirebaseConfig.usersCollection, user.uid, user.toJson());
  }

  void _syncMatch(MatchModel m) {
    FirestoreRestService.setDocument(FirebaseConfig.matchesCollection, m.id, m.toJson());
  }

  void _syncTransaction(TransactionModel txn) {
    FirestoreRestService.setDocument(FirebaseConfig.transactionsCollection, txn.id, txn.toJson());
  }

  void _syncWithdrawal(WithdrawalModel w) {
    FirestoreRestService.setDocument('skillwinner_withdrawals', w.id, w.toJson());
  }

  void _syncVoucherClaim(VoucherClaim claim) {
    FirestoreRestService.setDocument('skillwinner_voucher_claims', claim.id, claim.toJson());
  }
}
