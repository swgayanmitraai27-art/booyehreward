import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/match_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/match_banner_image.dart';
import '../widgets/ff_brand_elements.dart';
import '../widgets/match_rules_card.dart';
import 'package:intl/intl.dart';

class MyMatchesScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onBrowseMatches;

  const MyMatchesScreen({
    super.key,
    required this.appState,
    required this.onBrowseMatches,
  });

  @override
  State<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends State<MyMatchesScreen> {
  final Map<String, TextEditingController> _uidControllers = {};

  @override
  void dispose() {
    for (var c in _uidControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String matchId, String initialUid) {
    if (!_uidControllers.containsKey(matchId)) {
      _uidControllers[matchId] = TextEditingController(text: initialUid);
    }
    return _uidControllers[matchId]!;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF065F46),
        content: Text('$label copied to clipboard!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myMatches = widget.appState.myMatches;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'REGISTERED TOURNAMENTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    'My Matches & Room Details',
                    style: AppTheme.gamingTitle(fontSize: 20),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber.withAlpha(50),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryAmber),
                ),
                child: Text(
                  '${myMatches.length} Joined',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (myMatches.isEmpty)
            Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.sports_esports_outlined, size: 56, color: Colors.amber),
                  const SizedBox(height: 12),
                  Text(
                    'No Joined Matches Yet',
                    style: AppTheme.gamingTitle(fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'You haven\'t registered for any Free or Paid tournaments yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: widget.onBrowseMatches,
                    child: const Text('EXPLORE TOURNAMENT LOBBY'),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: myMatches.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final match = myMatches[index];
                final participant = match.participants.firstWhere((p) => p.uid == widget.appState.user.uid);
                return _buildMyMatchCard(match, participant);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMyMatchCard(MatchModel match, MatchParticipant participant) {
    final isFree = match.matchType == MatchType.free;
    final bool isRoomPublished = match.credentials.roomId.isNotEmpty && match.credentials.roomId.trim() != '';
    final uidController = _getController(match.id, participant.inGameUid);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
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
          // Match Banner Image
          MatchBannerImage(
            bannerImage: match.bannerImage,
            height: 110,
          ),

          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isFree ? const Color(0xFFFEF3C7) : const Color(0xFF0F172A),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isFree ? AppTheme.primaryAmber : AppTheme.winningGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'SLOT #${participant.slotNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isFree ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withAlpha(180), width: 0.8),
                      ),
                      child: Text(
                        '#${match.id}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FreeFireLogoInline(
                      gameType: match.gameType,
                      height: 14,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.withOpacity(0.4), width: 0.8),
                  ),
                  child: Text(
                    match.status == MatchStatus.completed
                        ? DateFormat('dd MMM, hh:mm a').format(match.completedAt ?? match.matchTime)
                        : (match.status == MatchStatus.upcoming ? '⚡ AUTO-START ON FULL' : match.status.name.toUpperCase()),
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isFree ? const Color(0xFFFBBF24) : Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.title,
                  style: AppTheme.gamingTitle(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  'Format: ${match.matchFormat.name.toUpperCase()} • Map: ${match.map.name.toUpperCase()} • Prize: ${isFree ? '${match.prizePool.totalPool.toInt()} 🎟️ Reward Coins' : '₹${match.prizePool.totalPool.toInt()} Cash'}',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),

                // 1. Submit Details Box (Free Fire UID)
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
                          const Row(
                            children: [
                              Icon(Icons.person_pin, size: 16, color: Colors.amber),
                              SizedBox(width: 6),
                              Text(
                                'SUBMITTED IN-GAME DETAILS',
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                          Text(
                            participant.inGameName,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: uidController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: 'Free Fire UID',
                                labelStyle: const TextStyle(fontSize: 11),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              participant.inGameUid = uidController.text.trim();
                              widget.appState.updateUserProfile(
                                inGameName: participant.inGameName,
                                inGameUid: participant.inGameUid,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Free Fire UID updated successfully!')),
                              );
                            },
                            child: const Text('UPDATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Room ID & Password Box (Direct Reveal - NO ADS REQUIRED)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isRoomPublished
                          ? [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)]
                          : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRoomPublished ? AppTheme.winningGreen : const Color(0xFFF59E0B),
                      width: 1.5,
                    ),
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
                                isRoomPublished ? Icons.lock_open : Icons.access_time_filled,
                                size: 18,
                                color: isRoomPublished ? const Color(0xFF047857) : const Color(0xFFB45309),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'CUSTOM ROOM ID & PASSWORD',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isRoomPublished ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isRoomPublished ? AppTheme.winningGreen : Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isRoomPublished ? 'PUBLISHED' : 'PUBLISHING SOON',
                              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (isRoomPublished) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('ROOM ID', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        Text(
                                          match.credentials.roomId,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 16, color: AppTheme.winningGreen),
                                      onPressed: () => _copyToClipboard(match.credentials.roomId, 'Room ID'),
                                      tooltip: 'Copy Room ID',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFA7F3D0)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('PASSWORD', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        Text(
                                          match.credentials.roomPassword,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 16, color: AppTheme.winningGreen),
                                      onPressed: () => _copyToClipboard(match.credentials.roomPassword, 'Password'),
                                      tooltip: 'Copy Password',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '⚡ Open Free Fire / FF Max, go to Custom Room, search Room ID, enter password & join your slot!',
                          style: TextStyle(fontSize: 10, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                        ),
                      ] else ...[
                        if (match.isFillingRoom) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.alarm_on, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '🚨 MATCH 100% FULL! AUTO-STARTING',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF991B1B)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Room ID & Password will be provided in exactly ${match.roomCountdownRemaining.inMinutes} minutes! Keep your game ready.',
                                        style: const TextStyle(fontSize: 10.5, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: Color(0xFFB45309)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Room ID & Password will be published 10-15 minutes before kickoff by Admin. No ads needed to view!',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF78350F), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const MatchRulesCard(initiallyExpanded: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
