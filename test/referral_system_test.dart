import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:booyah_rewards/models/user_model.dart';
import 'package:booyah_rewards/models/referral_record.dart';
import 'package:booyah_rewards/services/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('🎁 Referral System & Security Verification Tests', () {
    test('1. UserModel generates valid 6-digit numeric referral code', () {
      final user1 = UserModel(
        uid: 'usr_player_99182',
        displayName: 'RacerPro',
        email: 'racer@booyah.com',
        phoneNumber: '+91 9876543210',
        wallet: UserWallet(adCoins: 5, rewardCoins: 0, depositCash: 0, winningCash: 0),
        adTracker: AdTracker(adsWatchedToday: 0, adsWatchedSinceLastCoin: 0, dailyLimitRemaining: 30),
        stats: UserStats(matchesPlayed: 0, matchesWon: 0, totalKills: 0, totalWinningsCash: 0, totalRewardCoinsWon: 0, totalCoinsEarned: 5),
      );

      expect(user1.referralCode, isNotEmpty);
      expect(user1.referralCode.length, equals(6));
      expect(int.tryParse(user1.referralCode), isNotNull);
      final codeNum = int.parse(user1.referralCode);
      expect(codeNum, greaterThanOrEqualTo(100000));
      expect(codeNum, lessThanOrEqualTo(999999));
    });

    test('2. Applying Referral Code credits 10 Bonus Cash + 10 Ad Coins to logged-in user', () async {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState();
      
      // Set an active logged-in user
      appState.user = UserModel(
        uid: 'usr_active_player_01',
        displayName: 'Karan FF',
        email: 'karan@booyah.com',
        phoneNumber: '+91 9876543210',
        inGameName: '⚡KARAN_OP⚡',
        inGameUid: '284719284',
        inGameLevel: 55,
        wallet: UserWallet(adCoins: 5, rewardCoins: 0, depositCash: 0, winningCash: 0),
        adTracker: AdTracker(adsWatchedToday: 0, adsWatchedSinceLastCoin: 0, dailyLimitRemaining: 30),
        stats: UserStats(matchesPlayed: 0, matchesWon: 0, totalKills: 0, totalWinningsCash: 0, totalRewardCoinsWon: 0, totalCoinsEarned: 5),
      );

      final initialBonus = appState.user.wallet.bonusCash;
      final initialAdCoins = appState.user.wallet.adCoins;

      const testRefCode = '849201';
      final result = await appState.applyReferralCode(testRefCode);

      expect(result['success'], isTrue);
      expect(appState.user.wallet.bonusCash, equals(initialBonus + 10.0));
      expect(appState.user.wallet.adCoins, equals(initialAdCoins + 10));
      expect(appState.user.referredBy, equals(testRefCode));
      expect(appState.allGlobalReferralRecords, isNotEmpty);
      
      final record = appState.allGlobalReferralRecords.first;
      expect(record.referrerCode, equals(testRefCode));
      expect(record.bonusCashAwarded, equals(10.0));
      expect(record.adCoinsAwarded, equals(10));
    });

    test('3. Leaderboard formula accurately counts Referrals in points', () {
      SharedPreferences.setMockInitialValues({});
      final appState = AppState();
      
      final testPlayer = UserModel(
        uid: 'usr_champ_01',
        displayName: 'Aman_OP',
        email: 'aman@booyah.com',
        phoneNumber: '+91 9988776655',
        totalReferrals: 5, // 5 referrals * 20 = 100 points
        wallet: UserWallet(adCoins: 50, rewardCoins: 0, depositCash: 0, winningCash: 150),
        adTracker: AdTracker(adsWatchedToday: 0, adsWatchedSinceLastCoin: 0, dailyLimitRemaining: 30),
        stats: UserStats(
          matchesPlayed: 10,
          matchesWon: 3, // 3 * 50 = 150 points
          totalKills: 8,  // 8 * 10 = 80 points
          totalWinningsCash: 150, // 150 * 2 = 300 points
          totalRewardCoinsWon: 0,
          totalCoinsEarned: 50,
        ),
      );

      // Expected Points: (8 * 10) + (3 * 50) + (150 * 2) + (5 * 20) = 80 + 150 + 300 + 100 = 630 points
      final leaderboard = appState.getWeeklyLeaderboard(filter: 'ALL', registeredUsers: [testPlayer]);
      final entry = leaderboard.firstWhere((e) => e.uid == testPlayer.uid);

      expect(entry.points, equals(630));
    });

    test('4. ReferralRecord model serializes and deserializes correctly', () {
      final now = DateTime.now();
      final record = ReferralRecord(
        id: 'ref_123456789',
        referrerUid: 'usr_ref_01',
        referrerName: 'Vipin Pro',
        referrerCode: '748291',
        referredUid: 'usr_friend_02',
        referredName: 'Rahul Gamer',
        createdAt: now,
        bonusCashAwarded: 10.0,
        adCoinsAwarded: 10,
      );

      final json = record.toJson();
      final restored = ReferralRecord.fromJson(json);

      expect(restored.id, equals('ref_123456789'));
      expect(restored.referrerCode, equals('748291'));
      expect(restored.referrerName, equals('Vipin Pro'));
      expect(restored.referredName, equals('Rahul Gamer'));
      expect(restored.bonusCashAwarded, equals(10.0));
      expect(restored.adCoinsAwarded, equals(10));
    });
  });
}
