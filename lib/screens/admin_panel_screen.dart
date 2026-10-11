import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/match_model.dart';
import '../models/withdrawal_model.dart';
import '../models/voucher_model.dart';
import '../models/banner_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/app_state.dart';
import '../services/firestore_rest_service.dart';
import '../services/firebase_config.dart';
import '../theme/app_theme.dart';
import '../widgets/match_banner_image.dart';
import '../utils/url_launcher_util.dart';
import '../utils/image_url_resolver.dart';
import '../utils/universal_image_picker.dart';

class AdminPanelScreen extends StatefulWidget {
  final AppState appState;

  const AdminPanelScreen({super.key, required this.appState});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int activeSection = 0; // 0: Finance & Analytics, 1: Verification, 2: Results, 3: Room Publisher, 4: Withdrawals, 5: Store Claims, 6: Create Match, 7: Banners, 8: Settings
  int financeViewTab = 0; // 0: All Summary, 1: Paid (Real Cash), 2: Free (Ad Coins)
  String selectedLedgerDateFilter = 'All Time'; // 'All Time', 'Today', 'Last 7 Days', 'This Month'

  // Match Players Verification state
  String? selectedMatchIdForVerification;
  final TextEditingController _verificationSearchController = TextEditingController();

  // Result declaration state
  String? selectedMatchIdForResult;
  final Map<String, TextEditingController> killControllers = {};
  final Map<String, TextEditingController> rankControllers = {};

  // Room Publisher state
  String? selectedMatchIdForRoom;
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _roomPassController = TextEditingController();

  // Store Item Creation state
  final TextEditingController _storeTitleController = TextEditingController(text: '₹50 Google Play Redeem Code');
  final TextEditingController _storeImgUrlController = TextEditingController(text: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=300&auto=format&fit=crop&q=80');
  final TextEditingController _storeCoinPriceController = TextEditingController(text: '250');
  final TextEditingController _storeRewardValController = TextEditingController(text: '₹50 Code');

  // Dynamic Banners state
  final TextEditingController _bannerTitleController = TextEditingController(text: '🔥 Official Telegram Support & Daily Updates');
  final TextEditingController _bannerImgUrlController = TextEditingController(text: 'https://i.ibb.co/W43nNfnY/Chat-GPT-Image-Oct-7-2026-10-03-53-AM-1.png');
  final TextEditingController _bannerClickUrlController = TextEditingController(text: 'http://t.me/booyahrewardofficial');

  // Category Banners state
  final TextEditingController _brCategoryBannerController = TextEditingController(text: 'https://i.ibb.co/PvV4vz0X/brhomescreen.png');
  final TextEditingController _csCategoryBannerController = TextEditingController(text: 'https://i.ibb.co/S4qX9RW5/cshomescreen.png');
  final TextEditingController _lwCategoryBannerController = TextEditingController(text: 'https://i.ibb.co/9ktcjYSX/lonewolfhomescreen.png');

  // Telegram Support & Settings state
  final TextEditingController _telegramUrlController = TextEditingController();


  // Create Match state (100% Dynamic with 75/25 Financial Engine)
  final TextEditingController _matchTitleController = TextEditingController(text: '⚡ Free Fire Clash Squad Championship');
  final TextEditingController _matchBannerUrlController = TextEditingController(text: 'imgasest/cshomescreen.png');
  final TextEditingController _entryFeeController = TextEditingController(text: '50');
  final TextEditingController _maxSlotsController = TextEditingController(text: '8');

  // BR Specific Rank Prizes and Per Kill
  final TextEditingController _firstPrizeController = TextEditingController(text: '500');
  final TextEditingController _secondPrizeController = TextEditingController(text: '200');
  final TextEditingController _thirdPrizeController = TextEditingController(text: '100');
  final TextEditingController _fourthPrizeController = TextEditingController(text: '0');
  final TextEditingController _fifthPrizeController = TextEditingController(text: '0');
  final TextEditingController _sixthPrizeController = TextEditingController(text: '0');
  final TextEditingController _seventhPrizeController = TextEditingController(text: '0');
  final TextEditingController _eighthPrizeController = TextEditingController(text: '0');
  final TextEditingController _ninthPrizeController = TextEditingController(text: '0');
  final TextEditingController _tenthPrizeController = TextEditingController(text: '0');
  final TextEditingController _perKillController = TextEditingController(text: '10');
  bool _isRealCashPrizeForFree = true; // For Free Matches: Give Real Cash (₹) vs Store Coins
  DateTime _scheduledMatchDate = DateTime.now();
  TimeOfDay _scheduledMatchTime = TimeOfDay(hour: (DateTime.now().hour + 1) % 24, minute: 0);

  String _formatScheduledTime() {
    final hour = _scheduledMatchTime.hourOfPeriod == 0 ? 12 : _scheduledMatchTime.hourOfPeriod;
    final minute = _scheduledMatchTime.minute.toString().padLeft(2, '0');
    final period = _scheduledMatchTime.period == DayPeriod.am ? 'AM' : 'PM';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${_scheduledMatchDate.day} ${months[_scheduledMatchDate.month - 1]} ${_scheduledMatchDate.year} at ${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  MatchType newMatchType = MatchType.paid;
  GameType newGameType = GameType.freeFire;
  MatchMode newMatchMode = MatchMode.cs;
  TeamType newTeamType = TeamType.squad;
  MapType newMapType = MapType.bermuda;

  // Push Notification state
  final TextEditingController _notifTitleController = TextEditingController(text: '🔥 Mega Tournament Alert!');
  final TextEditingController _notifBodyController = TextEditingController(text: 'New High Prize Pool Match is LIVE! Join now and win real cash.');
  final TextEditingController _notifImageUrlController = TextEditingController();
  final TextEditingController _notifUserIdController = TextEditingController();
  final TextEditingController _notifUserSearchController = TextEditingController();
  String _notifTarget = 'all'; // 'all' | 'match' | 'user'
  String? _notifSelectedMatchId;
  String? _selectedTargetUserUid;
  List<UserModel> _registeredUsers = [];
  bool _isLoadingUsers = false;
  // Dynamic Tournament Modes Manager state
  final TextEditingController _modeKeyController = TextEditingController(text: 'CUSTOM_MODE');
  final TextEditingController _modeTitleController = TextEditingController(text: 'Custom Championship');
  final TextEditingController _modeBannerController = TextEditingController(text: 'https://i.ibb.co/PvV4vz0X/brhomescreen.png');
  final TextEditingController _modeSlotsController = TextEditingController(text: '48');
  String _modeSelectedBaseMode = 'br'; // 'br', 'cs', 'loneWolf'
  final TextEditingController _referralSearchController = TextEditingController();
  late TextEditingController _coinRateController;
  late TextEditingController _minWithdrawCoinsController;

  @override
  void initState() {
    super.initState();
    _telegramUrlController.text = widget.appState.telegramSupportUrl;
    _brCategoryBannerController.text = widget.appState.brCategoryBanner;
    _csCategoryBannerController.text = widget.appState.csCategoryBanner;
    _lwCategoryBannerController.text = widget.appState.lwCategoryBanner;
    _coinRateController = TextEditingController(text: widget.appState.coinToRupeeRate.toString());
    _minWithdrawCoinsController = TextEditingController(text: widget.appState.minWithdrawalCoins.toString());
    _fetchRegisteredUsers();
  }

  Future<void> _pickAndUploadImage(TextEditingController controller) async {
    try {
      final pickedData = await pickImageFromDevice();
      if (pickedData != null && pickedData.bytes.isNotEmpty) {
        final name = pickedData.name.isNotEmpty
            ? pickedData.name
            : 'banner_${DateTime.now().millisecondsSinceEpoch}.png';

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⏳ Uploading image directly to VPS...')),
        );
        final uploadedUrl = await widget.appState.uploadBannerImageFile(pickedData.bytes, name);
        if (uploadedUrl != null) {
          setState(() {
            controller.text = uploadedUrl;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.winningGreen,
              content: const Text('✅ Image uploaded successfully to VPS!'),
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Upload failed. Please check VPS connection.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _openVpsGalleryDialog(TextEditingController controller) async {
    showDialog(
      context: context,
      builder: (ctx) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: widget.appState.getUploadedGallery(),
          builder: (context, snapshot) {
            return AlertDialog(
              title: const Text('VPS Uploaded Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: SizedBox(
                width: double.maxFinite,
                height: 380,
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : (snapshot.data == null || snapshot.data!.isEmpty)
                        ? const Center(child: Text('No uploaded images found on VPS yet.\nUpload one first!'))
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.4,
                            ),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, i) {
                              final item = snapshot.data![i];
                              final url = item['url'].toString();
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    controller.text = url;
                                  });
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppTheme.winningGreen,
                                      content: Text('Selected: ${item['filename']}'),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber, width: 1.5),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, err, stack) => const Center(child: Icon(Icons.broken_image)),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<void> _fetchRegisteredUsers() async {
    if (!mounted) return;
    setState(() => _isLoadingUsers = true);
    try {
      final userDocs = await FirestoreRestService.getCollectionDocuments(FirebaseConfig.usersCollection);
      final users = userDocs.map((d) => UserModel.fromJson(d)).toList();
      users.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
      if (mounted) {
        setState(() {
          _registeredUsers = users;
          _isLoadingUsers = false;
          if (_selectedTargetUserUid == null && _registeredUsers.isNotEmpty) {
            _selectedTargetUserUid = _registeredUsers.first.uid;
            _notifUserIdController.text = _registeredUsers.first.uid;
          }
        });
      }
    } catch (e) {
      debugPrint('[AdminPanel] Error fetching registered users: $e');
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  @override
  void dispose() {
    for (var c in killControllers.values) {
      c.dispose();
    }
    for (var c in rankControllers.values) {
      c.dispose();
    }
    _verificationSearchController.dispose();
    _roomIdController.dispose();
    _roomPassController.dispose();
    _storeTitleController.dispose();
    _storeImgUrlController.dispose();
    _storeCoinPriceController.dispose();
    _storeRewardValController.dispose();
    _bannerTitleController.dispose();
    _bannerImgUrlController.dispose();
    _bannerClickUrlController.dispose();
    _telegramUrlController.dispose();
    _matchTitleController.dispose();
    _matchBannerUrlController.dispose();
    _entryFeeController.dispose();
    _maxSlotsController.dispose();
    _firstPrizeController.dispose();
    _secondPrizeController.dispose();
    _thirdPrizeController.dispose();
    _fourthPrizeController.dispose();
    _fifthPrizeController.dispose();
    _sixthPrizeController.dispose();
    _seventhPrizeController.dispose();
    _eighthPrizeController.dispose();
    _ninthPrizeController.dispose();
    _tenthPrizeController.dispose();
    _perKillController.dispose();
    _notifTitleController.dispose();
    _notifBodyController.dispose();
    _notifImageUrlController.dispose();
    _notifUserIdController.dispose();
    _referralSearchController.dispose();
    _coinRateController.dispose();
    _minWithdrawCoinsController.dispose();
    super.dispose();
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard!')),
    );
  }

  void _showDistributeWeeklyPrizesDialog() {
    final top3 = widget.appState.getWeeklyLeaderboard(filter: 'WEEKLY').take(3).toList();
    final seasonLabel = widget.appState.getWeeklySeasonLabel();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_events, color: Color(0xFFD97706), size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Distribute 450 🪙 Weekly Coins',
                style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Season: $seasonLabel',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            const Text(
              'The following Top 3 players will receive Winning Coins credited directly to their Winning Wallet:',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 10),
            ...top3.map((winner) {
              final prize = winner.rank == 1 ? '200 🪙' : (winner.rank == 2 ? '150 🪙' : '100 🪙');
              final badge = winner.rank == 1 ? '🥇' : (winner.rank == 2 ? '🥈' : '🥉');
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Text(badge, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            winner.inGameName ?? winner.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'UID: ${winner.uid} • ${winner.points} pts',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      prize,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF059669)),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            const Text(
              'Total Pool: 450 🪙 Winning Coins (Auto-deposited to Winning Coins balance)',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.appState.adminDistributeWeeklyLeaderboardPrizes();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF065F46),
                    content: Text('🎉 450 🪙 Weekly Championship Coins successfully distributed to Top 3 players!'),
                  ),
                );
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Distribute 450 🪙 Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final metrics = widget.appState.adminFinancialMetrics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin Title & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ORGANIZER CONTROL CENTER',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED), letterSpacing: 1.2),
                  ),
                  Text(
                    'Admin Dashboard & Finance',
                    style: AppTheme.gamingTitle(fontSize: 20),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('PRO ADMIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 🛡️ GOOGLE PLAY REVIEW SAFE MODE MASTER SWITCH
          _buildPlayStoreReviewSafeModeCard(),

          // 📊 FINANCIAL CARDS: 75/25 SPLIT & SEPARATED REVENUES
          _buildFinancialAnalyticsContainer(metrics),
          const SizedBox(height: 18),

          // 🚨 DYNAMIC AUTO-START EMERGENCY ALERTS (15-MIN COUNTDOWN)
          _buildAutoStartEmergencyAlerts(),

          // Action Navigation Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTabBtn(0, '📈 Finance & Analytics'),
                const SizedBox(width: 8),
                _buildTabBtn(1, '👥 Match Players & Room Verification'),
                const SizedBox(width: 8),
                _buildTabBtn(2, '🏆 Declare Results'),
                const SizedBox(width: 8),
                _buildTabBtn(3, '🔑 Room Publisher'),
                const SizedBox(width: 8),
                _buildTabBtn(4, '💵 Withdrawals (${metrics['pendingCount']})'),
                const SizedBox(width: 8),
                _buildTabBtn(5, '🎁 Store Claims (${metrics['pendingVoucherClaims']})'),
                const SizedBox(width: 8),
                _buildTabBtn(6, '➕ Create Match (75/25 Engine)'),
                const SizedBox(width: 8),
                _buildTabBtn(7, '📢 Banners & Slider (${widget.appState.banners.length})'),
                const SizedBox(width: 8),
                _buildTabBtn(8, '⚙️ Telegram & App Settings'),
                const SizedBox(width: 8),
                _buildTabBtn(9, '🔔 Push Notifications & FCM Broadcast'),
                const SizedBox(width: 8),
                _buildTabBtn(10, '🎮 Tournament Modes & Covers (${widget.appState.tournamentModes.length})'),
                const SizedBox(width: 8),
                _buildTabBtn(11, '🎁 Referral Attribution (${widget.appState.allGlobalReferralRecords.length})'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (activeSection == 0) _buildFinanceAndAnalyticsSection(),
          if (activeSection == 1) _buildMatchPlayersVerificationSection(),
          if (activeSection == 2) _buildResultDeclarationSection(),
          if (activeSection == 3) _buildRoomPublisherSection(),
          if (activeSection == 4) _buildWithdrawalsSection(),
          if (activeSection == 5) _buildStoreManagementSection(),
          if (activeSection == 6) _buildCreateMatchSection(),
          if (activeSection == 7) _buildBannersSection(),
          if (activeSection == 8) _buildSettingsSection(),
          if (activeSection == 9) _buildPushNotificationBroadcastSection(),
          if (activeSection == 10) _buildTournamentModesManagementSection(),
          if (activeSection == 11) _buildReferralLedgerSection(),
        ],
      ),
    );
  }

  // --- 🛡️ GOOGLE PLAY REVIEW SAFE MODE MASTER SWITCH WIDGET ---
  Widget _buildPlayStoreReviewSafeModeCard() {
    final isCashEnabled = widget.appState.isRealCashModeEnabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCashEnabled ? const Color(0xFF0F172A) : const Color(0xFF065F46),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCashEnabled ? const Color(0xFF3B82F6) : const Color(0xFF34D399),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isCashEnabled ? Colors.blue : Colors.green).withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isCashEnabled ? Icons.currency_rupee : Icons.shield_outlined,
                    color: isCashEnabled ? Colors.amberAccent : Colors.greenAccent,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCashEnabled ? 'REAL CASH & PAID MATCHES' : 'GOOGLE PLAY REVIEW SAFE MODE',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Switch(
                value: isCashEnabled,
                activeThumbColor: Colors.amberAccent,
                activeTrackColor: const Color(0xFF2563EB),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFF047857),
                onChanged: (val) async {
                  await widget.appState.adminSetRealCashMode(val);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: val ? const Color(0xFF2563EB) : const Color(0xFF047857),
                      content: Text(
                        val
                            ? '🚀 Real Cash & Paid Mode is now ON (4-Wallet & ₹ Matches visible)!'
                            : '🛡️ Play Store Review Safe Mode is now ON (Only Free Coins & Ads visible)!',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isCashEnabled
                ? '🟢 LIVE MODE ACTIVE: Full 4-Wallet Balance, Add Cash, Instant UPI Withdrawals, and Paid Tournaments are LIVE for all players.'
                : '🛡️ SAFE MODE ACTIVE: Play Store Review Compliant! Real Cash, Deposit Cash, ₹ Entry Fees, and UPI Withdrawals are completely HIDDEN. Users only see 2 Free Coins and Rewarded Ads.',
            style: TextStyle(
              fontSize: 11.5,
              color: isCashEnabled ? Colors.white70 : Colors.green.shade100,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // --- FINANCIAL ANALYTICS CONTAINER ---
  Widget _buildFinancialAnalyticsContainer(Map<String, dynamic> metrics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics, color: Colors.amber, size: 18),
                  SizedBox(width: 6),
                  Text(
                    '75/25 PLATFORM ECONOMY',
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${metrics['totalMatches']} Matches Total',
                  style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildFinanceSubTab(0, '📊 All Summary'),
              const SizedBox(width: 6),
              _buildFinanceSubTab(1, '💵 Paid Matches (₹)'),
              const SizedBox(width: 6),
              _buildFinanceSubTab(2, '🟡 Free Matches (Ads)'),
            ],
          ),
          const SizedBox(height: 14),

          if (financeViewTab == 0) _buildCombinedFinanceSummary(metrics),
          if (financeViewTab == 1) _buildPaidFinanceSummary(metrics),
          if (financeViewTab == 2) _buildFreeFinanceSummary(metrics),
        ],
      ),
    );
  }

  Widget _buildFinanceSubTab(int index, String label) {
    final isSelected = financeViewTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => financeViewTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber : Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isSelected ? Colors.black : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCombinedFinanceSummary(Map<String, dynamic> metrics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'TOTAL DEPOSITS',
                value: '₹${(metrics['totalDeposits'] as num).toInt()}',
                subtitle: 'Razorpay UPI Inflow',
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'TOTAL WINNERS',
                value: '${metrics['totalWinnersCount']}',
                subtitle: 'Paid & Free Winners',
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'PENDING PAYOUT',
                value: '₹${(metrics['totalPendingPayout'] as num).toInt()}',
                subtitle: '${metrics['pendingCount']} UPI Requests',
                color: const Color(0xFF34D399),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Organizer Net Profit (25% Commission + Ad Margin):',
                style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${(metrics['combinedNetProfit'] as num).toInt()}',
                style: AppTheme.gamingNumber(fontSize: 14, color: const Color(0xFF34D399)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaidFinanceSummary(Map<String, dynamic> metrics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'TOTAL CASH ENTRY',
                value: '₹${(metrics['totalCashEntryFees'] as num).toInt()}',
                subtitle: '${metrics['paidPlayersJoined']} Paid Players',
                color: const Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'PRIZES DISTRIBUTED',
                value: '₹${(metrics['totalCashPrizesWon'] as num).toInt()}',
                subtitle: '75% Distributable Pool',
                color: const Color(0xFFF472B6),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: '25% PLATFORM COMM.',
                value: '₹${(metrics['netCashMargin'] as num).toInt()}',
                subtitle: '25% Platform Margin',
                color: const Color(0xFF34D399),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Real Deposits: ₹${(metrics['totalDeposits'] as num).toInt()} | Completed UPI Payouts: ₹${(metrics['totalPaidOut'] as num).toInt()}',
              style: const TextStyle(color: Colors.white54, fontSize: 9.5),
            ),
            Text(
              '${metrics['paidMatchesCount']} Paid Matches',
              style: const TextStyle(color: Colors.amber, fontSize: 9.5, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFreeFinanceSummary(Map<String, dynamic> metrics) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'AD COINS COLLECTED',
                value: '🟡 ${metrics['totalAdCoinsCollected']}',
                subtitle: '${metrics['freePlayersJoined']} Free Players',
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'EST. ADMOB REVENUE',
                value: '₹${(metrics['estimatedAdRevenue'] as num).toStringAsFixed(1)}',
                subtitle: '${metrics['totalEstimatedAdsWatched']} Ads Watched',
                color: const Color(0xFF34D399),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                title: 'REWARD COINS GIVEN',
                value: '🎟️ ${metrics['totalRewardCoinsIssued']}',
                subtitle: 'Est. Cost: ₹${(metrics['estimatedRewardCost'] as num).toStringAsFixed(1)}',
                color: const Color(0xFFA78BFA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Net Ad Margin: ₹${(metrics['netAdMargin'] as num).toStringAsFixed(1)} (Free Matches: ${metrics['freeMatchesCount']})',
                style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              Text(
                'Store Claims: ${metrics['pendingVoucherClaims']} Pending / ${metrics['deliveredVoucherClaims']} Delivered',
                style: const TextStyle(color: Colors.white70, fontSize: 9.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(value, style: AppTheme.gamingNumber(fontSize: 16, color: Colors.white)),
          const SizedBox(height: 1),
          Text(subtitle, style: const TextStyle(fontSize: 8, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildTabBtn(int index, String label) {
    final isSelected = activeSection == index;
    return InkWell(
      onTap: () => setState(() => activeSection = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // --- 1. MATCH PLAYERS & ROOM VERIFICATION SECTION ---
  // ==========================================
  Widget _buildMatchPlayersVerificationSection() {
    final matches = widget.appState.matches;
    if (matches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.sports_esports_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('No matches created yet.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final selectedMatch = matches.firstWhere(
      (m) => m.id == (selectedMatchIdForVerification ?? matches.first.id),
      orElse: () => matches.first,
    );

    final searchQuery = _verificationSearchController.text.trim().toLowerCase();
    final filteredParticipants = selectedMatch.participants.where((p) {
      if (searchQuery.isEmpty) return true;
      return p.inGameName.toLowerCase().contains(searchQuery) ||
          p.inGameUid.toLowerCase().contains(searchQuery) ||
          p.uid.toLowerCase().contains(searchQuery) ||
          '#${p.slotNumber}'.contains(searchQuery);
    }).toList();

    final isPaid = selectedMatch.matchType == MatchType.paid;
    final totalPrizePool = isPaid ? selectedMatch.distributablePrizePool : selectedMatch.prizePool.totalPool;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Free Fire Intruder Room Notice
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user, color: Color(0xFF7C3AED), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ROOM INTRUDERS & PLAYERS VERIFICATION',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED), letterSpacing: 0.8),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: selectedMatch.status == MatchStatus.upcoming
                      ? Colors.blue.shade50
                      : (selectedMatch.status == MatchStatus.ongoing ? Colors.orange.shade50 : Colors.green.shade50),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  selectedMatch.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: selectedMatch.status == MatchStatus.upcoming
                        ? Colors.blue.shade800
                        : (selectedMatch.status == MatchStatus.ongoing ? Colors.orange.shade800 : Colors.green.shade800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Cross-check Free Fire Custom Room lobby with this list. If anyone is in the custom room whose UID / IGN is NOT in this list, kick them out directly from Free Fire room.',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
          ),
          const SizedBox(height: 14),

          // Match Selector Dropdown
          DropdownButtonFormField<String>(
            initialValue: selectedMatch.id,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Select Tournament Match',
              prefixIcon: const Icon(Icons.sports_esports, size: 20, color: Color(0xFF7C3AED)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: matches.map((m) {
              return DropdownMenuItem(
                value: m.id,
                child: Text(
                  '${m.title} [${m.mode.name.toUpperCase()} • ${m.teamType.name.toUpperCase()}] (${m.participants.length}/${m.maxSlots} Players)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                selectedMatchIdForVerification = val;
              });
            },
          ),
          const SizedBox(height: 12),

          // Summary Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildVerificationStatCard(
                  title: 'JOINED PLAYERS',
                  value: '${selectedMatch.participants.length} / ${selectedMatch.maxSlots}',
                  subtitle: '${selectedMatch.maxSlots - selectedMatch.participants.length} Slots Left',
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVerificationStatCard(
                  title: isPaid ? 'COLLECTED (₹)' : 'COINS (🟡)',
                  value: isPaid
                      ? '₹${selectedMatch.participants.fold(0.0, (s, p) => s + p.amountPaid).toInt()}'
                      : '🟡 ${selectedMatch.participants.fold(0.0, (s, p) => s + p.amountPaid).toInt()}',
                  subtitle: '${selectedMatch.entryFee.toInt()} Entry / Player',
                  color: const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVerificationStatCard(
                  title: '75% PRIZE POOL',
                  value: isPaid ? '₹${totalPrizePool.toInt()}' : '${totalPrizePool.toInt()} 🎟️',
                  subtitle: isPaid ? '25% Margin: ₹${selectedMatch.adminCommission.toInt()}' : 'Reward Coins',
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Bar & Copy All Actions Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _verificationSearchController,
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search by Free Fire UID, IGN, or Slot...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                    suffixIcon: _verificationSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _verificationSearchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: selectedMatch.participants.isEmpty
                    ? null
                    : () {
                        final uids = selectedMatch.participants.map((p) => p.inGameUid).join(', ');
                        _copy(uids, 'All Free Fire UIDs');
                      },
                icon: const Icon(Icons.copy_all, size: 16),
                label: const Text('COPY ALL UIDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Player List
          if (selectedMatch.participants.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'No players have registered for this match yet.\nWhen players join, their Free Fire UID & Name will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              ),
            )
          else if (filteredParticipants.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Text(
                'No player found matching "${_verificationSearchController.text.trim()}".',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredParticipants.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = filteredParticipants[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      // Slot Badge
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${p.slotNumber}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Player Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    p.inGameName,
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (p.teamName != null && p.teamName!.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: p.teamName == 'Team A' ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      p.teamName!,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: p.teamName == 'Team A' ? const Color(0xFF166534) : const Color(0xFF1E40AF),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Text('FF UID: ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                Text(
                                  p.inGameUid,
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED)),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _copy(p.inGameUid, 'UID ${p.inGameUid}'),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDE9FE),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.copy, size: 12, color: Color(0xFF7C3AED)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Paid: ${p.paidWith} (₹${p.amountPaid.toInt()}) • Joined: ${p.joinedAt.hour}:${p.joinedAt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),

                      // Verified Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 12, color: Color(0xFF059669)),
                            SizedBox(width: 4),
                            Text(
                              'VERIFIED',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(value, style: AppTheme.gamingNumber(fontSize: 14, color: const Color(0xFF0F172A))),
          const SizedBox(height: 1),
          Text(subtitle, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  // ==========================================
  // --- 2. RESULT DECLARATION (CS TEAM A/B vs BR DYNAMIC) ---
  // ==========================================
  Widget _buildResultDeclarationSection() {
    final matches = widget.appState.matches;
    final selectedMatch = matches.firstWhere(
      (m) => m.id == (selectedMatchIdForResult ?? matches.first.id),
      orElse: () => matches.first,
    );
    final isFree = selectedMatch.matchType == MatchType.free;
    final isCSorLW = selectedMatch.isTeamBasedMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCSorLW ? '⚡ CS / LONE WOLF: 1-CLICK TEAM WINNER' : '🏆 BR FULL MAP: DYNAMIC RANK & KILL RESULTS',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isFree ? Colors.amber.shade100 : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isFree ? 'Prize: 🎟️ Reward Coins' : 'Prize: 🏆 Winning Cash (75% Pool: ₹${selectedMatch.distributablePrizePool.toInt()})',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: isFree ? Colors.amber.shade900 : const Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedMatch.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Select Match to Declare Results',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: matches.map((m) {
                    return DropdownMenuItem(
                      value: m.id,
                      child: Text(
                        '${m.title} [${m.mode.name.toUpperCase()} • ${m.teamType.name.toUpperCase()}] (${m.participants.length} Players)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedMatchIdForResult = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                tooltip: 'Delete this match',
                icon: const Icon(Icons.delete_forever, size: 20),
                onPressed: () => _confirmDeleteMatch(context, selectedMatch),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- MODE SPECIFIC DECLARATION UI ---
          if (isCSorLW) ...[
            _buildCSTeamDeclarationUI(selectedMatch),
          ] else ...[
            _buildBRDynamicDeclarationUI(selectedMatch),
          ],
        ],
      ),
    );
  }

  // --- CS / LONE WOLF: TEAM A vs TEAM B 1-CLICK DECLARATION ---
  Widget _buildCSTeamDeclarationUI(MatchModel match) {
    final teamA = match.teamAParticipants;
    final teamB = match.teamBParticipants;
    final isPaid = match.matchType == MatchType.paid;
    final prizePool = isPaid ? match.distributablePrizePool : match.prizePool.totalPool;
    final teamCount = (match.maxSlots / 2).ceil();
    final prizePerPlayer = prizePool / (teamCount > 0 ? teamCount : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('75% DISTRIBUTABLE PRIZE POOL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
                  Text(
                    isPaid ? '₹${prizePool.toInt()} Real Cash' : '${prizePool.toInt()} 🎟️ Reward Coins',
                    style: AppTheme.gamingNumber(fontSize: 16, color: const Color(0xFF047857)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Text(
                  isPaid ? '₹${prizePerPlayer.toInt()} / Player' : '${prizePerPlayer.toInt()} 🎟️ / Player',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TEAM A
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield, size: 16, color: Color(0xFF16A34A)),
                        SizedBox(width: 4),
                        Text('TEAM A ROSTER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF16A34A))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (teamA.isEmpty)
                      const Text('No players joined Team A yet.', style: TextStyle(fontSize: 11, color: Colors.grey))
                    else
                      ...teamA.map((p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ${p.inGameName} (#${p.slotNumber})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    Text('  UID: ${p.inGameUid}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF047857), fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _copy(p.inGameUid, 'UID ${p.inGameUid}'),
                                      child: const Icon(Icons.copy, size: 11, color: Color(0xFF16A34A)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          widget.appState.adminDeclareCSTeamWinner(
                            matchId: match.id,
                            winningTeam: 'Team A',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF16A34A),
                              content: Text('🎉 TEAM A Declared Winner! ₹${prizePerPlayer.toInt()} distributed to each Team A player!'),
                            ),
                          );
                        },
                        child: const Text('TEAM A WON 🏆', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // TEAM B
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF93C5FD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 4),
                        Text('TEAM B ROSTER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF2563EB))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (teamB.isEmpty)
                      const Text('No players joined Team B yet.', style: TextStyle(fontSize: 11, color: Colors.grey))
                    else
                      ...teamB.map((p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ${p.inGameName} (#${p.slotNumber})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    Text('  UID: ${p.inGameUid}', style: const TextStyle(fontSize: 9.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _copy(p.inGameUid, 'UID ${p.inGameUid}'),
                                      child: const Icon(Icons.copy, size: 11, color: Color(0xFF2563EB)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          widget.appState.adminDeclareCSTeamWinner(
                            matchId: match.id,
                            winningTeam: 'Team B',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF2563EB),
                              content: Text('🎉 TEAM B Declared Winner! ₹${prizePerPlayer.toInt()} distributed to each Team B player!'),
                            ),
                          );
                        },
                        child: const Text('TEAM B WON 🏆', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- BR FULL MAP: DYNAMIC RANK + KILLS RESULTS ---
  Widget _buildBRDynamicDeclarationUI(MatchModel match) {
    final isPaid = match.matchType == MatchType.paid;
    final teamSize = match.teamSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Team Mode: ${match.teamType.name.toUpperCase()} (Team Size: $teamSize)',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
              ),
              Text(
                'Per Kill Reward: ${isPaid ? '₹${match.prizePool.perKill.toInt()}' : '${match.prizePool.perKill.toInt()} 🎟️'}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (match.participants.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text('No participants joined in this match yet.', style: TextStyle(color: Colors.grey, fontSize: 12))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: match.participants.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = match.participants[index];

              if (!killControllers.containsKey(p.uid)) {
                killControllers[p.uid] = TextEditingController(text: '0');
              }
              if (!rankControllers.containsKey(p.uid)) {
                rankControllers[p.uid] = TextEditingController(text: '${index + 1}');
              }

              final rank = int.tryParse(rankControllers[p.uid]?.text.trim() ?? '1') ?? 1;
              final kills = int.tryParse(killControllers[p.uid]?.text.trim() ?? '0') ?? 0;

              final isCashPrize = match.prizePool.isCashPrize || isPaid;
              final double rankPrize = match.getIndividualRankPrize(rank);
              final totalEstimatedPrize = rankPrize + (kills * match.prizePool.perKill);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                      child: Text('#${p.slotNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.inGameName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                          Row(
                            children: [
                              Text('UID: ${p.inGameUid}', style: const TextStyle(fontSize: 10, color: Color(0xFF047857), fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _copy(p.inGameUid, 'UID ${p.inGameUid}'),
                                child: const Icon(Icons.copy, size: 10, color: Color(0xFF047857)),
                              ),
                              const SizedBox(width: 6),
                              Text('• Est: ${isCashPrize ? '₹${totalEstimatedPrize.toInt()}' : '${totalEstimatedPrize.toInt()} 🎟️'}',
                                  style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: rankControllers[p.uid],
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() {}),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Rank',
                          labelStyle: const TextStyle(fontSize: 10),
                          contentPadding: const EdgeInsets.all(6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: killControllers[p.uid],
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() {}),
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Kills',
                          labelStyle: const TextStyle(fontSize: 10),
                          contentPadding: const EdgeInsets.all(6),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final results = <Map<String, dynamic>>[];

              for (var p in match.participants) {
                final rank = int.tryParse(rankControllers[p.uid]?.text.trim() ?? '1') ?? 1;
                final kills = int.tryParse(killControllers[p.uid]?.text.trim() ?? '0') ?? 0;

                results.add({
                  'participant': p,
                  'rank': rank,
                  'kills': kills,
                });
              }

              widget.appState.adminDeclareBRWinners(
                matchId: match.id,
                results: results,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Color(0xFF065F46),
                  content: Text('🎉 BR Results declared! Automatic team split and per-kill prizes credited to wallets!'),
                ),
              );
            },
            icon: const Icon(Icons.stars, size: 18),
            label: Text(
              'DISTRIBUTE PRIZES TO PLAYERS',
              style: AppTheme.gamingTitle(fontSize: 13, color: Colors.white, isItalic: false),
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. ROOM ID & PASSWORD PUBLISHER ---
  Widget _buildRoomPublisherSection() {
    final matches = widget.appState.matches;
    final selectedMatch = matches.firstWhere(
      (m) => m.id == (selectedMatchIdForRoom ?? matches.first.id),
      orElse: () => matches.first,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ROOM ID & PASSWORD UPDATER (10M BEFORE KICKOFF)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            initialValue: selectedMatch.id,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Select Match',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: matches.map((m) {
              return DropdownMenuItem(
                value: m.id,
                child: Text(m.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                selectedMatchIdForRoom = val;
                final m = matches.firstWhere((item) => item.id == val);
                _roomIdController.text = m.credentials.roomId;
                _roomPassController.text = m.credentials.roomPassword;
              });
            },
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _roomIdController,
            decoration: InputDecoration(
              labelText: 'Custom Room ID',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _roomPassController,
            decoration: InputDecoration(
              labelText: 'Custom Room Password',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_roomIdController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Room ID')));
                  return;
                }
                widget.appState.adminPublishRoomCredentials(
                  selectedMatch.id,
                  _roomIdController.text.trim(),
                  _roomPassController.text.trim(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: AppTheme.winningGreen, content: Text('Room Credentials Published to all participants!')),
                );
              },
              icon: const Icon(Icons.send, size: 16),
              label: Text('PUBLISH ROOM ID & PASSWORD', style: AppTheme.gamingTitle(fontSize: 13, color: Colors.white, isItalic: false)),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. WITHDRAWALS MANAGEMENT ---
  Widget _buildWithdrawalsSection() {
    final withdrawals = widget.appState.allGlobalWithdrawals.isNotEmpty 
        ? widget.appState.allGlobalWithdrawals 
        : widget.appState.withdrawals;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('REAL CASH (UPI) WITHDRAWAL REQUESTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
          const SizedBox(height: 10),

          if (withdrawals.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No withdrawal requests found.', style: TextStyle(color: Colors.grey, fontSize: 12))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: withdrawals.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final req = withdrawals[index];
                final isPending = req.status == WithdrawalStatus.pending;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPending ? Colors.amber.shade100 : (req.status == WithdrawalStatus.completed ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPending ? '⏳' : (req.status == WithdrawalStatus.completed ? '✅' : '❌'),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${req.userName} • ₹${req.amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Row(
                              children: [
                                Text('UPI: ${req.upiId}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _copy(req.upiId, 'UPI ID'),
                                  child: const Icon(Icons.copy, size: 12, color: Colors.blueAccent),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isPending) ...[
                        TextButton(
                          onPressed: () {
                            widget.appState.adminApproveWithdrawal(req.id, 'UTR-${DateTime.now().millisecondsSinceEpoch}', 'Paid via UPI');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal approved & marked paid!')));
                          },
                          child: const Text('APPROVE', style: TextStyle(color: AppTheme.winningGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        TextButton(
                          onPressed: () {
                            widget.appState.adminRejectWithdrawal(req.id, 'Incorrect UPI ID. Refunded to wallet.');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal rejected & refunded.')));
                          },
                          child: const Text('REJECT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: req.status == WithdrawalStatus.completed ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            req.status == WithdrawalStatus.completed ? 'PAID' : 'REJECTED',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: req.status == WithdrawalStatus.completed ? const Color(0xFF047857) : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- 4. STORE & WHATSAPP CLAIMS MANAGEMENT ---
  Widget _buildStoreManagementSection() {
    final claims = widget.appState.allGlobalVoucherClaims.isNotEmpty 
        ? widget.appState.allGlobalVoucherClaims 
        : widget.appState.voucherClaims;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PENDING WHATSAPP REWARD CLAIMS (DELIVER IN 2 HOURS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
          const SizedBox(height: 10),

          if (claims.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No store voucher claims yet.', style: TextStyle(color: Colors.grey, fontSize: 12))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: claims.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final claim = claims[index];
                final isPending = claim.status == VoucherClaimStatus.pending;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isPending ? Colors.amber.shade100 : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(isPending ? '🎁' : '✅', style: const TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${claim.userName} • ${claim.itemTitle}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            Row(
                              children: [
                                Text('WhatsApp: ${claim.whatsappNumber}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _copy(claim.whatsappNumber, 'WhatsApp Number'),
                                  child: const Icon(Icons.copy, size: 12, color: Colors.green),
                                ),
                              ],
                            ),
                            if (claim.inGameUid.isNotEmpty)
                              Text('FF UID: ${claim.inGameUid}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                          ],
                        ),
                      ),
                      if (isPending)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF047857),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            widget.appState.adminDeliverVoucher(claim.id, 'GP-CODE-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher marked as delivered via WhatsApp!')));
                          },
                          child: const Text('MARK DELIVERED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('DELIVERED', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                        ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 20),

          const Divider(),
          const SizedBox(height: 10),
          const Text('ADD NEW ITEM TO REWARDS STORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
          const SizedBox(height: 10),

          TextField(
            controller: _storeTitleController,
            decoration: InputDecoration(
              labelText: 'Item Title (e.g. ₹50 Google Play Code or 100 Diamonds)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _storeImgUrlController,
            decoration: InputDecoration(
              labelText: 'Image URL',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _storeCoinPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price in Reward Coins',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _storeRewardValController,
                  decoration: InputDecoration(
                    labelText: 'Reward Value',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final title = _storeTitleController.text.trim();
                final price = int.tryParse(_storeCoinPriceController.text.trim()) ?? 100;
                final img = _storeImgUrlController.text.trim();
                final val = _storeRewardValController.text.trim();

                widget.appState.adminAddStoreItem(
                  title: title,
                  description: 'Redeemable with Reward Coins. Delivery via WhatsApp in 2 hours.',
                  imageUrl: img,
                  coinPrice: price,
                  rewardValue: val,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: AppTheme.winningGreen, content: Text('New product added to Rewards Store!')),
                );
              },
              icon: const Icon(Icons.add_shopping_cart, size: 16),
              label: Text('ADD PRODUCT TO STORE', style: AppTheme.gamingTitle(fontSize: 13, color: Colors.white, isItalic: false)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // --- 6. CREATE MATCH (100% DYNAMIC 75/25 ENGINE) ---
  // ==========================================
  Widget _buildCreateMatchSection() {
    final entryFee = double.tryParse(_entryFeeController.text) ?? 50;
    final totalPlayers = int.tryParse(_maxSlotsController.text) ?? 8;

    // 75/25 Financial Engine Calculation
    final double totalPool = entryFee * totalPlayers;
    final double adminCommission = totalPool * 0.25; // 25% Admin Commission
    final double distributablePrizePool = totalPool * 0.75; // 75% Distributable Prize Pool

    // For BR mode: Calculate dynamic rank prizes total + per kill
    final firstPrize = double.tryParse(_firstPrizeController.text) ?? 0;
    final secondPrize = double.tryParse(_secondPrizeController.text) ?? 0;
    final thirdPrize = double.tryParse(_thirdPrizeController.text) ?? 0;
    final fourthPrize = double.tryParse(_fourthPrizeController.text) ?? 0;
    final fifthPrize = double.tryParse(_fifthPrizeController.text) ?? 0;
    final sixthPrize = double.tryParse(_sixthPrizeController.text) ?? 0;
    final seventhPrize = double.tryParse(_seventhPrizeController.text) ?? 0;
    final eighthPrize = double.tryParse(_eighthPrizeController.text) ?? 0;
    final ninthPrize = double.tryParse(_ninthPrizeController.text) ?? 0;
    final tenthPrize = double.tryParse(_tenthPrizeController.text) ?? 0;
    final perKill = double.tryParse(_perKillController.text) ?? 0;

    final double totalRankPrizes = firstPrize + secondPrize + thirdPrize + fourthPrize + fifthPrize + sixthPrize + seventhPrize + eighthPrize + ninthPrize + tenthPrize;
    final double maxKillCost = (totalPlayers > 1 ? (totalPlayers - 1) : 0) * perKill;
    final double totalEstimatedPayout = totalRankPrizes + maxKillCost;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DYNAMIC MATCH CREATION (75/25 ENGINE)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: newMatchType == MatchType.free ? Colors.amber.shade100 : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  newMatchType == MatchType.free ? '🟡 FREE AD MATCH' : '💵 PAID 75/25 ENGINE',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: newMatchType == MatchType.free ? Colors.amber.shade900 : const Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Match Title
          TextField(
            controller: _matchTitleController,
            decoration: InputDecoration(
              labelText: 'Match Title',
              hintText: 'e.g. ⚡ Clash Squad Pro / BR Solos',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // 1. MATCH MODE DROPDOWN (BR, CS, Lone Wolf)
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<MatchMode>(
                  initialValue: newMatchMode,
                  decoration: InputDecoration(
                    labelText: 'Match Mode',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: MatchMode.br, child: Text('🔥 BR (Full Map)')),
                    DropdownMenuItem(value: MatchMode.cs, child: Text('⚔️ Clash Squad (CS)')),
                    DropdownMenuItem(value: MatchMode.loneWolf, child: Text('🐺 Lone Wolf')),
                  ],
                  onChanged: (mode) {
                    setState(() {
                      newMatchMode = mode!;
                      if (mode == MatchMode.cs) {
                        _matchBannerUrlController.text = 'imgasest/cshomescreen.png';
                        _maxSlotsController.text = '8';
                        newTeamType = TeamType.squad;
                      } else if (mode == MatchMode.loneWolf) {
                        _matchBannerUrlController.text = 'imgasest/lonewolfhomescreen.png';
                        _maxSlotsController.text = '2';
                        newTeamType = TeamType.solo;
                      } else {
                        _matchBannerUrlController.text = 'imgasest/brhomescreen .png';
                        _maxSlotsController.text = '48';
                        newTeamType = TeamType.solo;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 2. TEAM TYPE DROPDOWN
              Expanded(
                child: DropdownButtonFormField<TeamType>(
                  initialValue: newTeamType,
                  decoration: InputDecoration(
                    labelText: 'Team Type',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: TeamType.solo,
                      child: Text(newMatchMode == MatchMode.br ? 'Solo' : 'Solo (1v1)'),
                    ),
                    DropdownMenuItem(
                      value: TeamType.duo,
                      child: Text(newMatchMode == MatchMode.br ? 'Duo (2 Players)' : 'Duo (2v2)'),
                    ),
                    DropdownMenuItem(
                      value: TeamType.squad,
                      child: Text(newMatchMode == MatchMode.br ? 'Squad (4 Players)' : 'Squad (4v4)'),
                    ),
                  ],
                  onChanged: (team) {
                    setState(() {
                      newTeamType = team!;
                      if (newMatchMode == MatchMode.cs) {
                        _maxSlotsController.text = team == TeamType.squad ? '8' : (team == TeamType.duo ? '4' : '2');
                      } else if (newMatchMode == MatchMode.loneWolf) {
                        _maxSlotsController.text = team == TeamType.solo ? '2' : (team == TeamType.duo ? '4' : '8');
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Game Version & Map
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<GameType>(
                  initialValue: newGameType,
                  decoration: InputDecoration(
                    labelText: 'Game Version',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: GameType.freeFire, child: Text('Free Fire')),
                    DropdownMenuItem(value: GameType.freeFireMax, child: Text('Free Fire MAX')),
                  ],
                  onChanged: (v) => setState(() => newGameType = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<MapType>(
                  initialValue: newMapType,
                  decoration: InputDecoration(
                    labelText: 'Map',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: MapType.bermuda, child: Text('Bermuda')),
                    DropdownMenuItem(value: MapType.purgatory, child: Text('Purgatory')),
                    DropdownMenuItem(value: MapType.kalahari, child: Text('Kalahari')),
                    DropdownMenuItem(value: MapType.alpine, child: Text('Alpine')),
                    DropdownMenuItem(value: MapType.nexterra, child: Text('NexTerra')),
                  ],
                  onChanged: (v) => setState(() => newMapType = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. ENTRY AD COINS & TOTAL PLAYERS
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _entryFeeController,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Entry Fee in Ad Coins (🟡)',
                    hintText: 'e.g. 1, 2, 5 (0 for Free)',
                    prefixIcon: const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxSlotsController,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Total Players (Slots)',
                    hintText: 'e.g. 2, 4, 8, 48...',
                    prefixIcon: const Icon(Icons.group, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Coin Presets: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                ActionChip(
                  label: const Text('0 (Free)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: () => setState(() => _entryFeeController.text = '0'),
                ),
                const SizedBox(width: 4),
                ActionChip(
                  label: const Text('🟡 1 Coin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: () => setState(() => _entryFeeController.text = '1'),
                ),
                const SizedBox(width: 4),
                ActionChip(
                  label: const Text('🟡 2 Coins', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: () => setState(() => _entryFeeController.text = '2'),
                ),
                const SizedBox(width: 4),
                ActionChip(
                  label: const Text('🟡 5 Coins', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: () => setState(() => _entryFeeController.text = '5'),
                ),
                const SizedBox(width: 4),
                ActionChip(
                  label: const Text('🟡 10 Coins', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: () => setState(() => _entryFeeController.text = '10'),
                ),
              ],
            ),
          ),
          // 4. MATCH SCHEDULE (DATE & TIME WITH AM / PM)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.access_time_filled, color: Color(0xFFD97706), size: 18),
                        SizedBox(width: 6),
                        Text(
                          'SCHEDULE MATCH TIME (AM / PM)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _formatScheduledTime(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _scheduledMatchDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (pickedDate != null) {
                            setState(() => _scheduledMatchDate = pickedDate);
                          }
                        },
                        icon: const Icon(Icons.calendar_month, size: 16),
                        label: Text(
                          '${_scheduledMatchDate.day}/${_scheduledMatchDate.month}/${_scheduledMatchDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: _scheduledMatchTime,
                          );
                          if (pickedTime != null) {
                            setState(() => _scheduledMatchTime = pickedTime);
                          }
                        },
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text(
                          '${_scheduledMatchTime.hourOfPeriod == 0 ? 12 : _scheduledMatchTime.hourOfPeriod}:${_scheduledMatchTime.minute.toString().padLeft(2, '0')} ${_scheduledMatchTime.period == DayPeriod.am ? 'AM' : 'PM'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Match Prize Type Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Match Prize Type:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                  ),
                ),
                ChoiceChip(
                  label: const Text('💵 Real Cash (₹)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  selected: _isRealCashPrizeForFree,
                  onSelected: (val) => setState(() => _isRealCashPrizeForFree = true),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('🎟️ Store Coins', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  selected: !_isRealCashPrizeForFree,
                  onSelected: (val) => setState(() => _isRealCashPrizeForFree = false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. MANUAL PRIZES BY MODE
          if (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ...[
            // CS / Lone Wolf: Full prize to winning team
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Color(0xFF047857)),
                      SizedBox(width: 6),
                      Text('CLASH SQUAD / LONE WOLF PRIZE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _firstPrizeController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: _isRealCashPrizeForFree ? 'Winning Team Total Prize (₹ Cash)' : 'Winning Team Total Prize (🎟️ Coins)',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Prize will be divided equally among members of the winning team.',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF065F46)),
                  ),
                ],
              ),
            ),
          ] else ...[
            // BR (Full Map): Manual Rank Prizes Top 1 to 10 + Optional Per Kill
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('MANUAL RANK PRIZES (TOP 1 TO 10)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
                      Text(
                        'Total Pool: ${_isRealCashPrizeForFree ? "₹" : ""}${totalEstimatedPayout.toInt()}${!_isRealCashPrizeForFree ? " 🎟️" : ""}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '💡 Enter prizes for as many ranks as you want (e.g. Top 3, Top 5, or Top 10). Leave unused ranks as 0.',
                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),

                  // Row 1: Rank 1, Rank 2, Rank 3
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstPrizeController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Rank 1 Prize (${_isRealCashPrizeForFree ? "₹" : "🎟️"})',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _secondPrizeController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Rank 2 Prize (${_isRealCashPrizeForFree ? "₹" : "🎟️"})',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _thirdPrizeController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Rank 3 Prize (${_isRealCashPrizeForFree ? "₹" : "🎟️"})',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 2: Rank 4, Rank 5, Rank 6
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fourthPrizeController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Rank 4 Prize (${_isRealCashPrizeForFree ? "₹" : "🎟️"})',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _fifthPrizeController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Rank 5 Prize (${_isRealCashPrizeForFree ? "₹" : "🎟️"})',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _sixthPrizeController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Rank 6 Prize (${_isRealCashPrizeForFree ? "₹" : "🎟️"})',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 3: Rank 7, Rank 8, Rank 9
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _seventhPrizeController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Rank 7 Prize (${_isRealCashPrizeForFree ? "₹" : "🎟️"})',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _eighthPrizeController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Rank 8 Prize (${_isRealCashPrizeForFree ? "₹" : "🎟️"})',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _ninthPrizeController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Rank 9 Prize (${_isRealCashPrizeForFree ? "₹" : "🎟️"})',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 4: Rank 10, Per Kill
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tenthPrizeController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Rank 10 Prize (${_isRealCashPrizeForFree ? "₹" : "🎟️"})',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _perKillController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Per Kill (${_isRealCashPrizeForFree ? "₹" : "🎟️"})',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Info box
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 16, color: Color(0xFF047857)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '✓ Total Prize Pool: ${_isRealCashPrizeForFree ? "₹" : ""}${totalEstimatedPayout.toInt()}${!_isRealCashPrizeForFree ? " 🎟️" : ""} (Ranks: ${totalRankPrizes.toInt()} + Max Kills: ${maxKillCost.toInt()}). If Duo/Squad, rank prize is divided equally by ${newTeamType == TeamType.duo ? 2 : (newTeamType == TeamType.squad ? 4 : 1)} members.',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF065F46), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Banner Image & Preview
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MATCH BANNER IMAGE:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
              Text('Size: 16:9 (1280x720 or 800x450 px)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _matchBannerUrlController,
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Banner Image Path or Online URL',
              hintText: 'e.g. imgasest/brhomescreen .png or https://images.unsplash.com/...',
              isDense: true,
              prefixIcon: const Icon(Icons.image, size: 18, color: Color(0xFF7C3AED)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 6),

          // Upload & Gallery Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.amberAccent,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _pickAndUploadImage(_matchBannerUrlController),
                  icon: const Icon(Icons.cloud_upload_rounded, size: 15),
                  label: const Text('UPLOAD TO VPS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openVpsGalleryDialog(_matchBannerUrlController),
                  icon: const Icon(Icons.photo_library_outlined, size: 15),
                  label: const Text('VPS GALLERY', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),


          // Quick Presets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Presets: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                ActionChip(
                  label: const Text('⚔️ Clash Squad', style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    setState(() {
                      _matchBannerUrlController.text = 'imgasest/cshomescreen.png';
                    });
                  },
                ),
                const SizedBox(width: 4),
                ActionChip(
                  label: const Text('🔥 BR Full Map', style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    setState(() {
                      _matchBannerUrlController.text = 'imgasest/brhomescreen .png';
                    });
                  },
                ),
                const SizedBox(width: 4),
                ActionChip(
                  label: const Text('🐺 Lone Wolf', style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    setState(() {
                      _matchBannerUrlController.text = 'imgasest/lonewolfhomescreen.png';
                    });
                  },
                ),
                const SizedBox(width: 4),
                ActionChip(
                  label: const Text('💎 Diamonds Glow', style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    setState(() {
                      _matchBannerUrlController.text = 'https://images.unsplash.com/photo-1563089145-599997674d42?w=800&auto=format&fit=crop&q=80';
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Live Banner Preview Box
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                MatchBannerImage(
                  bannerImage: _matchBannerUrlController.text.trim(),
                  height: 100,
                ),
                Positioned(
                  bottom: 6,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('LIVE PREVIEW', style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Create Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final bannerUrl = _matchBannerUrlController.text.trim();
                final resolvedBanner = await ImageUrlResolver.resolveDirectImageUrl(bannerUrl);

                final format = newMatchMode == MatchMode.cs
                    ? MatchFormat.cs4v4
                    : (newMatchMode == MatchMode.loneWolf
                        ? (newTeamType == TeamType.solo ? MatchFormat.loneWolf1v1 : MatchFormat.loneWolf2v2)
                        : (newTeamType == TeamType.duo ? MatchFormat.duo : (newTeamType == TeamType.squad ? MatchFormat.squad : MatchFormat.solo)));

                final prizePool = PrizePool(
                  totalPool: newMatchType == MatchType.paid
                      ? distributablePrizePool
                      : (totalEstimatedPayout > 0 ? totalEstimatedPayout : totalPool * 0.4),
                  perKill: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? 0 : perKill,
                  firstPlace: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? distributablePrizePool : firstPrize,
                  secondPlace: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? null : secondPrize,
                  thirdPlace: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? null : thirdPrize,
                  fourthPlace: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? null : fourthPrize,
                  fifthPlace: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? null : fifthPrize,
                  sixthPlace: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? null : sixthPrize,
                  seventhPlace: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? null : seventhPrize,
                  eighthPlace: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? null : eighthPrize,
                  ninthPlace: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? null : ninthPrize,
                  tenthPlace: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? null : tenthPrize,
                  isCashPrize: newMatchType == MatchType.paid || _isRealCashPrizeForFree,
                );

                final enteredTitle = _matchTitleController.text.trim();
                final finalTitle = enteredTitle.isNotEmpty
                    ? enteredTitle
                    : (newMatchMode == MatchMode.cs
                        ? '⚔️ Clash Squad ${newTeamType == TeamType.squad ? "4v4" : (newTeamType == TeamType.duo ? "2v2" : "1v1")} Showdown'
                        : (newMatchMode == MatchMode.loneWolf
                            ? '🐺 Lone Wolf ${newTeamType == TeamType.solo ? "1v1" : "2v2"} Duel'
                            : '🔥 Free Fire BR ${newTeamType.name.toUpperCase()} Battle'));

                final match = MatchModel(
                  id: 'match_${DateTime.now().millisecondsSinceEpoch}',
                  title: finalTitle,
                  bannerImage: resolvedBanner.isNotEmpty ? resolvedBanner : 'imgasest/cshomescreen.png',
                  gameType: newGameType,
                  mode: newMatchMode,
                  teamType: newTeamType,
                  matchFormat: format,
                  map: newMapType,
                  matchType: newMatchType,
                  entryFeeType: newMatchType == MatchType.free ? EntryFeeType.adCoins : EntryFeeType.cash,
                  entryFee: entryFee,
                  prizePool: prizePool,
                  maxSlots: totalPlayers,
                  filledSlots: 0,
                  credentials: MatchCredentials(roomId: '', roomPassword: '', isRevealed: false),
                  status: MatchStatus.upcoming,
                  matchTime: DateTime(
                    _scheduledMatchDate.year,
                    _scheduledMatchDate.month,
                    _scheduledMatchDate.day,
                    _scheduledMatchTime.hour,
                    _scheduledMatchTime.minute,
                  ),
                  participants: [],
                );

                widget.appState.adminCreateMatch(match);
                _matchTitleController.clear();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.winningGreen,
                    content: Text('Match "$finalTitle" created! 75% Pool: ₹${distributablePrizePool.toInt()} | 25% Platform Margin: ₹${adminCommission.toInt()}'),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle, size: 18),
              label: Text('CREATE TOURNAMENT MATCH', style: AppTheme.gamingTitle(fontSize: 13, color: Colors.white, isItalic: false)),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 14),

          // 🎮 LIVE TOURNAMENTS & MATCHES MANAGER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_esports, color: Color(0xFF7C3AED), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ACTIVE & CREATED MATCHES (${widget.appState.matches.length})',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Text(
                'Full Admin Control & Delete',
                style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.appState.matches.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('No tournaments found in system.', style: TextStyle(color: Colors.grey)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.appState.matches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final match = widget.appState.matches[index];
                final isFree = match.matchType == MatchType.free;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#${match.id}',
                                  style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isFree ? Colors.amber.shade100 : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isFree ? 'FREE' : 'PAID',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isFree ? Colors.amber.shade900 : const Color(0xFF065F46),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: match.status == MatchStatus.upcoming
                                      ? const Color(0xFFEFF6FF)
                                      : (match.status == MatchStatus.completed ? const Color(0xFFF3E8FF) : const Color(0xFFFEF2F2)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  match.status.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: match.status == MatchStatus.upcoming
                                        ? const Color(0xFF1D4ED8)
                                        : (match.status == MatchStatus.completed ? const Color(0xFF7C3AED) : Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Slots: ${match.filledSlots}/${match.maxSlots}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        match.title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Fee: ${isFree ? "${match.entryFee.toInt()} 🟡" : "₹${match.entryFee.toInt()}"} • Pool: ${isFree ? "${match.prizePool.totalPool.toInt()} 🎟️" : "₹${match.prizePool.totalPool.toInt()}"}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                          if (match.roomPublishedByAdminName != null && match.roomPublishedByAdminName!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• Host: ${match.roomPublishedByAdminName}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF7C3AED), fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Quick Action Buttons
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Delete Button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFF1F2),
                                foregroundColor: Colors.red,
                                elevation: 0,
                                side: const BorderSide(color: Color(0xFFFECDD3)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _confirmDeleteMatch(context, match),
                              icon: const Icon(Icons.delete_outline, size: 14),
                              label: const Text('Delete Match', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),

                            // Respawn Button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEFF6FF),
                                foregroundColor: const Color(0xFF2563EB),
                                elevation: 0,
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                widget.appState.adminRespawnMatch(match.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.winningGreen,
                                    content: Text('Match #${match.id} respawned with 0 slots for next round!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.refresh, size: 14),
                              label: const Text('Respawn (0 Slots)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),

                            // Reset Slots Button
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF475569),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                widget.appState.adminResetMatchSlots(match.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Match #${match.id} slots reset to 0.'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.clear_all, size: 14),
                              label: const Text('Reset Slots (0)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),

                            // Publish Room ID
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedMatchIdForRoom = match.id;
                                  activeSection = 3; // Jump to Room Publisher tab
                                });
                              },
                              icon: const Icon(Icons.key, size: 14, color: Colors.amber),
                              label: const Text('Publish Room ID', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================
  // --- 0. FINANCE & ANALYTICS DASHBOARD & IMMUTABLE MATCH LEDGER ---
  // ==========================================
  Widget _buildFinanceAndAnalyticsSection() {
    final aggregates = widget.appState.getFinancialAggregates(selectedLedgerDateFilter);
    final completedMatches = widget.appState.getCompletedMatchesByFilter(selectedLedgerDateFilter);

    final double totalNetProfit = aggregates['totalNetProfit'] ?? 0;
    final double founderTotal = aggregates['founderTotal'] ?? 0;
    final double hostTotal = aggregates['hostTotal'] ?? 0;
    final double investorTotal = aggregates['investorTotal'] ?? 0;
    final double totalCollection = aggregates['totalCollection'] ?? 0;
    final double grossCommission = aggregates['grossCommission'] ?? 0;
    final double gatewayFees = aggregates['gatewayFees'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Section Banner & Date Range Filter
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AUTOMATED PROFIT SHARING & LEDGER',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Financial Dashboard',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, color: Color(0xFF059669), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${completedMatches.length} Settled Matches',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Date Range Filter Bar
              Row(
                children: [
                  const Text(
                    'Filter Period: ',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildLedgerDateFilterChip('All Time'),
                          const SizedBox(width: 6),
                          _buildLedgerDateFilterChip('Today'),
                          const SizedBox(width: 6),
                          _buildLedgerDateFilterChip('Last 7 Days'),
                          const SizedBox(width: 6),
                          _buildLedgerDateFilterChip('This Month'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 💰 USER REAL MONEY INFLOW & TOTAL DEPOSITS STATS
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6366F1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance, color: Color(0xFFA5B4FC), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'LIFETIME USER REAL MONEY INFLOW (DEPOSITS)',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFFA5B4FC), letterSpacing: 1),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('RAZORPAY UPI / GATEWAY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL CASH DEPOSITED', style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, color: Colors.white70, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${((widget.appState.adminFinancialMetrics['totalDeposits'] ?? 0) as num).toInt()}',
                          style: AppTheme.gamingNumber(fontSize: 20, color: const Color(0xFF38BDF8)),
                        ),
                        const Text('All users real cash loaded', style: TextStyle(fontSize: 8.5, color: Colors.white54)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ENTRY FEES COLLECTED', style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, color: Colors.white70, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${((widget.appState.adminFinancialMetrics['totalCashEntryFees'] ?? 0) as num).toInt()}',
                          style: AppTheme.gamingNumber(fontSize: 20, color: const Color(0xFFFBBF24)),
                        ),
                        const Text('Used in tournament entries', style: TextStyle(fontSize: 8.5, color: Colors.white54)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL PAID OUT (UPI)', style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, color: Colors.white70, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${((widget.appState.adminFinancialMetrics['totalPaidOut'] ?? 0) as num).toInt()}',
                          style: AppTheme.gamingNumber(fontSize: 20, color: const Color(0xFF34D399)),
                        ),
                        const Text('Completed user withdrawals', style: TextStyle(fontSize: 8.5, color: Colors.white54)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 4 TOP AGGREGATED METRIC CARDS
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 650;
            if (isWide) {
              return Row(
                children: [
                  Expanded(child: _buildTopMetricCard(
                    title: 'TOTAL NET PROFIT',
                    amount: totalNetProfit,
                    subtext: 'Gross ₹${grossCommission.toStringAsFixed(0)} (25%) - Fee ₹${gatewayFees.toStringAsFixed(1)}',
                    badge: 'LIFETIME / FILTERED',
                    gradientColors: [const Color(0xFF064E3B), const Color(0xFF065F46)],
                    icon: Icons.account_balance_wallet,
                    accentColor: const Color(0xFF34D399),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTopMetricCard(
                    title: 'FOUNDER EARNINGS (60%)',
                    amount: founderTotal,
                    subtext: '60% of Net Profit',
                    badge: '👑 FOUNDER',
                    gradientColors: [const Color(0xFF312E81), const Color(0xFF4338CA)],
                    icon: Icons.military_tech,
                    accentColor: const Color(0xFFA5B4FC),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTopMetricCard(
                    title: 'HOST EARNINGS (25%)',
                    amount: hostTotal,
                    subtext: '25% of Net Profit',
                    badge: '🎮 HOST/ADMIN',
                    gradientColors: [const Color(0xFF1E293B), const Color(0xFF334155)],
                    icon: Icons.sports_esports,
                    accentColor: const Color(0xFF38BDF8),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTopMetricCard(
                    title: 'INVESTOR EARNINGS (15%)',
                    amount: investorTotal,
                    subtext: '15% of Net Profit',
                    badge: '📈 INVESTOR',
                    gradientColors: [const Color(0xFF78350F), const Color(0xFF92400E)],
                    icon: Icons.trending_up,
                    accentColor: const Color(0xFFFBBF24),
                  )),
                ],
              );
            } else {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTopMetricCard(
                        title: 'TOTAL NET PROFIT',
                        amount: totalNetProfit,
                        subtext: 'Gross ₹${grossCommission.toStringAsFixed(0)} - Fee ₹${gatewayFees.toStringAsFixed(1)}',
                        badge: 'NET PROFIT',
                        gradientColors: [const Color(0xFF064E3B), const Color(0xFF065F46)],
                        icon: Icons.account_balance_wallet,
                        accentColor: const Color(0xFF34D399),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTopMetricCard(
                        title: 'FOUNDER (60%)',
                        amount: founderTotal,
                        subtext: '60% Share',
                        badge: '👑 FOUNDER',
                        gradientColors: [const Color(0xFF312E81), const Color(0xFF4338CA)],
                        icon: Icons.military_tech,
                        accentColor: const Color(0xFFA5B4FC),
                      )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildTopMetricCard(
                        title: 'HOST (25%)',
                        amount: hostTotal,
                        subtext: '25% Share',
                        badge: '🎮 HOST',
                        gradientColors: [const Color(0xFF1E293B), const Color(0xFF334155)],
                        icon: Icons.sports_esports,
                        accentColor: const Color(0xFF38BDF8),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTopMetricCard(
                        title: 'INVESTOR (15%)',
                        amount: investorTotal,
                        subtext: '15% Share',
                        badge: '📈 INVESTOR',
                        gradientColors: [const Color(0xFF78350F), const Color(0xFF92400E)],
                        icon: Icons.trending_up,
                        accentColor: const Color(0xFFFBBF24),
                      )),
                    ],
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 14),

        // Formula Explain Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Color(0xFF475569)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Formula: Total Collection (₹${totalCollection.toStringAsFixed(0)}) ➔ Gross Platform Comm (25%) - Razorpay Fee (2.36%) = Net Profit (100%) ➔ [Founder: 60% | Host: 25% | Investor: 15%]',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 👥 MULTI-ADMIN & HOST PROFIT COMMISSION LEADERBOARD (25% PROFIT SHARE)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF312E81),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.people_alt, color: Color(0xFFA5B4FC), size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ADMIN & HOST COMMISSION ATTRIBUTION',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF64748B),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Host Admin Profit Earnings (25%)',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Text(
                      '⚡ Auto Wallet Credited',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Builder(
                builder: (context) {
                  final hostList = widget.appState.getAdminHostLeaderboard(registeredUsers: _registeredUsers);
                  if (hostList.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No admin host match activity yet.', style: TextStyle(color: Colors.grey))),
                    );
                  }
                  return Column(
                    children: hostList.map((host) {
                      final name = host['hostName'] as String;
                      final uid = host['hostUid'] as String;
                      final phone = (host['phoneNumber'] ?? '') as String;
                      final email = (host['email'] ?? '') as String;
                      final published = host['totalMatchesPublished'] as int;
                      final completed = host['totalMatchesCompleted'] as int;
                      final revenue = (host['totalRevenueGenerated'] as num).toDouble();
                      final commission = (host['totalHostCommissionEarned'] as num).toDouble();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFF0F172A),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A)),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4F46E5).withAlpha(30),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: const Color(0xFF4F46E5).withAlpha(100)),
                                            ),
                                            child: const Text(
                                              'HOST ADMIN',
                                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      InkWell(
                                        onTap: () => _copy(uid, 'Admin UID'),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'UID: $uid',
                                              style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                            ),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.copy, size: 11, color: Color(0xFF94A3B8)),
                                          ],
                                        ),
                                      ),
                                      if (phone.isNotEmpty || email.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          [if (phone.isNotEmpty) phone, if (email.isNotEmpty) email].join(' • '),
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+₹${commission.toStringAsFixed(2)}',
                                      style: AppTheme.gamingNumber(fontSize: 16.5, color: AppTheme.winningGreen),
                                    ),
                                    const Text(
                                      '25% Host Profit',
                                      style: TextStyle(fontSize: 9.5, color: Color(0xFF059669), fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 18, color: Color(0xFFE2E8F0)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '🚀 Published: $published  •  🏁 Completed: $completed',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                                ),
                                Text(
                                  'Revenue: ₹${revenue.toInt()}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 🏆 WEEKLY LEADERBOARD & ₹100 PRIZE DISTRIBUTION MANAGER
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.emoji_events, color: Colors.black, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WEEKLY CHAMPIONSHIP (450 🪙 POOL)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11.5, letterSpacing: 0.8),
                          ),
                          Text(
                            'Top 3 Players: 🥇 200 🪙 | 🥈 150 🪙 | 🥉 100 🪙',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _showDistributeWeeklyPrizesDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Distribute 450 🪙', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Builder(
                builder: (context) {
                  final top3 = widget.appState.getWeeklyLeaderboard(filter: 'WEEKLY').take(3).toList();
                  return Row(
                    children: top3.map((winner) {
                      final prize = winner.rank == 1 ? '200 🪙' : (winner.rank == 2 ? '150 🪙' : '100 🪙');
                      final crown = winner.rank == 1 ? '🥇' : (winner.rank == 2 ? '🥈' : '🥉');
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withAlpha(25)),
                          ),
                          child: Column(
                            children: [
                              Text(crown, style: const TextStyle(fontSize: 18)),
                              const SizedBox(height: 2),
                              Text(
                                winner.inGameName ?? winner.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                              ),
                              Text(
                                '${winner.points} pts',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$prize COINS',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 📅 DATE-WISE & DAILY FINANCIAL BREAKDOWN
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.date_range, color: Colors.amber, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DAY-BY-DAY ACCOUNTING LEDGER',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF64748B),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Daily Financial Ledger ($selectedLedgerDateFilter)',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Builder(
                builder: (context) {
                  final dailyList = widget.appState.getDateWiseFinancialLedger(selectedLedgerDateFilter);
                  if (dailyList.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('No daily entries found in "$selectedLedgerDateFilter".', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    );
                  }
                  return Column(
                    children: dailyList.map((day) {
                      final date = day['date'] as String;
                      final count = day['matchCount'] as int;
                      final collection = (day['totalCollection'] as num).toDouble();
                      final net = (day['netProfit'] as num).toDouble();
                      final founder = (day['founder60'] as num).toDouble();
                      final host = (day['host25'] as num).toDouble();
                      final investor = (day['investor15'] as num).toDouble();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.event_note, color: Colors.blueAccent, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      date,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$count Matches',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Net Profit: ₹${net.toStringAsFixed(2)}',
                                  style: AppTheme.gamingNumber(fontSize: 14, color: AppTheme.winningGreen),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: _buildLedgerStatItem(label: 'Collection', value: '₹${collection.toInt()}', valueColor: const Color(0xFF0F172A))),
                                Expanded(child: _buildLedgerStatItem(label: 'Founder (60%)', value: '₹${founder.toStringAsFixed(1)}', valueColor: const Color(0xFF4338CA))),
                                Expanded(child: _buildLedgerStatItem(label: 'Host (25%)', value: '₹${host.toStringAsFixed(1)}', valueColor: const Color(0xFF0284C7))),
                                Expanded(child: _buildLedgerStatItem(label: 'Investor (15%)', value: '₹${investor.toStringAsFixed(1)}', valueColor: const Color(0xFFD97706))),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // MATCH LEDGER (DATA TABLE & CHRONOLOGICAL HISTORY)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long, color: Colors.amber, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'IMMUTABLE MATCH LEDGER',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF64748B),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Completed Match History',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${completedMatches.length} Matches Found',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (completedMatches.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.history_toggle_off, size: 40, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 8),
                      Text(
                        'No completed matches in "$selectedLedgerDateFilter"',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Declare results in the "Declare Results" tab to automatically settle profits here.',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Chronological Match Ledger List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completedMatches.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final match = completedMatches[index];
                    final fb = match.financialBreakdown ?? FinancialBreakdown.calculate(totalCollection: match.totalCollection);
                    final dt = match.completedAt ?? match.matchTime;
                    final formattedDate = '${dt.day.toString().padLeft(2, '0')} ${_monthName(dt.month)} ${dt.year}, ${_formatTime(dt)}';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Header: Date, Match ID, Status Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 12, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'ID: #${match.id.substring(match.id.length > 8 ? match.id.length - 8 : 0)}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle, size: 10, color: Color(0xFF059669)),
                                    SizedBox(width: 3),
                                    Text(
                                      'COMPLETED',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF065F46),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Match Title & Host Name
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  match.title,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Text(
                                'Host: ${match.hostName ?? 'Admin'}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Financial Breakdown Summary Row
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildLedgerStatItem(
                                  label: 'TOTAL ENTRY',
                                  value: '₹${fb.totalEntryCollection.toStringAsFixed(0)}',
                                  valueColor: const Color(0xFF0F172A),
                                ),
                                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                                _buildLedgerStatItem(
                                  label: 'GROSS (25%)',
                                  value: '₹${fb.platformCommissionGross.toStringAsFixed(1)}',
                                  valueColor: const Color(0xFF2563EB),
                                ),
                                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                                _buildLedgerStatItem(
                                  label: 'RZP FEE (2.36%)',
                                  value: '-₹${fb.gatewayFeeDeduction.toStringAsFixed(1)}',
                                  valueColor: const Color(0xFFDC2626),
                                ),
                                Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                                _buildLedgerStatItem(
                                  label: 'NET PROFIT',
                                  value: '₹${fb.netProfit.toStringAsFixed(2)}',
                                  valueColor: const Color(0xFF059669),
                                  isBold: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Profit Sharing Bar (Founder 60% | Host 25% | Investor 15%)
                          Row(
                            children: [
                              Expanded(
                                flex: 60,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFC7D2FE)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('👑 FOUNDER (60%)', style: TextStyle(fontFamily: 'Inter', fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF3730A3))),
                                      Text(
                                        '₹${fb.shares.founder60.toStringAsFixed(2)}',
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF312E81)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 25,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F9FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFBAE6FD)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('🎮 HOST (25%)', style: TextStyle(fontFamily: 'Inter', fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF0369A1))),
                                      Text(
                                        '₹${fb.shares.host25.toStringAsFixed(2)}',
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF075985)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 15,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFDE68A)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('📈 INVESTOR (15%)', style: TextStyle(fontFamily: 'Inter', fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                                      Text(
                                        '₹${fb.shares.investor15.toStringAsFixed(2)}',
                                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _showAuditReceiptDialog(match),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.receipt, color: Colors.amber, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- LEDGER DATE FILTER CHIP ---
  Widget _buildLedgerDateFilterChip(String label) {
    final isSelected = selectedLedgerDateFilter == label;
    return InkWell(
      onTap: () => setState(() => selectedLedgerDateFilter = label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFCBD5E1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // --- TOP AGGREGATED METRIC CARD ---
  Widget _buildTopMetricCard({
    required String title,
    required double amount,
    required String subtext,
    required String badge,
    required List<Color> gradientColors,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: gradientColors.first.withAlpha(40), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(badge, style: TextStyle(fontFamily: 'Inter', fontSize: 8, fontWeight: FontWeight.w900, color: accentColor)),
              ),
              Icon(icon, color: accentColor.withAlpha(180), size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Colors.white.withAlpha(180),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withAlpha(140),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- LEDGER STAT ITEM ---
  Widget _buildLedgerStatItem({
    required String label,
    required String value,
    required Color valueColor,
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            color: Color(0xFF64748B),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // --- AUDIT RECEIPT DIALOG MODAL ---
  void _showAuditReceiptDialog(MatchModel match) {
    final fb = match.financialBreakdown ?? FinancialBreakdown.calculate(totalCollection: match.totalCollection);
    final dt = match.completedAt ?? match.matchTime;
    final formattedDate = '${dt.day} ${_monthName(dt.month)} ${dt.year}, ${_formatTime(dt)}';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long, color: Color(0xFF059669), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Financial Audit Receipt',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              Text('Match: ${match.title}', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.bold)),
              Text('Match ID: ${match.id}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.grey)),
              Text('Settled At: $formattedDate', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.grey)),
              Text('Host/Admin: ${match.hostName ?? 'Admin'}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 14),

              // Firestore Document JSON Breakdown Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FIRESTORE DOCUMENT BREAKDOWN:', style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.amber, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    _buildJsonRow('status', '"COMPLETED"'),
                    _buildJsonRow('total_entry_collection', '₹${fb.totalEntryCollection.toStringAsFixed(2)}'),
                    _buildJsonRow('platform_commission_gross (25%)', '₹${fb.platformCommissionGross.toStringAsFixed(2)}'),
                    _buildJsonRow('gateway_fee_deduction (2.36%)', '₹${fb.gatewayFeeDeduction.toStringAsFixed(2)}'),
                    _buildJsonRow('net_profit', '₹${fb.netProfit.toStringAsFixed(2)}'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Divider(color: Colors.white24, height: 1),
                    ),
                    const Text('  "shares": {', style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Colors.white70)),
                    _buildJsonRow('    "founder_60"', '₹${fb.shares.founder60.toStringAsFixed(2)} (60%)', color: const Color(0xFFA5B4FC)),
                    _buildJsonRow('    "host_25"', '₹${fb.shares.host25.toStringAsFixed(2)} (25%)', color: const Color(0xFF38BDF8)),
                    _buildJsonRow('    "investor_15"', '₹${fb.shares.investor15.toStringAsFixed(2)} (15%)', color: const Color(0xFFFDE68A)),
                    const Text('  }', style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CLOSE AUDIT RECEIPT', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // --- 6. PROMO BANNERS & SLIDER MANAGEMENT ---
  // ==========================================
  Widget _buildBannersSection() {
    final banners = widget.appState.banners;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROMO BANNERS & SLIDER',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED), letterSpacing: 1.2),
                  ),
                  Text(
                    'Dynamic Home Lobby Carousel',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${banners.length} ACTIVE',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Banners added here appear dynamically in the auto-sliding carousel at the top of the Home Lobby. When players click the banner, it opens the configured URL in a new tab.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 16),

          // Active Banners List
          const Text('ACTIVE CAROUSEL BANNERS:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
          const SizedBox(height: 8),

          if (banners.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text('No promo banners active. Add one below to display in lobby!', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: banners.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final banner = banners[index];

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      // Mini Thumbnail
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 80,
                          height: 48,
                          color: const Color(0xFF0F172A),
                          child: banner.imageUrl.startsWith('http')
                              ? Image.network(
                                  banner.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 20)),
                                )
                              : Image.asset(
                                  banner.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image, color: Colors.white54, size: 20)),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              banner.clickUrl,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF7C3AED)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Test Link Button
                      IconButton(
                        tooltip: 'Test Open URL',
                        icon: const Icon(Icons.open_in_new, size: 18, color: Color(0xFF64748B)),
                        onPressed: () => UrlLauncherUtil.openUrl(banner.clickUrl),
                      ),

                      // Delete Button
                      IconButton(
                        tooltip: 'Delete Banner',
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        onPressed: () {
                          widget.appState.adminDeleteBanner(banner.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Banner deleted from lobby & Firestore!')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 20),

          const Divider(),
          const SizedBox(height: 10),

          // Add Banner Form
          const Text('➕ ADD NEW LOBBY BANNER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
          const SizedBox(height: 10),

          TextField(
            controller: _bannerTitleController,
            decoration: InputDecoration(
              labelText: 'Banner Title / Headline',
              hintText: 'e.g. 🔥 Free Fire Esports Championship - Win ₹500',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _bannerImgUrlController,
            decoration: InputDecoration(
              labelText: 'Image Path or Online Image URL',
              hintText: 'e.g. imgasest/brhomescreen.png or https://images.unsplash.com/...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 6),

          // Upload & Gallery Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.amberAccent,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _pickAndUploadImage(_bannerImgUrlController),
                  icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                  label: const Text('UPLOAD BANNER TO VPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openVpsGalleryDialog(_bannerImgUrlController),
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('VPS GALLERY PICKER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Quick Presets for Image
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Presets: ', style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold)),
                ActionChip(
                  label: const Text('BR Cover', style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    setState(() {
                      _bannerImgUrlController.text = 'imgasest/brhomescreen .png';
                    });
                  },
                ),
                const SizedBox(width: 6),
                ActionChip(
                  label: const Text('CS Cover', style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    setState(() {
                      _bannerImgUrlController.text = 'imgasest/cshomescreen.png';
                    });
                  },
                ),
                const SizedBox(width: 6),
                ActionChip(
                  label: const Text('Diamonds HD', style: TextStyle(fontSize: 10)),
                  onPressed: () {
                    setState(() {
                      _bannerImgUrlController.text = 'https://images.unsplash.com/photo-1563089145-599997674d42?w=800&auto=format&fit=crop&q=80';
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _bannerClickUrlController,
            decoration: InputDecoration(
              labelText: 'Click URL / Action Link',
              hintText: 'e.g. https://t.me/swgayanmitra or https://...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final title = _bannerTitleController.text.trim();
                final img = _bannerImgUrlController.text.trim();
                final url = _bannerClickUrlController.text.trim();

                if (title.isEmpty || img.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill title and image URL')),
                  );
                  return;
                }

                final resolvedImg = await ImageUrlResolver.resolveDirectImageUrl(img);

                final newBanner = BannerModel(
                  id: 'banner_${DateTime.now().millisecondsSinceEpoch}',
                  title: title,
                  imageUrl: resolvedImg,
                  clickUrl: url.isEmpty ? widget.appState.telegramSupportUrl : url,
                  createdAt: DateTime.now(),
                );

                widget.appState.adminAddBanner(newBanner);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppTheme.winningGreen,
                    content: Text('Promo banner added to Lobby & synced to Firestore!'),
                  ),
                );
              },
              icon: const Icon(Icons.add_photo_alternate, size: 18),
              label: Text('PUBLISH BANNER TO LOBBY', style: AppTheme.gamingTitle(fontSize: 13, color: Colors.white, isItalic: false)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // --- 7. TELEGRAM SUPPORT & APP SETTINGS ---
  // ==========================================
  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APP CONFIGURATION & SUPPORT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0284C7), letterSpacing: 1.2),
                  ),
                  Text(
                    'Official Telegram Support Settings',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '24/7 LIVE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'The Telegram customer support handle configured here is 100% dynamic and synced with Firestore (`skillwinner_settings/app_config`). Any time a player taps "💬 SUPPORT" in the top bar or wallet, they are taken directly to this Telegram ID/Channel.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 16),

          // Current Link display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CURRENT ACTIVE SUPPORT LINK:', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
                      Text(
                        widget.appState.telegramSupportUrl,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF14532D)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Input field
          TextField(
            controller: _telegramUrlController,
            decoration: InputDecoration(
              labelText: 'Telegram Support URL or Handle',
              hintText: 'e.g. https://t.me/swgayanmitra or @swgayanmitra',
              prefixIcon: const Icon(Icons.send_rounded, color: Color(0xFF0284C7)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 6),

          // Quick helper suggestions
          Row(
            children: [
              const Text('Suggestions: ', style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold)),
              ActionChip(
                label: const Text('@swgayanmitra', style: TextStyle(fontSize: 10)),
                onPressed: () {
                  setState(() {
                    _telegramUrlController.text = 'https://t.me/swgayanmitra';
                  });
                },
              ),
              const SizedBox(width: 6),
              ActionChip(
                label: const Text('Booyah Support Channel', style: TextStyle(fontSize: 10)),
                onPressed: () {
                  setState(() {
                    _telegramUrlController.text = 'https://t.me/booyahrewards';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final url = _telegramUrlController.text.trim();
                    if (url.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid Telegram URL')),
                      );
                      return;
                    }
                    widget.appState.adminUpdateTelegramUrl(url);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppTheme.winningGreen,
                        content: Text('Telegram Customer Support URL updated & synced to Firestore!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.cloud_done, size: 18),
                  label: const Text('SAVE TO FIRESTORE', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0284C7),
                  side: const BorderSide(color: Color(0xFF0284C7)),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => UrlLauncherUtil.openUrl(_telegramUrlController.text.trim()),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('TEST LINK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 14),

          // --- 🪙 WINNING COINS TO UPI CASH CONVERSION CONFIGURATION ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50.withAlpha(140),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text('🪙', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Text(
                          'WINNING COINS EXCHANGE RATE & MIN WITHDRAWAL',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '1000 Coins = ₹${(1000 * widget.appState.coinToRupeeRate).toInt()}',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Set how much Real Cash (₹) users receive when redeeming Winning Coins to UPI.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _coinRateController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Coin Rate (₹ per 1 Coin)',
                          hintText: 'e.g. 0.10 for ₹100 / 1000 coins',
                          prefixIcon: const Icon(Icons.currency_rupee, color: Colors.amber, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _minWithdrawCoinsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Min Withdrawal (Coins)',
                          hintText: 'e.g. 1000',
                          prefixIcon: const Icon(Icons.toll, color: Colors.amber, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Presets: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF78350F))),
                      ActionChip(
                        label: const Text('1000 Coins = ₹100 (₹0.10/coin)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () => setState(() => _coinRateController.text = '0.10'),
                      ),
                      const SizedBox(width: 4),
                      ActionChip(
                        label: const Text('1000 Coins = ₹50 (₹0.05/coin)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () => setState(() => _coinRateController.text = '0.05'),
                      ),
                      const SizedBox(width: 4),
                      ActionChip(
                        label: const Text('1000 Coins = ₹200 (₹0.20/coin)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () => setState(() => _coinRateController.text = '0.20'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final rate = double.tryParse(_coinRateController.text.trim()) ?? 0.10;
                      final minCoins = int.tryParse(_minWithdrawCoinsController.text.trim()) ?? 1000;
                      await widget.appState.adminUpdateCoinRate(rate, minCoins: minCoins);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppTheme.winningGreen,
                          content: Text('Winning Coin Rate updated: 1000 Coins = ₹${(1000 * rate).toInt()} (Min $minCoins Coins)!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('SAVE COIN RATE TO VPS & APP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 14),

          // --- 🎮 CATEGORY COVER BANNERS MANAGEMENT (BR, CS, LONE WOLF) ---
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CATEGORY MODE BANNERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0284C7), letterSpacing: 1.2)),
              Text('DIRECT VPS STORAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Configure or Upload custom banners for BR, Clash Squad, and Lone Wolf mode cards displayed in the lobby.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          const SizedBox(height: 14),

          // 1. BR Full Map Banner
          _buildCategoryBannerEditor(title: '🔥 Full Map (BR) Banner', controller: _brCategoryBannerController, modeKey: 'BR'),
          const SizedBox(height: 12),

          // 2. CS Clash Squad Banner
          _buildCategoryBannerEditor(title: '⚔️ Clash Squad (CS) Banner', controller: _csCategoryBannerController, modeKey: 'CS'),
          const SizedBox(height: 12),

          // 3. Lone Wolf Banner
          _buildCategoryBannerEditor(title: '🐺 Lone Wolf 1v1 Banner', controller: _lwCategoryBannerController, modeKey: 'LONE_WOLF'),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.amberAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final br = _brCategoryBannerController.text.trim();
                final cs = _csCategoryBannerController.text.trim();
                final lw = _lwCategoryBannerController.text.trim();
                await widget.appState.adminUpdateCategoryBanners(br: br, cs: cs, lw: lw);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppTheme.winningGreen,
                    content: Text('All Category Banners updated & synced in real-time!'),
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('SAVE ALL CATEGORY BANNERS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBannerEditor({required String title, required TextEditingController controller, required String modeKey}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Image Path or VPS URL',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.amberAccent,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => _pickAndUploadImage(controller),
                  icon: const Icon(Icons.cloud_upload_rounded, size: 14),
                  label: const Text('UPLOAD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => _openVpsGalleryDialog(controller),
                  icon: const Icon(Icons.photo_library_outlined, size: 14),
                  label: const Text('GALLERY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJsonRow(String key, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.white70)),
          Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.bold, color: color ?? Colors.white)),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1).clamp(0, 11)];
  }

  void _confirmDeleteMatch(BuildContext context, MatchModel match) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Cancel & Refund Match?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel "${match.title}" (ID: ${match.id})?'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Text('🟡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All ${match.participants.length} player(s) joined will automatically receive their 🟡 Ad Coins entry fee refunded back to their wallet!',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('NO, KEEP MATCH'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() {
                if (selectedMatchIdForResult == match.id) selectedMatchIdForResult = null;
                if (selectedMatchIdForRoom == match.id) selectedMatchIdForRoom = null;
              });
              final res = await widget.appState.adminCancelAndRefundMatch(match.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF065F46),
                    content: Text(res['message'] ?? 'Match cancelled and coins refunded!'),
                  ),
                );
                setState(() {});
              }
            },
            child: const Text('CANCEL MATCH & REFUND COINS'),
          ),
        ],
      ),
    );
  }

  // --- AUTO-START EMERGENCY ALERTS (15-MIN COUNTDOWN) ---
  Widget _buildAutoStartEmergencyAlerts() {
    final fullMatches = widget.appState.matches.where((m) => m.isFillingRoom).toList();
    if (fullMatches.isEmpty) return const SizedBox.shrink();

    return Column(
      children: fullMatches.map((m) {
        final remaining = m.roomCountdownRemaining;
        final minutes = remaining.inMinutes;
        final seconds = remaining.inSeconds % 60;
        final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withAlpha(100),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '🚨 DYNAMIC AUTO-START TRIGGERED (100% FULL)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, color: Colors.amberAccent, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Match "${m.title}" (${m.participants.length}/${m.maxSlots} Players) is FULL & Guaranteed Profitable! Please create the custom room and publish Room ID & Password within 15 minutes.',
                style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF991B1B),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() {
                      selectedMatchIdForRoom = m.id;
                      activeSection = 3; // Switch to Room Publisher tab
                      _roomIdController.text = m.credentials.roomId;
                      _roomPassController.text = m.credentials.roomPassword;
                    });
                  },
                  icon: const Icon(Icons.key, size: 16),
                  label: const Text(
                    'PUBLISH ROOM ID & PASSWORD NOW',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- 9. PUSH NOTIFICATIONS & FCM BROADCAST CENTER ---
  Widget _buildPushNotificationBroadcastSection() {
    final matches = widget.appState.matches;
    final notifications = widget.appState.allGlobalNotifications;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'REALTIME PUSH NOTIFICATIONS (FCM BROADCAST)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '⚡ CLOUD MESSAGING ACTIVE',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Target Audience Selector
          const Text('1. SELECT TARGET AUDIENCE:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('🌍 All Users', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: _notifTarget == 'all',
                  onSelected: (val) => setState(() => _notifTarget = 'all'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ChoiceChip(
                  label: const Text('🎮 Match Players', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: _notifTarget == 'match',
                  onSelected: (val) => setState(() => _notifTarget = 'match'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ChoiceChip(
                  label: const Text('👤 Single User', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: _notifTarget == 'user',
                  onSelected: (val) => setState(() => _notifTarget = 'user'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_notifTarget == 'match') ...[
            DropdownButtonFormField<String>(
              initialValue: _notifSelectedMatchId ?? (matches.isNotEmpty ? matches.first.id : null),
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Select Target Match',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: matches.map((m) {
                return DropdownMenuItem(
                  value: m.id,
                  child: Text('${m.title} (${m.participants.length} Players)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _notifSelectedMatchId = val),
            ),
            const SizedBox(height: 12),
          ],

          if (_notifTarget == 'user') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SELECT REGISTERED USER (${_registeredUsers.length}):',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
                      ),
                      InkWell(
                        onTap: _fetchRegisteredUsers,
                        child: Row(
                          children: [
                            if (_isLoadingUsers)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1D4ED8)),
                              )
                            else
                              const Icon(Icons.refresh, size: 14, color: Color(0xFF1D4ED8)),
                            const SizedBox(width: 4),
                            const Text('Refresh Users', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_isLoadingUsers && _registeredUsers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (_registeredUsers.isEmpty)
                    const Text('No users loaded. Click Refresh to load from database.', style: TextStyle(fontSize: 11, color: Colors.grey))
                  else ...[
                    // Search box for filtering user list
                    TextField(
                      controller: _notifUserSearchController,
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        hintText: 'Search user by Name, Email, Phone, IGN...',
                        hintStyle: const TextStyle(fontSize: 11),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (val) => setState(() {}),
                    ),
                    const SizedBox(height: 8),

                    // User Dropdown Selector
                    DropdownButtonFormField<String>(
                      value: _registeredUsers.any((u) => u.uid == _selectedTargetUserUid)
                          ? _selectedTargetUserUid
                          : (_registeredUsers.isNotEmpty ? _registeredUsers.first.uid : null),
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Choose Target User',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _registeredUsers
                          .where((u) {
                            final q = _notifUserSearchController.text.trim().toLowerCase();
                            if (q.isEmpty) return true;
                            final ign = u.inGameName?.toLowerCase() ?? '';
                            return u.displayName.toLowerCase().contains(q) ||
                                u.email.toLowerCase().contains(q) ||
                                u.phoneNumber.toLowerCase().contains(q) ||
                                ign.contains(q) ||
                                u.uid.toLowerCase().contains(q);
                          })
                          .map<DropdownMenuItem<String>>((UserModel u) {
                            final ign = (u.inGameName != null && u.inGameName!.isNotEmpty) ? u.inGameName! : (u.phoneNumber.isNotEmpty ? u.phoneNumber : u.email);
                            return DropdownMenuItem<String>(
                              value: u.uid,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFF1D4ED8),
                                    child: Text(
                                      u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : 'U',
                                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${u.displayName} ($ign)',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedTargetUserUid = val;
                            _notifUserIdController.text = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    // Highlighted Selected User Card Preview
                    if (_selectedTargetUserUid != null && _registeredUsers.any((u) => u.uid == _selectedTargetUserUid)) ...[
                      Builder(builder: (context) {
                        final selUser = _registeredUsers.firstWhere((u) => u.uid == _selectedTargetUserUid);
                        final ign = (selUser.inGameName != null && selUser.inGameName!.isNotEmpty) ? selUser.inGameName! : 'N/A';
                        final phone = selUser.phoneNumber.isNotEmpty ? selUser.phoneNumber : 'N/A';
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Target: ${selUser.displayName} | IGN: $ign',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A))),
                                    Text('Email: ${selUser.email} | Phone: $phone',
                                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF3B82F6))),
                                    Text('UID: ${selUser.uid}',
                                        style: const TextStyle(fontSize: 9, fontFamily: 'monospace', color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Presets
          const Text('2. QUICK TEMPLATES:', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ActionChip(
                  label: const Text('🔥 Mega Tournament', style: TextStyle(fontSize: 10.5)),
                  onPressed: () {
                    setState(() {
                      _notifTitleController.text = '🔥 Sunday Mega Esports Cup!';
                      _notifBodyController.text = 'Entry is open! 75% Prize pool ₹1,500 waiting. Join your squad now!';
                    });
                  },
                ),
                const SizedBox(width: 6),
                ActionChip(
                  label: const Text('🔑 Room ID Released', style: TextStyle(fontSize: 10.5)),
                  onPressed: () {
                    setState(() {
                      _notifTitleController.text = '🔑 Room ID & Pass Released!';
                      _notifBodyController.text = 'Your match Room ID is live. Open app & join Free Fire room immediately!';
                    });
                  },
                ),
                const SizedBox(width: 6),
                ActionChip(
                  label: const Text('🎁 10% Deposit Bonus', style: TextStyle(fontSize: 10.5)),
                  onPressed: () {
                    setState(() {
                      _notifTitleController.text = '🎁 10% Extra Deposit Cashback!';
                      _notifBodyController.text = 'Add cash via Razorpay UPI today and get 10% instant Bonus Cash!';
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Message Content
          TextField(
            controller: _notifTitleController,
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Notification Title',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _notifBodyController,
            onChanged: (v) => setState(() {}),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notification Message / Body',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _notifImageUrlController,
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Optional Image URL (Big Picture)',
              hintText: 'https://images.unsplash.com/...',
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),

          // Live Android Lockscreen Preview Mockup
          const Text('3. LIVE NOTIFICATION PREVIEW (ANDROID LOCKSCREEN):', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.notifications_active, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Booyah Rewards', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                          Text('now', style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 9.5)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _notifTitleController.text.isNotEmpty ? _notifTitleController.text : 'Notification Title',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _notifBodyController.text.isNotEmpty ? _notifBodyController.text : 'Notification Message Body...',
                        style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Send Push Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final title = _notifTitleController.text.trim();
                final body = _notifBodyController.text.trim();
                final img = _notifImageUrlController.text.trim();

                if (title.isEmpty || body.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter Title and Message!')),
                  );
                  return;
                }

                if (_notifTarget == 'all') {
                  await widget.appState.adminSendBroadcastNotification(
                    title: title,
                    body: body,
                    imageUrl: img.isNotEmpty ? img : null,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF047857),
                      content: Text('📢 Global Push Notification dispatched to ALL users!'),
                    ),
                  );
                } else if (_notifTarget == 'match') {
                  final targetMatchId = _notifSelectedMatchId ?? (matches.isNotEmpty ? matches.first.id : '');
                  if (targetMatchId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a match!')));
                    return;
                  }
                  await widget.appState.adminSendMatchNotification(
                    matchId: targetMatchId,
                    title: title,
                    body: body,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF047857),
                      content: Text('🎮 Match Push Notification dispatched to participants!'),
                    ),
                  );
                } else {
                  final targetUid = _selectedTargetUserUid ?? _notifUserIdController.text.trim();
                  if (targetUid.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a target User!')));
                    return;
                  }
                  await widget.appState.adminSendPersonalNotification(
                    userId: targetUid,
                    title: title,
                    body: body,
                    imageUrl: img.isNotEmpty ? img : null,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF047857),
                      content: Text('👤 Push Notification sent to user: $targetUid!'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _notifTarget == 'all'
                    ? 'DISPATCH BROADCAST TO ALL USERS'
                    : (_notifTarget == 'match' ? 'SEND ALERT TO MATCH PLAYERS' : 'SEND NOTIFICATION TO USER'),
                style: AppTheme.gamingTitle(fontSize: 12, color: Colors.white, isItalic: false),
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Divider(),
          const SizedBox(height: 10),
          const Text('RECENT DISPATCHED NOTIFICATIONS HISTORY:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
          const SizedBox(height: 10),

          if (notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: Text('No notifications recorded yet.', style: TextStyle(color: Colors.grey, fontSize: 11))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length.clamp(0, 10),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          notif.type == NotificationType.matchFull
                              ? Icons.alarm
                              : (notif.type == NotificationType.roomCredentials ? Icons.key : Icons.campaign),
                          size: 16,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(notif.body, style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Text(
                        '${notif.createdAt.hour.toString().padLeft(2, '0')}:${notif.createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================
  // --- 10. DYNAMIC TOURNAMENT MODES & COVERS ---
  // ==========================================
  Widget _buildTournamentModesManagementSection() {
    final modes = widget.appState.tournamentModes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DYNAMIC GAME MODES & FILTERS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED), letterSpacing: 1.2),
                  ),
                  Text(
                    'Tournament Modes & Cover Banners',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${modes.length} MODES',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Create new custom game modes (e.g. Gun Game, Custom Squad) with custom banners. Any mode created here automatically appears as a category banner and filter in the Home Lobby!',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 16),

          // 1. ACTIVE MODES LIST
          const Text('ACTIVE TOURNAMENT MODES:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
          const SizedBox(height: 10),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final modeItem = modes[index];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: modeItem.enabled ? const Color(0xFFCBD5E1) : Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Mode Banner Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 80,
                            height: 48,
                            color: const Color(0xFF0F172A),
                            child: MatchBannerImage(bannerImage: modeItem.bannerUrl, height: 48),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    modeItem.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDE9FE),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(modeItem.key, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Slots: ${modeItem.defaultSlots} Players | Base: ${modeItem.mode.toUpperCase()}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),

                        // Enable / Disable Switch
                        Switch(
                          value: modeItem.enabled,
                          activeColor: AppTheme.primaryAmber,
                          onChanged: (val) async {
                            final updated = modeItem.copyWith(enabled: val);
                            await widget.appState.adminSaveTournamentMode(updated);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Mode "${modeItem.title}" ${val ? "Enabled" : "Disabled"}!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 14),

          // 2. CREATE NEW MODE FORM
          const Text('➕ CREATE NEW TOURNAMENT MODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _modeTitleController,
                  decoration: InputDecoration(
                    labelText: 'Mode Display Title',
                    hintText: 'e.g. Gun Game (1v1) or Squad War',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _modeKeyController,
                  decoration: InputDecoration(
                    labelText: 'Mode Unique Key',
                    hintText: 'e.g. GUN_GAME or CS_CUSTOM',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _modeSelectedBaseMode,
                  decoration: InputDecoration(
                    labelText: 'Base Game Type',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'br', child: Text('Full Map Battle Royale (BR)')),
                    DropdownMenuItem(value: 'cs', child: Text('Clash Squad (CS 4v4)')),
                    DropdownMenuItem(value: 'loneWolf', child: Text('Lone Wolf (1v1 / 2v2)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _modeSelectedBaseMode = val);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _modeSlotsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Default Player Slots',
                    hintText: 'e.g. 48, 8, 2',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _modeBannerController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Mode Cover Banner Image URL',
              hintText: 'e.g. https://i.ibb.co/... or VPS Upload',
              prefixIcon: const Icon(Icons.image, color: Color(0xFF7C3AED)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 6),

          // Upload & Gallery Buttons for New Mode
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.amberAccent,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _pickAndUploadImage(_modeBannerController),
                  icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                  label: const Text('UPLOAD BANNER TO VPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openVpsGalleryDialog(_modeBannerController),
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('VPS GALLERY PICKER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Live Preview Box
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: MatchBannerImage(bannerImage: _modeBannerController.text.trim(), height: 90),
          ),
          const SizedBox(height: 16),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final key = _modeKeyController.text.trim().toUpperCase();
                final title = _modeTitleController.text.trim();
                final banner = _modeBannerController.text.trim();
                final slots = int.tryParse(_modeSlotsController.text.trim()) ?? 48;

                if (key.isEmpty || title.isEmpty || banner.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all mode details and banner URL!')),
                  );
                  return;
                }

                final newMode = TournamentModeItem(
                  key: key,
                  title: title,
                  bannerUrl: banner,
                  defaultSlots: slots,
                  mode: _modeSelectedBaseMode,
                  enabled: true,
                );

                await widget.appState.adminSaveTournamentMode(newMode);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.winningGreen,
                    content: Text('Tournament Mode "$title" created & published to Lobby!'),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('SAVE & PUBLISH MODE TO LOBBY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  // --- 🎁 11. REFERRAL ATTRIBUTION & BONUS LEDGER SECTION ---
  Widget _buildReferralLedgerSection() {
    final allReferrals = widget.appState.allGlobalReferralRecords;
    final query = _referralSearchController.text.trim().toLowerCase();

    final filtered = allReferrals.where((r) {
      if (query.isEmpty) return true;
      return r.referrerCode.toLowerCase().contains(query) ||
          r.referrerName.toLowerCase().contains(query) ||
          r.referrerUid.toLowerCase().contains(query) ||
          r.referredName.toLowerCase().contains(query) ||
          r.referredUid.toLowerCase().contains(query);
    }).toList();

    final totalReferrals = allReferrals.length;
    final totalBonusCash = allReferrals.fold(0.0, (sum, r) => sum + (r.bonusCashAwarded * 2));
    final totalAdCoins = allReferrals.fold(0, (sum, r) => sum + (r.adCoinsAwarded * 2));
    final uniqueReferrers = allReferrals.map((r) => r.referrerUid).toSet().length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.card_giftcard, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REFERRAL ATTRIBUTION LEDGER',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Track who referred whom, 6-digit codes & double bonus coins',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF059669).withAlpha(60)),
                ),
                child: Text(
                  'Total: $totalReferrals Referrals',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary Metric Cards
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.8,
            children: [
              _buildRefMetricBox('TOTAL REFERRALS', '$totalReferrals', Icons.people, Colors.blue),
              _buildRefMetricBox('ACTIVE REFERRERS', '$uniqueReferrers', Icons.stars, Colors.amber),
              _buildRefMetricBox('BONUS CASH ISSUED', '₹${totalBonusCash.toInt()}', Icons.currency_rupee, AppTheme.winningGreen),
              _buildRefMetricBox('AD COINS AWARDED', '$totalAdCoins 🟡', Icons.monetization_on, Colors.purple),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar
          TextField(
            controller: _referralSearchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by Referrer Code, User Name, or UID...',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
              suffixIcon: _referralSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _referralSearchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Referral List
          if (filtered.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.card_giftcard, size: 36, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 8),
                  Text(
                    query.isNotEmpty
                        ? 'No referral records match "$query"'
                        : 'No referrals recorded yet.\nUsers will appear here when they register using 6-digit referral codes.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final ref = filtered[i];
                final dateStr = '${ref.createdAt.day}/${ref.createdAt.month}/${ref.createdAt.year} ${_formatTime(ref.createdAt)}';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'CODE',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8)),
                            ),
                            Text(
                              ref.referrerCode,
                              style: const TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Referrer & Referee Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Inviter: ',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B)),
                                ),
                                Flexible(
                                  child: Text(
                                    ref.referrerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${ref.referrerUid})',
                                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Text(
                                  'Joined: ',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                                ),
                                Flexible(
                                  child: Text(
                                    ref.referredName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${ref.referredUid})',
                                  style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              dateStr,
                              style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),

                      // Reward Badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF059669).withAlpha(80)),
                            ),
                            child: const Text(
                              '+10₹ Bonus Each',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '+10 🟡 Ad Coins Each',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefMetricBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

