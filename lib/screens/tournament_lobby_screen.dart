import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/slot_picker_dialog.dart';
import '../widgets/squad_team_dialog.dart';
import '../widgets/match_banner_image.dart';
import '../widgets/ff_brand_elements.dart';
import '../widgets/dynamic_banner_carousel.dart';
import 'package:intl/intl.dart';

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
          if (appState.banners.isNotEmpty) ...[
            DynamicBannerCarousel(banners: appState.banners),
            const SizedBox(height: 14),
          ],

          // 1. Hero Promo Card (Clean Light Aesthetic with Amber Accent)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 12,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          Image.asset('imgasest/FF_SHORT_LOGO.PNG.png', width: 14, height: 14),
                          const SizedBox(width: 6),
                          const Text(
                            'HYBRID ESPORTS ARENA',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF92400E),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const FreeFireLogoInline(height: 16),
                  ],
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: AppTheme.gamingTitle(fontSize: 22, color: Colors.black),
                    children: const [
                      TextSpan(text: 'PLAY FREE OR WIN '),
                      TextSpan(
                        text: 'REAL CASH',
                        style: TextStyle(color: AppTheme.primaryAmber),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Watch ads for 🟡 Ad Coins in Free Tournaments or deposit cash for Pro 75/25 Matches with Instant UPI withdrawals.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryAmber,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: onEarnCoinsClick,
                      icon: const Text('🟡', style: TextStyle(fontSize: 13)),
                      label: const Text(
                        'Get Free Coins',
                        style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800, fontSize: 11.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => onTabChange(1),
                      child: const Text(
                        'My Matches',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

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
              children: [
                _buildCategoryBannerCard(
                  title: 'Full Map (BR)',
                  modeKey: 'BR',
                  assetPath: 'imgasest/brhomescreen .png',
                  isSelected: selectedMode == 'BR',
                  matchCount: appState.matches.where((m) => m.mode == MatchMode.br).length,
                ),
                const SizedBox(width: 12),
                _buildCategoryBannerCard(
                  title: 'Clash Squad (CS)',
                  modeKey: 'CS',
                  assetPath: 'imgasest/cshomescreen.png',
                  isSelected: selectedMode == 'CS',
                  matchCount: appState.matches.where((m) => m.mode == MatchMode.cs).length,
                ),
                const SizedBox(width: 12),
                _buildCategoryBannerCard(
                  title: 'Lone Wolf',
                  modeKey: 'LONE_WOLF',
                  assetPath: 'imgasest/lonewolfhomescreen.png',
                  isSelected: selectedMode == 'LONE_WOLF',
                  matchCount: appState.matches.where((m) => m.mode == MatchMode.loneWolf).length,
                ),
              ],
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

              // Economy Filter Row (All / Free / Paid)
              Row(
                children: [
                  _buildEconomyChip('ALL', 'All Matches', null, selectedFilter == 'ALL'),
                  const SizedBox(width: 6),
                  _buildEconomyChip('FREE', 'Free Matches', '🟡', selectedFilter == 'FREE'),
                  const SizedBox(width: 6),
                  _buildEconomyChip('PAID', 'Paid Matches', '💵', selectedFilter == 'PAID'),
                ],
              ),
              const SizedBox(height: 10),

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
                return _buildMatchCard(context, match);
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
              child: Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF1E293B)),
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

  // --- ECONOMY FILTER CHIP (All / Free / Paid) ---
  Widget _buildEconomyChip(String value, String label, String? iconEmoji, bool isSelected) {
    return Expanded(
      child: InkWell(
        onTap: () => appState.setFilter(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (value == 'FREE' ? AppTheme.primaryAmber : (value == 'PAID' ? const Color(0xFF0F172A) : const Color(0xFF0F172A)))
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
                  color: isSelected
                      ? (value == 'FREE' ? Colors.black : Colors.white)
                      : const Color(0xFF475569),
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

    final isTeamMatch = match.teamType == TeamType.duo ||
        match.teamType == TeamType.squad ||
        match.matchFormat == MatchFormat.duo ||
        match.matchFormat == MatchFormat.squad ||
        match.matchFormat == MatchFormat.cs4v4;

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

              // Match Type Badge (Free vs Paid)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFree ? AppTheme.primaryAmber : AppTheme.winningGreen,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 4),
                    ],
                  ),
                  child: Text(
                    isFree ? '🟡 FREE MATCH' : '💵 PAID 75/25 MATCH',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: isFree ? Colors.black : Colors.white,
                    ),
                  ),
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
                    Text(
                      DateFormat('hh:mm a').format(match.matchTime),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
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
                Text(
                  match.title,
                  style: AppTheme.gamingTitle(fontSize: 16),
                ),
                const SizedBox(height: 10),

                // Prize Breakdown Boxes
                Row(
                  children: [
                    Expanded(
                      child: _buildPrizeBox(
                        'Total Pool',
                        isFree ? '${match.prizePool.totalPool.toInt()} 🎟️' : '₹${match.prizePool.totalPool.toInt()}',
                        const Color(0xFF065F46),
                        const Color(0xFFECFDF5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPrizeBox(
                        '1st Prize',
                        isFree ? '${match.prizePool.firstPlace.toInt()} 🎟️' : '₹${match.prizePool.firstPlace.toInt()}',
                        Colors.amber.shade900,
                        const Color(0xFFFFFBEB),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPrizeBox(
                        'Per Kill',
                        isFree
                            ? '${match.prizePool.perKill.toInt()} 🎟️'
                            : (match.prizePool.perKill > 0 ? '₹${match.prizePool.perKill.toInt()}' : '₹0'),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
                            ? (isFree
                                ? '🟡 JOIN SQUAD (${match.entryFee.toInt()} AD COINS)'
                                : '💵 JOIN SQUAD (PAY ₹${match.entryFee.toInt()})')
                            : (isFree
                                ? '🟡 JOIN WITH ${match.entryFee.toInt()} AD COINS (PICK SLOT)'
                                : '💵 PAY ₹${match.entryFee.toInt()} TO JOIN (PICK SLOT)'),
                        style: AppTheme.gamingTitle(fontSize: 13, isItalic: false),
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
}
