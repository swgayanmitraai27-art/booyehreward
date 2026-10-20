import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/match_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/slot_picker_dialog.dart';
import '../widgets/squad_team_dialog.dart';
import '../widgets/match_banner_image.dart';
import '../widgets/ff_brand_elements.dart';
import '../widgets/dynamic_banner_carousel.dart';
import '../widgets/admin_notice_board_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show AdSize;
import '../widgets/admob_banner_widget.dart';
import '../widgets/daily_login_popup_dialog.dart';
import '../widgets/interactive_user_guide_dialog.dart';

class TournamentLobbyScreen extends StatelessWidget {
  final AppState appState;
  final VoidCallback onEarnCoinsClick;
  final Function(int) onTabChange;

  const TournamentLobbyScreen({
    super.key,
    required this.appState,
    required this.onEarnCoinsClick,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final matches = appState.filteredMatches;
    final selectedMode = appState.selectedMode;
    final selectedTeamType = appState.selectedTeamType;
    final selectedFilter = appState.selectedFilter;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Auto-Sliding Promo & Announcement Carousel
          if (appState.activeBanners.isNotEmpty) ...[
            DynamicBannerCarousel(banners: appState.activeBanners),
            const SizedBox(height: 14),
          ],

          // 📢 Official Admin Notice & Live Community Board (Admin Message)
          AdminNoticeBoardWidget(appState: appState),
          const SizedBox(height: 12),

          // 🎁 Daily Login & Tasks Quick Access Card
          _buildDailyMissionsQuickCard(context),
          const SizedBox(height: 12),

          // 1. Hero Promo Card: 100% FREE ESPORTS & REAL REDEEM CODES (High-Retention Hindi)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withAlpha(25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with Free Fire Short Logo and 100% FREE BADGE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withAlpha(60),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 5),
                          Text(
                            '100% फ्री ऐप • 0₹ कोई पैसा नहीं लगेगा',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const FreeFireLogoInline(height: 16),
                  ],
                ),
                const SizedBox(height: 12),

                // Main Big Heading in Devanagari Hindi
                const Text(
                  '100% फ्री टूर्नामेंट्स खेलें!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD97706),
                    ),
                    children: [
                      TextSpan(text: '🎁 नए यूज़र्स को '),
                      TextSpan(
                        text: '5 फ्री Coins मिले हैं ',
                        style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w900),
                      ),
                      TextSpan(text: '• '),
                      TextSpan(
                        text: '📺 1 Ad = 1 Coin!',
                        style: TextStyle(color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Clear explanatory box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text(
                    'यहाँ एक भी रुपया जमा करने की ज़रूरत नहीं है! बस Ads (वीडियो) देखकर फ्री में Ad Coins लें, 100% फ्री मैच में एंट्री लें और Booyah करके असली Google Play Redeem Code जीतें!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: Color(0xFF475569),
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3 Quick Steps visual row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCD34D)),
                        ),
                        child: const Column(
                          children: [
                            Text('📺 Step 1', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFFB45309))),
                            SizedBox(height: 2),
                            Text('1 Ad = 1 Coin', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            Text('तुरंत Coin लें', style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Column(
                          children: [
                            Text('🎮 Step 2', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
                            SizedBox(height: 2),
                            Text('मैच खेलें', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            Text('100% फ्री एंट्री', style: TextStyle(fontSize: 8.5, color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                        ),
                        child: const Column(
                          children: [
                            Text('🎁 Step 3', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8))),
                            SizedBox(height: 2),
                            Text('कोड जीतें', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            Text('Real Redeem Code', style: TextStyle(fontSize: 8.5, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 📖 NEW PLAYER APP GUIDE CALLOUT BANNER
                InkWell(
                  onTap: () {
                    InteractiveUserGuideDialog.show(
                      context,
                      onGoToMatches: () => onTabChange(0),
                      onGoToEarnCoins: onEarnCoinsClick,
                      onGoToWallet: () => onTabChange(4),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withAlpha(30),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('📖', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Naye Player Ho? Kaise Khele Guide Dekhein!',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF78350F),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Yahan click karein aur sikhein matches khel kar paise kaise jeetein ➔',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: onEarnCoinsClick,
                      icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 16),
                      label: const Text(
                        '📺 Ads देखकर फ्री Coins लें',
                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900, fontSize: 11.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => onTabChange(1),
                      child: const Text(
                        'My Matches',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => onTabChange(2),
                      icon: const Text('🏆', style: TextStyle(fontSize: 12)),
                      label: Text(
                        appState.isRealCashModeEnabled ? '₹100 Ranks' : 'Leaderboard',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 🏆 WEEKLY CHAMPIONSHIP CALLOUT BANNER (₹100 PRIZE POOL)
          InkWell(
            onTap: () => onTabChange(2), // Leaderboard Tab
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A).withAlpha(150), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withAlpha(30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('🏆', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                appState.isRealCashModeEnabled ? '₹100 WEEKLY CASH POOL' : 'WEEKLY REWARDS POOL',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '• Ends Sunday',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Weekly Esports Championship',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          appState.isRealCashModeEnabled
                              ? 'Top 3 Players win ₹50, ₹30, ₹20 Cash! Check your live rank.'
                              : 'Top 3 Players win 500, 300, 200 Reward Coins! Check your live rank.',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFFCBD5E1)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.amber),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. MATCH CATEGORY BANNERS (Home Screen Banners with 12px border radius & soft drop shadows)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOURNAMENT MODES',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: 1.1,
                ),
              ),
              if (selectedMode != 'ALL')
                InkWell(
                  onTap: () => appState.setMode('ALL'),
                  child: const Text(
                    'View All Modes',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryAmber,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Grid / Row of the 3 Specific Mode Category Banners
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: appState.activeTournamentModes.map((modeItem) {
                final matchCount = appState.matches.where((m) {
                  if (modeItem.mode == 'cs') return m.mode == MatchMode.cs;
                  if (modeItem.mode == 'loneWolf') return m.mode == MatchMode.loneWolf;
                  return m.mode == MatchMode.br;
                }).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildCategoryBannerCard(
                    title: modeItem.title,
                    modeKey: modeItem.key,
                    assetPath: modeItem.bannerUrl,
                    isSelected: selectedMode == modeItem.key,
                    matchCount: matchCount,
                  ),
                );
              }).toList(),


            ),
          ),
          const SizedBox(height: 18),

          // 3. SUB-FILTERS: Team Type (All / Solo / Duo / Squad) & Free / Paid
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team Type Filter Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSubFilterChip(
                      label: 'All Formats',
                      isSelected: selectedTeamType == 'ALL',
                      onTap: () => appState.setTeamType('ALL'),
                    ),
                    const SizedBox(width: 6),
                    _buildSubFilterChip(
                      label: 'Solo (1v1)',
                      icon: Icons.person,
                      isSelected: selectedTeamType == 'SOLO',
                      onTap: () => appState.setTeamType('SOLO'),
                    ),
                    const SizedBox(width: 6),
                    _buildSubFilterChip(
                      label: 'Duo (2v2)',
                      icon: Icons.people,
                      isSelected: selectedTeamType == 'DUO',
                      onTap: () => appState.setTeamType('DUO'),
                    ),
                    const SizedBox(width: 6),
                    _buildSubFilterChip(
                      label: 'Squad (4v4)',
                      icon: Icons.groups,
                      isSelected: selectedTeamType == 'SQUAD',
                      onTap: () => appState.setTeamType('SQUAD'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Coin Economy Filter Row (All / WinCoin / Reward Coin)
              if (appState.isRealCashModeEnabled) ...[
                Row(
                  children: [
                    _buildEconomyChip('ALL', 'All Matches', null, selectedFilter == 'ALL'),
                    const SizedBox(width: 6),
                    _buildEconomyChip('WIN_COIN', 'Real Cash (₹)', '💵', selectedFilter == 'WIN_COIN'),
                    const SizedBox(width: 6),
                    _buildEconomyChip('REWARD_COIN', 'Free Matches', '🎟️', selectedFilter == 'REWARD_COIN'),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Match Status Row (ALL / UPCOMING / ONGOING / RESULTS)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusFilterChip('ALL', 'All Status', Icons.all_inclusive, appState.selectedStatus == 'ALL', () => appState.setStatusFilter('ALL')),
                    const SizedBox(width: 6),
                    _buildStatusFilterChip('UPCOMING', 'Upcoming 🕒', Icons.schedule, appState.selectedStatus == 'UPCOMING', () => appState.setStatusFilter('UPCOMING')),
                    const SizedBox(width: 6),
                    _buildStatusFilterChip('ONGOING', 'Live 🔴', Icons.sensors, appState.selectedStatus == 'ONGOING', () => appState.setStatusFilter('ONGOING')),
                    const SizedBox(width: 6),
                    _buildStatusFilterChip('COMPLETED', 'Resulted 🏆', Icons.emoji_events, appState.selectedStatus == 'COMPLETED', () => appState.setStatusFilter('COMPLETED')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Matches Count Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AVAILABLE MATCHES (${matches.length})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              if (selectedMode != 'ALL' || selectedTeamType != 'ALL' || selectedFilter != 'ALL')
                InkWell(
                  onTap: () {
                    appState.setMode('ALL');
                    appState.setTeamType('ALL');
                    appState.setFilter('ALL');
                  },
                  child: const Text(
                    'Reset Filters',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. Matches List
          if (matches.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.sports_esports, size: 48, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 12),
                  const Text(
                    'No tournaments found for this filter.',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Try changing mode, team format, or creating a new match in Admin Panel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Inter', color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      appState.setMode('ALL');
                      appState.setTeamType('ALL');
                      appState.setFilter('ALL');
                    },
                    child: const Text('Show All Matches', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: matches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final match = matches[index];
                final matchCard = _buildMatchCard(context, match);

                // Har 2 match card ke baad ek sponsored ad banner dikhega (index 1, 3, 5...)
                if ((index + 1) % 2 == 0) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      matchCard,
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'SPONSORED',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.amber,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AdmobBannerWidget(
                              key: ValueKey('lobby_feed_banner_$index'),
                              adSize: AdSize.mediumRectangle, // 300x250 Medium Rectangle (bada banner)
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return matchCard;
              },
            ),
        ],
      ),
    );
  }

  // --- CATEGORY BANNER CARD WIDGET ---
  Widget _buildCategoryBannerCard({
    required String title,
    required String modeKey,
    required String assetPath,
    required bool isSelected,
    required int matchCount,
  }) {
    return InkWell(
      onTap: () {
        if (appState.selectedMode == modeKey) {
          appState.setMode('ALL');
        } else {
          appState.setMode(modeKey);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryAmber : const Color(0xFFE2E8F0),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppTheme.primaryAmber.withAlpha(50) : Colors.black.withAlpha(12),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: MatchBannerImage(
                bannerImage: assetPath,
                fit: BoxFit.cover,
              ),
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(60),
                      Colors.black.withAlpha(200),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryAmber : Colors.black.withAlpha(160),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$matchCount Matches',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    isSelected ? '✓ ACTIVE FILTER' : 'TAP TO FILTER',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? AppTheme.primaryAmber : Colors.white70,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUB FILTER CHIPS (Solo / Duo / Squad) ---
  Widget _buildSubFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: isSelected ? AppTheme.primaryAmber : const Color(0xFF64748B)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- COIN ECONOMY FILTER CHIP (All / WinCoin / Reward Coin) ---
  Widget _buildEconomyChip(String value, String label, String? iconEmoji, bool isSelected) {
    return Expanded(
      child: InkWell(
        onTap: () => appState.setFilter(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (value == 'WIN_COIN' ? const Color(0xFFD97706) : (value == 'REWARD_COIN' ? const Color(0xFF059669) : const Color(0xFF0F172A)))
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconEmoji != null) ...[
                Text(iconEmoji, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STATUS FILTER CHIP (All / Upcoming / Ongoing / Resulted) ---
  Widget _buildStatusFilterChip(String value, String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MATCH CARD WIDGET ---
  Widget _buildMatchCard(BuildContext context, MatchModel match) {
    final isFree = match.matchType == MatchType.free;
    final isJoined = match.participants.any((p) => p.uid == appState.user.uid);
    final userSlot = isJoined
        ? match.participants.firstWhere((p) => p.uid == appState.user.uid).slotNumber
        : null;
    final progress = match.filledSlots / match.maxSlots;

    final isTeamMatch = match.isTeamMatch;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner with 12px rounded feel & Overlays
          Stack(
            children: [
              MatchBannerImage(
                bannerImage: match.bannerImage,
                height: 135,
              ),
              Container(
                height: 135,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(190),
                    ],
                  ),
                ),
              ),

              // Match Type Badge & Unique Match ID Badge
              Positioned(
                top: 10,
                left: 10,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF047857), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 4),
                        ],
                      ),
                      child: const Text(
                        '🏆 CASH PRIZE (₹)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(200),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withAlpha(180), width: 1),
                      ),
                      child: Text(
                        '#${match.id}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Crucial Inline Free Fire / Free Fire MAX Logo Badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(180),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: FreeFireLogoInline(
                    gameType: match.gameType,
                    height: 14,
                    showBadge: false,
                  ),
                ),
              ),

              // Format, Map & Time Info
              Positioned(
                bottom: 8,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const FfBulletPoint(size: 12),
                        Text(
                          '${match.mode.name.toUpperCase()} • ${match.teamType.name.toUpperCase()} • MAP: ${match.map.name.toUpperCase()}',
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(165),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amber.withAlpha(100), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            match.status == MatchStatus.upcoming ? Icons.schedule : Icons.bolt,
                            color: Colors.amber,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            match.status == MatchStatus.upcoming
                                ? DateFormat('dd MMM, hh:mm a').format(match.matchTime)
                                : match.status.name.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Content section (White background, high contrast, clean typography)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Kickoff Countdown Ticker Widget
                LiveCountdownTimerWidget(match: match),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        match.title,
                        style: AppTheme.gamingTitle(fontSize: 16),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showPrizeBreakdownDialog(context, match),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.emoji_events, color: Color(0xFFB45309), size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Rank Prizes',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Prize & Entry Fee Breakdown Boxes (4 Columns)
                Row(
                  children: [
                    Expanded(
                      child: _buildPrizeBox(
                        'Entry Fee',
                        match.entryFeeDisplay,
                        const Color(0xFFB45309),
                        const Color(0xFFFEF3C7),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildPrizeBox(
                        'Total Pool',
                        '₹${match.prizePool.totalPool.toInt()}',
                        const Color(0xFF065F46),
                        const Color(0xFFECFDF5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildPrizeBox(
                        '1st Prize',
                        '₹${match.prizePool.firstPlace.toInt()}',
                        Colors.amber.shade900,
                        const Color(0xFFFFFBEB),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildPrizeBox(
                        'Per Kill',
                        match.prizePool.perKill > 0 ? '₹${match.prizePool.perKill.toInt()}' : '₹0',
                        AppTheme.roseRed,
                        const Color(0xFFFFF1F2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Slots Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Slots: ${match.filledSlots}/${match.maxSlots}',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                    ),
                    Text(
                      '${(progress * 100).toInt()}% filled',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 0.8 ? Colors.red : (isFree ? AppTheme.primaryAmber : AppTheme.winningGreen),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 14),

                if (match.isFillingRoom) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.alarm_on, color: Color(0xFFDC2626), size: 16),
                            SizedBox(width: 6),
                            Text(
                              'MATCH FULL • AUTO-STARTING',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF991B1B)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Room in ${match.roomCountdownRemaining.inMinutes}m',
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action / Join Button
                if (isJoined)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'REGISTERED (SLOT #$userSlot)',
                          style: AppTheme.gamingTitle(fontSize: 13, color: const Color(0xFF065F46), isItalic: false),
                        ),
                      ],
                    ),
                  )
                else if (match.filledSlots >= match.maxSlots)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'SLOTS FULL',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFree ? AppTheme.primaryAmber : const Color(0xFF0F172A),
                        foregroundColor: isFree ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (isTeamMatch) {
                          showDialog(
                            context: context,
                            builder: (context) => SquadTeamDialog(
                              match: match,
                              appState: appState,
                              onEarnCoinsClick: onEarnCoinsClick,
                            ),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => SlotPickerDialog(
                              match: match,
                              appState: appState,
                              onEarnCoinsClick: onEarnCoinsClick,
                            ),
                          );
                        }
                      },
                      child: Text(
                        isTeamMatch
                            ? (match.entryFee <= 0
                                ? 'JOIN SQUAD'
                                : (match.entryFeeType == EntryFeeType.cash || match.matchType == MatchType.paid
                                    ? 'JOIN SQUAD (₹${match.entryFee.toInt()})'
                                    : 'JOIN SQUAD (🟡 ${match.entryFee.toInt()})'))
                            : (match.entryFee <= 0
                                ? 'JOIN MATCH'
                                : (match.entryFeeType == EntryFeeType.cash || match.matchType == MatchType.paid
                                    ? 'JOIN MATCH (₹${match.entryFee.toInt()})'
                                    : 'JOIN MATCH (🟡 ${match.entryFee.toInt()})')),
                        style: AppTheme.gamingTitle(
                          fontSize: 13,
                          color: isFree ? Colors.black : Colors.white,
                          isItalic: false,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeBox(String label, String value, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withAlpha(8)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 2),
          Text(value, style: AppTheme.gamingNumber(fontSize: 13, color: textColor)),
        ],
      ),
    );
  }

  void _showPrizeBreakdownDialog(BuildContext context, MatchModel match) {
    final pp = match.prizePool;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Prize Pool Breakdown',
                style: AppTheme.gamingTitle(fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '#${match.id}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                match.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              // Dynamic Ranks 1 to 10 Display
              ...List.generate(10, (idx) {
                final rank = idx + 1;
                final prize = match.getTeamRankPrize(rank);
                if (prize <= 0) return const SizedBox.shrink();

                String rankBadge;
                Color rankColor;
                if (rank == 1) {
                  rankBadge = '🥇 1st Place (Rank 1)';
                  rankColor = Colors.amber.shade900;
                } else if (rank == 2) {
                  rankBadge = '🥈 2nd Place (Rank 2)';
                  rankColor = const Color(0xFF475569);
                } else if (rank == 3) {
                  rankBadge = '🥉 3rd Place (Rank 3)';
                  rankColor = const Color(0xFFB45309);
                } else {
                  rankBadge = '🎖️ Rank $rank';
                  rankColor = const Color(0xFF64748B);
                }

                return _buildPrizeRow(
                  rankBadge,
                  '₹${prize.toInt()} Real Cash',
                  rankColor,
                );
              }),
              if (pp.perKill > 0)
                _buildPrizeRow('🎯 Per Kill Bounty', '₹${pp.perKill.toInt()} Real Cash', Colors.red),
              const Divider(height: 20),
              _buildPrizeRow('📊 Total Prize Pool', '₹${pp.totalPool.toInt()} Real Cash', AppTheme.winningGreen, isBold: true),
              _buildPrizeRow('🎟️ Entry Fee', match.entryFee <= 0 ? 'FREE DIRECT ENTRY' : '${match.entryFee.toInt()} 🟡 Ad Coins', const Color(0xFF0F172A)),
              if (match.roomPublishedByAdminName != null && match.roomPublishedByAdminName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '👤 Room Published by: ${match.roomPublishedByAdminName}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeRow(String label, String value, Color textColor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- 🎁 DAILY MISSIONS & LOGIN HERO CARD ---
  Widget _buildDailyMissionsQuickCard(BuildContext context) {
    final taskData = appState.dailyTaskData;
    taskData.checkAndResetForNewDay();
    final hasCheckedIn = taskData.hasCheckedInToday;
    final todayReward = taskData.getTodayCheckInReward();

    return InkWell(
      onTap: () {
        DailyLoginPopupDialog.show(context, appState, onNavigateToEarn: onEarnCoinsClick);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withAlpha(90), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: const Text('🎁', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'DAILY MISSIONS & LOGIN',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Day ${taskData.checkInStreak}/14',
                          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasCheckedIn
                        ? 'Day ${taskData.checkInStreak} Claimed! Daily match & ad missions ready!'
                        : 'Day ${taskData.checkInStreak} login reward ready! Tap to claim +$todayReward 🪙 Coin!',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: hasCheckedIn ? const Color(0xFF94A3B8) : const Color(0xFFFDE68A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: hasCheckedIn ? const Color(0xFF334155) : const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hasCheckedIn ? 'TASKS' : 'CLAIM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: hasCheckedIn ? Colors.white70 : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiveCountdownTimerWidget extends StatefulWidget {
  final MatchModel match;

  const LiveCountdownTimerWidget({super.key, required this.match});

  @override
  State<LiveCountdownTimerWidget> createState() => _LiveCountdownTimerWidgetState();
}

class _LiveCountdownTimerWidgetState extends State<LiveCountdownTimerWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final now = DateTime.now();
    final diff = match.matchTime.difference(now);
    final isPast = diff.isNegative;

    String countdownText;
    Color statusColor = AppTheme.primaryAmber;
    IconData statusIcon = Icons.timer_outlined;

    if (match.status == MatchStatus.ongoing) {
      countdownText = '⚔️ MATCH IS LIVE IN ROOM!';
      statusColor = Colors.green;
      statusIcon = Icons.sensors;
    } else if (match.status == MatchStatus.completed) {
      countdownText = '🏆 MATCH COMPLETED';
      statusColor = const Color(0xFF64748B);
      statusIcon = Icons.emoji_events;
    } else if (match.status == MatchStatus.cancelled) {
      countdownText = '❌ MATCH CANCELLED (COINS REFUNDED)';
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else if (isPast || match.status == MatchStatus.roomFilling) {
      countdownText = '🚀 KICKOFF TIME REACHED • ROOM ID SHARING!';
      statusColor = Colors.amber;
      statusIcon = Icons.bolt;
    } else {
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;
      if (hours > 0) {
        countdownText = '⏳ Starts in: ${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
      } else {
        countdownText = '⏳ Starts in: ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
      }
      if (diff.inMinutes < 15) {
        statusColor = const Color(0xFFF97316); // Orange alert for under 15 mins
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withAlpha(120), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 6),
              Text(
                countdownText,
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor.withAlpha(80)),
            ),
            child: Text(
              DateFormat('hh:mm a').format(match.matchTime),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
