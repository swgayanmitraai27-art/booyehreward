import 'dart:async';
import 'package:flutter/material.dart';
import '../models/leaderboard_model.dart';
import '../services/app_state.dart';

class WeeklyLeaderboardScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback? onBrowseTournaments;

  const WeeklyLeaderboardScreen({
    super.key,
    required this.appState,
    this.onBrowseTournaments,
  });

  @override
  State<WeeklyLeaderboardScreen> createState() => _WeeklyLeaderboardScreenState();
}

class _WeeklyLeaderboardScreenState extends State<WeeklyLeaderboardScreen> {
  String _selectedFilter = 'WEEKLY'; // 'WEEKLY' | 'ALL_TIME'
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.appState.getWeeklySeasonTimeRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeLeft = widget.appState.getWeeklySeasonTimeRemaining();
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    int days = d.inDays;
    int hours = d.inHours.remainder(24);
    int minutes = d.inMinutes.remainder(60);
    int seconds = d.inSeconds.remainder(60);
    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m ${seconds}s';
    }
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showRulesDialog() {
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
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Weekly Championship Rules',
                style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRuleItem('🏆 ₹100 Weekly Cash Prize Pool', 'Every Sunday at 11:59 PM, the Top 3 leaderboard players receive real money prizes:'),
              const SizedBox(height: 8),
              _buildPrizeRow('🥇 Rank 1', '₹50 Real Cash', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
              _buildPrizeRow('🥈 Rank 2', '₹30 Real Cash', const Color(0xFFF1F5F9), const Color(0xFF475569)),
              _buildPrizeRow('🥉 Rank 3', '₹20 Real Cash', const Color(0xFFFFEDD5), const Color(0xFFEA580C)),
              const Divider(height: 24),
              _buildRuleItem('🎯 Scoring System', 'Points are calculated automatically from matches played this week:'),
              const SizedBox(height: 6),
              _buildScoreRow('🎯 1 Tournament Kill', '+10 Points'),
              _buildScoreRow('👑 1 Booyah (Match Win)', '+50 Points'),
              _buildScoreRow('💰 ₹1 Cash Won in Match', '+2 Points'),
              const Divider(height: 24),
              _buildRuleItem('⚡ Automatic Wallet Credit', 'Winning prizes are credited directly to your Winning Wallet with 100% instant UPI withdrawal eligibility!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Got It', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
        const SizedBox(height: 2),
        Text(desc, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4)),
      ],
    );
  }

  Widget _buildPrizeRow(String rank, String prize, Color bg, Color textCol) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rank, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textCol)),
          Text(prize, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: textCol)),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String action, String pts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(action, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155))),
          Text(pts, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF059669))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.appState.getWeeklyLeaderboard(filter: _selectedFilter);
    final seasonLabel = widget.appState.getWeeklySeasonLabel();

    final top1 = list.isNotEmpty ? list[0] : null;
    final top2 = list.length > 1 ? list[1] : null;
    final top3 = list.length > 2 ? list[2] : null;
    final remainingPlayers = list.length > 3 ? list.sublist(3) : <LeaderboardEntry>[];

    final currentUserEntry = list.firstWhere(
      (e) => e.isCurrentUser || e.uid == widget.appState.user.uid,
      orElse: () => LeaderboardEntry(
        uid: widget.appState.user.uid,
        displayName: widget.appState.user.displayName,
        inGameName: widget.appState.user.inGameName,
        inGameUid: widget.appState.user.inGameUid,
        rank: list.length + 1,
        kills: 0,
        matchesWon: 0,
        matchesPlayed: 0,
        winningsCash: 0,
        rewardCoins: 0,
        points: 0,
        prizeAmount: 0,
        isCurrentUser: true,
      ),
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 🏆 1. HERO CHAMPIONSHIP HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                  Color(0xFF0F172A),
                ],
              ),
            ),
            child: Column(
              children: [
                // Top Badge & Rules Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withAlpha(120)),
                      ),
                      child: Row(
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Text(
                            'SEASON: $seasonLabel',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _showRulesDialog,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withAlpha(50)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white70, size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Rules & Info',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Trophy Title
                const Text(
                  'WEEKLY CHAMPIONSHIP',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Top 3 Players Win Real Cash Payout Every Week!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 14),

                // ₹100 Prize Pool Badge & Countdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withAlpha(90),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WEEKLY PRIZE POOL',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF78350F), letterSpacing: 0.8),
                          ),
                          const Row(
                            children: [
                              Text(
                                '₹100',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'REAL CASH',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFFFEF3C7)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(height: 36, width: 1, color: Colors.white24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'SEASON ENDS IN',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF78350F), letterSpacing: 0.8),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(_timeLeft),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Top 3 Prize Breakdown Strip
                Row(
                  children: [
                    Expanded(child: _buildPrizeBadge('🥇 1st Place', '₹50 CASH', const Color(0xFFFEF3C7), const Color(0xFFB45309))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPrizeBadge('🥈 2nd Place', '₹30 CASH', const Color(0xFFF1F5F9), const Color(0xFF334155))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPrizeBadge('🥉 3rd Place', '₹20 CASH', const Color(0xFFFFEDD5), const Color(0xFFC2410C))),
                  ],
                ),
              ],
            ),
          ),

          // 🔀 2. FILTER TOGGLE (This Week vs All Time)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterTab(
                      label: '🔥 This Week (Live ₹100 Pool)',
                      filterKey: 'WEEKLY',
                    ),
                  ),
                  Expanded(
                    child: _buildFilterTab(
                      label: '⭐ All-Time Legends',
                      filterKey: 'ALL_TIME',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 👑 3. TOP 3 PODIUM DISPLAY
          if (top1 != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Rank 2 (Silver - Left)
                  Expanded(
                    child: top2 != null
                        ? _buildPodiumColumn(
                            entry: top2,
                            rank: 2,
                            height: 145,
                            glowColor: const Color(0xFF94A3B8),
                            crownEmoji: '🥈',
                            rankTitle: '2ND PLACE',
                            prizeLabel: '₹30',
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),

                  // Rank 1 (Gold - Center, Tallest)
                  Expanded(
                    child: _buildPodiumColumn(
                      entry: top1,
                      rank: 1,
                      height: 180,
                      glowColor: const Color(0xFFF59E0B),
                      crownEmoji: '👑',
                      rankTitle: 'CHAMPION',
                      prizeLabel: '₹50',
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Rank 3 (Bronze - Right)
                  Expanded(
                    child: top3 != null
                        ? _buildPodiumColumn(
                            entry: top3,
                            rank: 3,
                            height: 130,
                            glowColor: const Color(0xFFF97316),
                            crownEmoji: '🥉',
                            rankTitle: '3RD PLACE',
                            prizeLabel: '₹20',
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // 📋 4. FULL RANK LIST (Rank 4 to N)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ALL PLAYERS RANKING',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF475569),
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      '${list.length} Total Competitors',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (remainingPlayers.isEmpty && list.length <= 3) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'Play more tournaments to join the leaderboard!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: remainingPlayers.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 6),
                    itemBuilder: (ctx, i) {
                      final player = remainingPlayers[i];
                      return _buildPlayerRankCard(player);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 📌 5. STICKY / PINNED USER RANK CARD AT BOTTOM
          _buildMyRankStickyCard(currentUserEntry, top3?.points ?? 100),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPrizeBadge(String place, String prize, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(place, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: textCol)),
          const SizedBox(height: 1),
          Text(prize, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: textCol)),
        ],
      ),
    );
  }

  Widget _buildFilterTab({required String label, required String filterKey}) {
    final isSelected = _selectedFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterKey),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumColumn({
    required LeaderboardEntry entry,
    required int rank,
    required double height,
    required Color glowColor,
    required String crownEmoji,
    required String rankTitle,
    required String prizeLabel,
  }) {
    final is1st = rank == 1;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Crown / Medal Icon
        Text(crownEmoji, style: TextStyle(fontSize: is1st ? 26 : 20)),
        const SizedBox(height: 2),

        // Avatar
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: is1st ? 28 : 23,
              backgroundColor: glowColor,
              child: CircleAvatar(
                radius: is1st ? 25 : 21,
                backgroundColor: const Color(0xFF0F172A),
                child: Text(
                  (entry.inGameName?.isNotEmpty == true
                          ? entry.inGameName![0]
                          : entry.displayName.isNotEmpty
                              ? entry.displayName[0]
                              : 'P')
                      .toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: is1st ? 16 : 13,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: glowColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 9.5, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Name
        Text(
          entry.inGameName ?? entry.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: is1st ? 12.5 : 11,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),

        // Points
        Text(
          '${entry.points} pts',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: is1st ? const Color(0xFFD97706) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),

        // Podium Block
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: is1st
                  ? [const Color(0xFFFDE68A), const Color(0xFFF59E0B)]
                  : rank == 2
                      ? [const Color(0xFFE2E8F0), const Color(0xFF94A3B8)]
                      : [const Color(0xFFFFEDD5), const Color(0xFFF97316)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            boxShadow: [
              BoxShadow(
                color: glowColor.withAlpha(50),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                rankTitle,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: is1st ? const Color(0xFF78350F) : Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$prizeLabel CASH',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: is1st ? 13 : 11.5,
                    fontWeight: FontWeight.w900,
                    color: is1st ? const Color(0xFFB45309) : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '🎯 ${entry.kills} Kills • 🏆 ${entry.matchesWon} Wins',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRankCard(LeaderboardEntry player) {
    final isMe = player.isCurrentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
          width: isMe ? 1.5 : 1.0,
        ),
        boxShadow: isMe
            ? [BoxShadow(color: Colors.amber.withAlpha(30), blurRadius: 6, offset: const Offset(0, 2))]
            : null,
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#${player.rank}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Avatar / Icon
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF0F172A),
            child: Text(
              (player.inGameName?.isNotEmpty == true
                      ? player.inGameName![0]
                      : player.displayName.isNotEmpty
                          ? player.displayName[0]
                          : 'P')
                  .toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),

          // Name & UID
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.inGameName ?? player.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isMe ? const Color(0xFF92400E) : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('YOU', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '🎯 ${player.kills} Kills  •  🏆 ${player.matchesWon} Wins',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          // Total Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${player.points}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Text(
                'PTS',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyRankStickyCard(LeaderboardEntry myEntry, int rank3Points) {
    final isInTop3 = myEntry.rank <= 3 && myEntry.rank > 0;
    final pointsNeeded = (rank3Points - myEntry.points) + 10;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // User Rank Circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isInTop3 ? const Color(0xFFF59E0B) : Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '#${myEntry.rank}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isInTop3 ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'YOUR WEEKLY RANK',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.amber, letterSpacing: 0.5),
                          ),
                          if (isInTop3) ...[
                            const SizedBox(width: 6),
                            const Text('🔥 (Winning Cash!)', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        myEntry.inGameName ?? myEntry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Points & Potential Prize
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${myEntry.points} PTS',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    if (isInTop3) ...[
                      Text(
                        'Prize: ₹${myEntry.prizeAmount.toInt()}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.amber),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),

            // Motivation & Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    isInTop3
                        ? '🎉 Great job! Keep playing to protect your Top 3 position until Sunday!'
                        : '⚡ Score $pointsNeeded more points to break into the Top 3 and win ₹100 cash!',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1), height: 1.3),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: widget.onBrowseTournaments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Play Match', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
