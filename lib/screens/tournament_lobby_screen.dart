import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tournament_model.dart';
import '../services/ad_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class TournamentLobbyScreen extends StatefulWidget {
  final AppState appState;

  const TournamentLobbyScreen({super.key, required this.appState});

  @override
  State<TournamentLobbyScreen> createState() => _TournamentLobbyScreenState();
}

class _TournamentLobbyScreenState extends State<TournamentLobbyScreen> {
  String _selectedCategory = 'ALL';

  final List<Map<String, String>> _categories = [
    {'id': 'ALL', 'label': '⚡ सभी मैच'},
    {'id': 'BR', 'label': '🔥 बैटल रॉयल सोलो'},
    {'id': 'CS', 'label': '⚔️ क्लैश स्क्वाड 4v4'},
    {'id': 'LW', 'label': '🎯 लोन वोल्फ 1v1'},
    {'id': 'MEGA', 'label': '🏆 मेगा कप ₹500'},
    {'id': 'CUSTOM', 'label': '🎮 कस्टम मोड्स'},
  ];

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    widget.appState.fetchFFTournaments(category: _selectedCategory);
    // Real-time ticking countdown timer (every 1 second)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onCategorySelected(String cat) {
    setState(() => _selectedCategory = cat);
    widget.appState.fetchFFTournaments(category: cat);
  }

  // ── 1. REGISTRATION MODAL (SOLO / MEGA) ──
  void _openSoloRegistrationModal(FFTournament tourn) {
    final ignController = TextEditingController(text: widget.appState.user.inGameName);
    final uidController = TextEditingController(text: widget.appState.user.inGameId);
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.bgDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.primaryGold, width: 2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SLOT REGISTRATION',
                    style: GoogleFonts.rajdhani(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                      letterSpacing: 1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tourn.title,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Entry Fee', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        Text('${tourn.entryFeeCoins} Coins',
                            style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Your Balance', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        Text('${widget.appState.user.adCoins} Coins',
                            style: GoogleFonts.rajdhani(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.appState.user.adCoins >= tourn.entryFeeCoins
                                    ? AppTheme.successGreen
                                    : AppTheme.errorRed)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'FREE FIRE IN-GAME NAME (IGN)',
                style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: ignController,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'e.g. Raistar_FF',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                  filled: true,
                  fillColor: AppTheme.bgCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'FREE FIRE NUMERIC UID',
                style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: uidController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'e.g. 192847192',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                  filled: true,
                  fillColor: AppTheme.bgCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 18),
              if (widget.appState.user.adCoins < tourn.entryFeeCoins)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGold,
                        side: const BorderSide(color: AppTheme.primaryGold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.play_circle_fill, size: 20),
                      label: Text('WATCH AD TO EARN +10 COINS', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        AdService.showRewardedAd(
                          context: context,
                          onRewarded: () async {
                            await widget.appState.watchAdEarnCoins();
                            setModalState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSubmitting || widget.appState.user.adCoins < tourn.entryFeeCoins
                      ? null
                      : () async {
                          if (ignController.text.trim().isEmpty) return;
                          setModalState(() => isSubmitting = true);
                          final res = await widget.appState.registerTournament(
                            tournamentId: tourn.id,
                            inGameName: ignController.text.trim(),
                            inGameId: uidController.text.trim(),
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: res['success'] == true ? AppTheme.successGreen : AppTheme.errorRed,
                              content: Text(res['message'] ?? 'Slot registered!'),
                            ),
                          );
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(
                          'CONFIRM REGISTRATION (-${tourn.entryFeeCoins} COINS)',
                          style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 2. TEAM CODE MODAL (DUO 2v2 & SQUAD 4v4) ──
  void _openTeamModal(FFTournament tourn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: AppTheme.bgDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppTheme.cyanAccent, width: 2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SQUAD / DUO TEAM JOIN',
              style: GoogleFonts.rajdhani(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent),
            ),
            const SizedBox(height: 6),
            Text(
              'No randoms! Play with your real friends using a Team Code.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openCreateTeamDialog(tourn);
                    },
                    child: Text(
                      'CREATE TEAM\n(BE CAPTAIN)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cyanAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openJoinTeamDialog(tourn);
                    },
                    child: Text(
                      'JOIN SQUAD\n(WITH CODE)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateTeamDialog(FFTournament tourn) {
    final teamNameController = TextEditingController();
    final ignController = TextEditingController(text: widget.appState.user.inGameName);
    final uidController = TextEditingController(text: widget.appState.user.inGameId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.primaryGold)),
        title: Text('CREATE SQUAD', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Team / Clan Name', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            TextField(controller: teamNameController, style: const TextStyle(color: Colors.white, fontSize: 13)),
            const SizedBox(height: 10),
            const Text('Captain Free Fire IGN', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            TextField(controller: ignController, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black),
            onPressed: () async {
              if (teamNameController.text.trim().isEmpty) return;
              final res = await widget.appState.createSquadTeam(
                tournamentId: tourn.id,
                teamName: teamNameController.text.trim(),
                inGameName: ignController.text.trim().isNotEmpty ? ignController.text.trim() : 'Captain',
                inGameId: uidController.text.trim(),
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              if (res['success'] == true) {
                _showTeamCodeSuccessDialog(res['teamCode'] ?? 'BOY-XXX');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error')));
              }
            },
            child: const Text('CREATE & GET CODE'),
          ),
        ],
      ),
    );
  }

  void _showTeamCodeSuccessDialog(String teamCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.successGreen, width: 2)),
        title: Text('🎉 SQUAD CREATED!', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this code with your teammates to join:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGold),
              ),
              child: Text(
                teamCode,
                style: GoogleFonts.rajdhani(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 3, color: AppTheme.primaryGold),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('COPY CODE'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: teamCode));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team code copied! Share on WhatsApp/Chat!')));
            },
          ),
        ],
      ),
    );
  }

  void _openJoinTeamDialog(FFTournament tourn) {
    final codeController = TextEditingController();
    final ignController = TextEditingController(text: widget.appState.user.inGameName);
    final uidController = TextEditingController(text: widget.appState.user.inGameId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.cyanAccent)),
        title: Text('JOIN SQUAD WITH CODE', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: AppTheme.cyanAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter 6-Digit Team Code', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
              decoration: const InputDecoration(hintText: 'BOY-XXX', hintStyle: TextStyle(color: Colors.white30)),
            ),
            const SizedBox(height: 10),
            const Text('Your Free Fire IGN', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            TextField(controller: ignController, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cyanAccent, foregroundColor: Colors.black),
            onPressed: () async {
              if (codeController.text.trim().isEmpty) return;
              final res = await widget.appState.joinSquadTeam(
                teamCode: codeController.text.trim(),
                inGameName: ignController.text.trim().isNotEmpty ? ignController.text.trim() : 'Player',
                inGameId: uidController.text.trim(),
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: res['success'] == true ? AppTheme.successGreen : AppTheme.errorRed,
                  content: Text(res['message'] ?? 'Joined!'),
                ),
              );
            },
            child: const Text('JOIN SQUAD'),
          ),
        ],
      ),
    );
  }

  // ── 3. ROOM CREDENTIALS REVEAL (INTERSTITIAL AD BARRIER) ──
  Future<void> _revealRoomCredentials(FFTournament tourn) async {
    final group = tourn.groups.isNotEmpty ? tourn.groups[0] : null;
    if (group == null) return;

    // Show Full-Screen Interstitial Ad as required by revenue blueprint!
    AdService.showInterstitialAd();

    final res = await widget.appState.fetchRoomCredentials(tourn.id, group.groupId);
    if (!mounted) return;

    if (res['isPublished'] == true && res['roomId'] != null) {
      final roomId = res['roomId'].toString();
      final roomPass = res['roomPassword'].toString();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.bgDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppTheme.primaryGold, width: 2)),
          title: Row(
            children: [
              const Icon(Icons.vpn_key, color: AppTheme.primaryGold),
              const SizedBox(width: 8),
              Text('ROOM CREDENTIALS', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tourn.title, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CUSTOM ROOM ID', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        Text(roomId, style: GoogleFonts.rajdhani(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppTheme.cyanAccent),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: roomId));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room ID copied!')));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ROOM PASSWORD', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        Text(roomPass, style: GoogleFonts.rajdhani(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppTheme.primaryGold),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: roomPass));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password copied!')));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '• Open Free Fire -> Custom Room -> Search ID -> Enter Password -> Join your slot!',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.3),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('READY TO PLAY'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.bgDark,
          title: Text('ROOM NOT LIVE YET', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: AppTheme.saffronOrange)),
          content: Text(res['message'] ?? 'Room ID will be published 15 minutes before the match!'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.saffronOrange, foregroundColor: Colors.black),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final tournaments = widget.appState.ffTournaments;

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: Column(
            children: [
              // ── TAGLINE BADGE ──
              Container(
                margin: const EdgeInsets.fromLTRB(14, 6, 14, 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.saffronOrange.withValues(alpha: 0.15),
                      AppTheme.bgCard,
                      AppTheme.indiaGreen.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: AppTheme.primaryGold, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'India Ka Apna Esports Platform. Zero Entry Fee, Infinite Glory!',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // ── CATEGORY FILTER TABS ──
              Container(
                height: 48,
                margin: const EdgeInsets.only(top: 8, bottom: 6),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _categories.length,
                  itemBuilder: (context, idx) {
                    final cat = _categories[idx];
                    final isSelected = cat['id'] == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat['label']!),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryGold,
                        backgroundColor: AppTheme.bgCard,
                        labelStyle: GoogleFonts.rajdhani(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.white70,
                          fontSize: 13,
                        ),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryGold : Colors.white12,
                        ),
                        onSelected: (_) => _onCategorySelected(cat['id']!),
                      ),
                    );
                  },
                ),
              ),

              // ── TOURNAMENT FEED ──
              Expanded(
                child: widget.appState.isLoadingTournaments
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
                    : tournaments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sports_esports, size: 54, color: AppTheme.textMuted),
                                const SizedBox(height: 12),
                                Text('No Matches in this Category', style: GoogleFonts.rajdhani(fontSize: 18, color: Colors.white70)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppTheme.primaryGold,
                            onRefresh: () => widget.appState.fetchFFTournaments(category: _selectedCategory),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                              itemCount: tournaments.length,
                              itemBuilder: (context, idx) {
                                final t = tournaments[idx];
                                final isRegistered = t.isUserRegistered;
                                final filled = t.filledSlots;
                                final total = t.totalSlots;
                                final progress = (total > 0) ? (filled / total).clamp(0.0, 1.0) : 0.0;
                                final isFull = filled >= total;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgCard,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isRegistered
                                          ? AppTheme.successGreen
                                          : AppTheme.primaryGold.withValues(alpha: 0.3),
                                      width: isRegistered ? 1.5 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Banner with Badges
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        child: Stack(
                                          children: [
                                            Image.network(
                                              t.bannerUrl,
                                              height: 125,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                height: 125,
                                                color: const Color(0xFF1F2937),
                                                child: const Center(
                                                  child: Icon(Icons.sports_esports, size: 48, color: Colors.white24),
                                                ),
                                              ),
                                            ),
                                            // Mode Badge
                                            Positioned(
                                              top: 10,
                                              left: 10,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.8),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppTheme.primaryGold),
                                                ),
                                                child: Text(
                                                  t.mode.toUpperCase(),
                                                  style: GoogleFonts.rajdhani(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primaryGold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Map Badge
                                            Positioned(
                                              top: 10,
                                              right: 10,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.8),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppTheme.cyanAccent),
                                                ),
                                                child: Text(
                                                  t.map.toUpperCase(),
                                                  style: GoogleFonts.rajdhani(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.cyanAccent,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // Registration Status Ribbon
                                            if (isRegistered)
                                              Positioned(
                                                bottom: 10,
                                                left: 10,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.successGreen,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '✓ REGISTERED (${t.userGroup ?? "Group A"} #${t.userSlot ?? 1})',
                                                    style: GoogleFonts.rajdhani(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),

                                      // ── LIVE MATCH TIME / COUNTDOWN STRIP UNDER BANNER ──
                                      _buildMatchTimeStrip(t),

                                      // Match Info
                                      Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.title,
                                              style: GoogleFonts.rajdhani(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.schedule, size: 14, color: AppTheme.textMuted),
                                                const SizedBox(width: 4),
                                                Text(
                                                  t.matchTimeText,
                                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),

                                            // Prize Pool & Entry Fee Row
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text('PRIZE POOL', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${t.prizePool.totalCoins} Coins',
                                                      style: GoogleFonts.rajdhani(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.successGreen,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  children: [
                                                    const Text('ENTRY FEE', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${t.entryFeeCoins} Coins',
                                                      style: GoogleFonts.rajdhani(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.primaryGold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),

                                            // Slots Progress Bar
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'SLOTS FILLED: $filled / $total',
                                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  '${total - filled} LEFT',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: (total - filled) <= 5 ? AppTheme.errorRed : AppTheme.cyanAccent,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                minHeight: 6,
                                                backgroundColor: Colors.white12,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  progress >= 0.8 ? AppTheme.saffronOrange : AppTheme.primaryGold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 14),

                                            // Action Button
                                            if (isRegistered)
                                              SizedBox(
                                                width: double.infinity,
                                                height: 44,
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.cyanAccent,
                                                    foregroundColor: Colors.black,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  icon: const Icon(Icons.vpn_key, size: 18),
                                                  label: Text(
                                                    'GET ROOM ID & PASSWORD (15M BEFORE)',
                                                    style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold),
                                                  ),
                                                  onPressed: () => _revealRoomCredentials(t),
                                                ),
                                              )
                                            else if (isFull)
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: Colors.white12,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  'SLOTS FULL (MATCH STARTING)',
                                                  style: GoogleFonts.rajdhani(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white54,
                                                  ),
                                                ),
                                              )
                                            else
                                              SizedBox(
                                                width: double.infinity,
                                                height: 44,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.primaryGold,
                                                    foregroundColor: Colors.black,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  ),
                                                  onPressed: () {
                                                    if (t.teamFormat == 'duo' || t.teamFormat == 'squad') {
                                                      _openTeamModal(t);
                                                    } else {
                                                      _openSoloRegistrationModal(t);
                                                    }
                                                  },
                                                  child: Text(
                                                    t.teamFormat == 'solo' ? 'स्लॉट बुक करें (REGISTER SLOT)' : 'स्क्वाड बनाएं / कोड जोड़ें (SQUAD)',
                                                    style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchTimeStrip(FFTournament t) {
    final isScheduled = t.scheduleType == 'scheduled' && t.scheduledTime.isNotEmpty;
    DateTime? schedTime;
    Duration? diff;
    if (isScheduled) {
      schedTime = DateTime.tryParse(t.scheduledTime);
      if (schedTime != null) {
        diff = schedTime.difference(DateTime.now());
      }
    }

    final isFull = t.filledSlots >= t.totalSlots;
    final isLive = t.status == 'LIVE' || (diff != null && diff.isNegative && diff.inMinutes.abs() < 90);

    Color bg;
    Color border;
    IconData icon;
    String mainText;
    String subText;

    if (isLive) {
      bg = AppTheme.errorRed.withValues(alpha: 0.15);
      border = AppTheme.errorRed;
      icon = Icons.radio_button_checked;
      mainText = '🔴 मैच लाइव है / कस्टम रूम खुला है';
      subText = t.matchTimeText;
    } else if (isScheduled && diff != null && !diff.isNegative) {
      final hours = diff.inHours.toString().padLeft(2, '0');
      final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
      bg = AppTheme.primaryGold.withValues(alpha: 0.12);
      border = AppTheme.primaryGold;
      icon = Icons.hourglass_top;
      mainText = '⏳ शुरू होने में: ${hours}h : ${minutes}m : ${seconds}s';
      subText = 'समय: ${t.matchTimeText}';
    } else if (isFull) {
      bg = AppTheme.saffronOrange.withValues(alpha: 0.15);
      border = AppTheme.saffronOrange;
      icon = Icons.whatshot;
      mainText = '🔥 100% स्लॉट फुल! रूम 15 मिनट में खुलेगा';
      subText = t.matchTimeText;
    } else {
      bg = AppTheme.cyanAccent.withValues(alpha: 0.1);
      border = AppTheme.cyanAccent.withValues(alpha: 0.4);
      icon = Icons.bolt;
      mainText = '⚡ स्लॉट भरते ही मैच शुरू होगा';
      subText = 'केवल ${t.totalSlots - t.filledSlots} खिलाड़ी और चाहिए!';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: border.withValues(alpha: 0.4), width: 1),
          bottom: BorderSide(color: border.withValues(alpha: 0.4), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: border, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mainText,
                  style: GoogleFonts.rajdhani(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: border,
                  ),
                ),
                Text(
                  subText,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isScheduled && diff != null && !diff.isNegative)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: border.withValues(alpha: 0.4)),
              ),
              child: Text(
                'LIVE TIMER',
                style: GoogleFonts.rajdhani(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: border,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
