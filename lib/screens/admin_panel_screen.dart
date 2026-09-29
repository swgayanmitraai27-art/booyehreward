import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/match_model.dart';
import '../models/withdrawal_model.dart';
import '../models/voucher_model.dart';
import '../models/banner_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/match_banner_image.dart';
import '../utils/url_launcher_util.dart';
import '../utils/image_url_resolver.dart';

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
  final TextEditingController _bannerTitleController = TextEditingController(text: '🔥 Free Fire Esports Championship - Win ₹500');
  final TextEditingController _bannerImgUrlController = TextEditingController(text: 'imgasest/brhomescreen .png');
  final TextEditingController _bannerClickUrlController = TextEditingController(text: 'https://t.me/swgayanmitra');

  // Telegram Support & Settings state
  final TextEditingController _telegramUrlController = TextEditingController();

  // Create Match state (100% Dynamic with 75/25 Financial Engine)
  final TextEditingController _matchTitleController = TextEditingController(text: '⚡ Free Fire Clash Squad Championship');
  final TextEditingController _matchBannerUrlController = TextEditingController(text: 'imgasest/cshomescreen.png');
  final TextEditingController _entryFeeController = TextEditingController(text: '50');
  final TextEditingController _maxSlotsController = TextEditingController(text: '8');

  // BR Specific Rank Prizes, Per Kill, and Distribution Mode
  String _brPrizeDistributionMode = 'top3'; // 'top3', 'top5', 'top10'
  final TextEditingController _firstPrizeController = TextEditingController(text: '500');
  final TextEditingController _secondPrizeController = TextEditingController(text: '200');
  final TextEditingController _thirdPrizeController = TextEditingController(text: '100');
  final TextEditingController _fourthPrizeController = TextEditingController(text: '0');
  final TextEditingController _fifthPrizeController = TextEditingController(text: '0');
  final TextEditingController _perKillController = TextEditingController(text: '10');

  MatchType newMatchType = MatchType.paid;
  GameType newGameType = GameType.freeFire;
  MatchMode newMatchMode = MatchMode.cs;
  TeamType newTeamType = TeamType.squad;
  MapType newMapType = MapType.bermuda;

  @override
  void initState() {
    super.initState();
    _telegramUrlController.text = widget.appState.telegramSupportUrl;
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
    _perKillController.dispose();
    super.dispose();
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard!')),
    );
  }

  void _autoCalculateBRPrizes() {
    final entryFee = double.tryParse(_entryFeeController.text) ?? 50;
    final totalPlayers = int.tryParse(_maxSlotsController.text) ?? 48;
    final totalPool = entryFee * totalPlayers;
    final distributablePrizePool = newMatchType == MatchType.paid ? (totalPool * 0.75) : (totalPool * 0.4);
    final perKill = double.tryParse(_perKillController.text) ?? 0;
    final maxKills = totalPlayers > 1 ? (totalPlayers - 1) : 0;
    final reservedKillPool = maxKills * perKill;
    final rankPool = (distributablePrizePool - reservedKillPool) > 0 ? (distributablePrizePool - reservedKillPool) : 0.0;

    if (_brPrizeDistributionMode == 'top3') {
      _firstPrizeController.text = (rankPool * 0.50).toInt().toString();
      _secondPrizeController.text = (rankPool * 0.30).toInt().toString();
      _thirdPrizeController.text = (rankPool * 0.20).toInt().toString();
      _fourthPrizeController.text = '0';
      _fifthPrizeController.text = '0';
    } else if (_brPrizeDistributionMode == 'top5') {
      _firstPrizeController.text = (rankPool * 0.40).toInt().toString();
      _secondPrizeController.text = (rankPool * 0.25).toInt().toString();
      _thirdPrizeController.text = (rankPool * 0.15).toInt().toString();
      _fourthPrizeController.text = (rankPool * 0.10).toInt().toString();
      _fifthPrizeController.text = (rankPool * 0.10).toInt().toString();
    } else {
      // top10
      _firstPrizeController.text = (rankPool * 0.30).toInt().toString();
      _secondPrizeController.text = (rankPool * 0.20).toInt().toString();
      _thirdPrizeController.text = (rankPool * 0.15).toInt().toString();
      _fourthPrizeController.text = (rankPool * 0.075).toInt().toString();
      _fifthPrizeController.text = (rankPool * 0.075).toInt().toString();
    }
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

          // 📊 FINANCIAL CARDS: 75/25 SPLIT & SEPARATED REVENUES
          _buildFinancialAnalyticsContainer(metrics),
          const SizedBox(height: 18),

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

              double rankPrize = 0;
              if (rank == 1) rankPrize = match.prizePool.firstPlace / teamSize;
              if (rank == 2) rankPrize = (match.prizePool.secondPlace ?? 0) / teamSize;
              if (rank == 3) rankPrize = (match.prizePool.thirdPlace ?? 0) / teamSize;
              if (rank == 4) rankPrize = (match.prizePool.fourthPlace ?? 0) / teamSize;
              if (rank == 5) rankPrize = (match.prizePool.fifthPlace ?? 0) / teamSize;

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
                              Text('• Est: ${isPaid ? '₹${totalEstimatedPrize.toInt()}' : '${totalEstimatedPrize.toInt()} 🎟️'}',
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
    final perKill = double.tryParse(_perKillController.text) ?? 0;

    final double totalRankPrizes = firstPrize + secondPrize + thirdPrize + fourthPrize + fifthPrize;
    final double maxKillCost = (totalPlayers > 1 ? (totalPlayers - 1) : 0) * perKill;
    final double totalEstimatedPayout = totalRankPrizes + maxKillCost;
    final bool isBRValid = newMatchMode != MatchMode.br || (totalEstimatedPayout <= distributablePrizePool + 0.5);

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

          // Match Type Toggle (Free vs Paid)
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('🟡 FREE MATCH (Ad Coins)'),
                  selected: newMatchType == MatchType.free,
                  onSelected: (val) {
                    setState(() {
                      newMatchType = MatchType.free;
                      _entryFeeController.text = '5';
                      _autoCalculateBRPrizes();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('💵 PAID MATCH (Real Cash 75/25)'),
                  selected: newMatchType == MatchType.paid,
                  onSelected: (val) {
                    setState(() {
                      newMatchType = MatchType.paid;
                      _entryFeeController.text = '50';
                      _autoCalculateBRPrizes();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

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
                        _autoCalculateBRPrizes();
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
                      } else {
                        _autoCalculateBRPrizes();
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

          // 3. ENTRY FEE & TOTAL PLAYERS (ANY NUMBER)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _entryFeeController,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    setState(() {
                      if (newMatchMode == MatchMode.br) _autoCalculateBRPrizes();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: newMatchType == MatchType.free ? 'Entry Fee (🟡 Ad Coins)' : 'Entry Fee (₹ Real Cash)',
                    prefixIcon: Icon(newMatchType == MatchType.free ? Icons.monetization_on : Icons.currency_rupee, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _maxSlotsController,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    setState(() {
                      if (newMatchMode == MatchMode.br) _autoCalculateBRPrizes();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Total Players (Slots)',
                    hintText: 'Any number: 2, 4, 8, 48, 50...',
                    prefixIcon: const Icon(Icons.group, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4. 75/25 FINANCIAL ENGINE LIVE CARD
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pie_chart, color: Colors.amber, size: 16),
                        SizedBox(width: 6),
                        Text('75/25 AUTOMATIC FINANCIAL ENGINE', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Text('Auto-Calculated', style: TextStyle(color: Colors.white54, fontSize: 9.5)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TOTAL POOL (100%)', style: TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.bold)),
                            Text(
                              newMatchType == MatchType.free ? '${totalPool.toInt()} 🟡' : '₹${totalPool.toInt()}',
                              style: AppTheme.gamingNumber(fontSize: 14, color: Colors.white),
                            ),
                            Text('$totalPlayers × ${entryFee.toInt()}', style: const TextStyle(color: Colors.white54, fontSize: 8)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('COMMISSION (25%)', style: TextStyle(color: Color(0xFF34D399), fontSize: 8.5, fontWeight: FontWeight.bold)),
                            Text(
                              newMatchType == MatchType.free ? 'Zero Loss' : '₹${adminCommission.toInt()}',
                              style: AppTheme.gamingNumber(fontSize: 14, color: const Color(0xFF34D399)),
                            ),
                            const Text('25% Platform Margin', style: TextStyle(color: Colors.white54, fontSize: 8)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PRIZE POOL (75%)', style: TextStyle(color: Colors.amber, fontSize: 8.5, fontWeight: FontWeight.bold)),
                            Text(
                              newMatchType == MatchType.free ? '${(totalPool * 0.4).toInt()} 🎟️' : '₹${distributablePrizePool.toInt()}',
                              style: AppTheme.gamingNumber(fontSize: 14, color: Colors.amber),
                            ),
                            const Text('75% Distributable', style: TextStyle(color: Colors.white54, fontSize: 8)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. SPECIFIC DISTRIBUTION RULES BY MODE
          if (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ...[
            // CS / Lone Wolf: Per Kill Disabled. Full 75% pool to winning team!
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
                      Text('CLASH SQUAD / LONE WOLF PRIZE RULE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Per Kill rewards are DISABLED for CS / Lone Wolf.\n'
                    '• Entire 75% Prize Pool (₹${distributablePrizePool.toInt()}) will be divided EQUALLY among winning team members (≈ ₹${(distributablePrizePool / ((totalPlayers / 2) > 0 ? (totalPlayers / 2) : 1)).toInt()} per player).',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF065F46)),
                  ),
                ],
              ),
            ),
          ] else ...[
            // BR (Full Map): Dynamic Rank Prizes + Optional Per Kill
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
                      const Text('BR PRIZE DISTRIBUTION MODE', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF475569))),
                      Text(
                        '75% Pool: ₹${distributablePrizePool.toInt()}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Distribution Mode Selector Chips
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('🏆 Top 3 (50/30/20)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          selected: _brPrizeDistributionMode == 'top3',
                          onSelected: (val) {
                            setState(() {
                              _brPrizeDistributionMode = 'top3';
                              _autoCalculateBRPrizes();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('🎖️ Top 5 (Esports)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          selected: _brPrizeDistributionMode == 'top5',
                          onSelected: (val) {
                            setState(() {
                              _brPrizeDistributionMode = 'top5';
                              _autoCalculateBRPrizes();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('🌟 Top 10 (Wide)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          selected: _brPrizeDistributionMode == 'top10',
                          onSelected: (val) {
                            setState(() {
                              _brPrizeDistributionMode = 'top10';
                              _autoCalculateBRPrizes();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _firstPrizeController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Rank 1 Prize (₹)',
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
                            labelText: 'Rank 2 Prize (₹)',
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
                            labelText: 'Rank 3 Prize (₹)',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fourthPrizeController,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Rank 4 Prize (₹)',
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
                            labelText: 'Rank 5 Prize (₹)',
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
                          onChanged: (v) {
                            setState(() {
                              _autoCalculateBRPrizes();
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Per Kill (₹)',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Validation check display
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isBRValid ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isBRValid ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        Icon(isBRValid ? Icons.check_circle : Icons.warning, size: 16, color: isBRValid ? const Color(0xFF047857) : Colors.red),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isBRValid
                                ? '✓ Valid: Rank Prizes (₹${totalRankPrizes.toInt()}) + Max Kills (₹${maxKillCost.toInt()}) are within 75% pool limit (₹${distributablePrizePool.toInt()}). If Duo/Squad, prize is divided equally by ${newTeamType == TeamType.duo ? 2 : (newTeamType == TeamType.squad ? 4 : 1)} members.'
                                : '⚠️ Warning: Total Payout (₹${totalEstimatedPayout.toInt()}) exceeds 75% pool limit (₹${distributablePrizePool.toInt()}). Please reduce rank prizes or per-kill amount.',
                            style: TextStyle(fontSize: 10, color: isBRValid ? const Color(0xFF065F46) : Colors.red, fontWeight: FontWeight.bold),
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
                  totalPool: newMatchType == MatchType.paid ? distributablePrizePool : totalPool * 0.4,
                  perKill: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? 0 : perKill,
                  firstPlace: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? distributablePrizePool : firstPrize,
                  secondPlace: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? null : secondPrize,
                  thirdPlace: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? null : thirdPrize,
                  fourthPlace: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? null : fourthPrize,
                  fifthPlace: (newMatchMode == MatchMode.cs || newMatchMode == MatchMode.loneWolf) ? null : fifthPrize,
                );

                final match = MatchModel(
                  id: 'match_${DateTime.now().millisecondsSinceEpoch}',
                  title: _matchTitleController.text.trim(),
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
                  matchTime: DateTime.now().add(const Duration(hours: 1)),
                  participants: [],
                );

                widget.appState.adminCreateMatch(match);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.winningGreen,
                    content: Text('Match created! 75% Pool: ₹${distributablePrizePool.toInt()} | 25% Platform Margin: ₹${adminCommission.toInt()}'),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle, size: 18),
              label: Text('CREATE TOURNAMENT MATCH', style: AppTheme.gamingTitle(fontSize: 13, color: Colors.white, isItalic: false)),
            ),
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
        const SizedBox(height: 20),

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
              hintText: 'e.g. imgasest/brhomescreen .png or https://images.unsplash.com/...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 6),

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
        title: const Text('Delete Match?'),
        content: Text('Are you sure you want to permanently delete "${match.title}" (ID: ${match.id}) from Firestore?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                if (selectedMatchIdForResult == match.id) selectedMatchIdForResult = null;
                if (selectedMatchIdForRoom == match.id) selectedMatchIdForRoom = null;
              });
              widget.appState.adminDeleteMatch(match.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red,
                  content: Text('Match "${match.title}" deleted from database.'),
                ),
              );
            },
            child: const Text('DELETE PERMANENTLY'),
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

