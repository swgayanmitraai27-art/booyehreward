import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../services/app_state.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';
import 'match_rules_card.dart';

class SlotPickerDialog extends StatefulWidget {
  final MatchModel match;
  final AppState appState;
  final VoidCallback onEarnCoinsClick;

  const SlotPickerDialog({
    super.key,
    required this.match,
    required this.appState,
    required this.onEarnCoinsClick,
  });

  @override
  State<SlotPickerDialog> createState() => _SlotPickerDialogState();
}

class _SlotPickerDialogState extends State<SlotPickerDialog> {
  int? selectedSlot;
  late TextEditingController _ignController;
  late TextEditingController _uidController;
  late TextEditingController _levelController;
  String? errorText;
  bool isSubmitting = false;
  bool _isWatchingAd = false;

  @override
  void initState() {
    super.initState();
    _ignController = TextEditingController(text: widget.appState.user.inGameName);
    _uidController = TextEditingController(text: widget.appState.user.inGameUid);
    _levelController = TextEditingController(text: widget.appState.user.inGameLevel.toString());
  }

  @override
  void dispose() {
    _ignController.dispose();
    _uidController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final ign = _ignController.text.trim();
    final uid = _uidController.text.trim();
    final levelStr = _levelController.text.trim();
    final level = int.tryParse(levelStr);

    if (ign.isEmpty) {
      setState(() => errorText = 'Free Fire In-Game Name (IGN) daalna mandatory hai.');
      return false;
    }
    if (uid.isEmpty || uid.length < 6 || int.tryParse(uid) == null) {
      setState(() => errorText = 'Valid numeric Free Fire UID daalna zaroori hai (min 6 digits).');
      return false;
    }
    if (level == null || level < 40) {
      setState(() => errorText = 'Anti-Hack Rule: Minimum Free Fire Account Level 40+ hona anivarya hai (Aapka level: ${levelStr.isEmpty ? '0' : levelStr}).');
      return false;
    }
    setState(() => errorText = null);
    return true;
  }

  void _executeJoin() {
    if (selectedSlot == null) {
      setState(() => errorText = 'Please select a slot from the grid above.');
      return;
    }

    if (!_validateForm()) return;

    final ign = _ignController.text.trim();
    final uid = _uidController.text.trim();
    final level = int.tryParse(_levelController.text.trim()) ?? 40;

    widget.appState.updateUserProfile(
      inGameName: ign,
      inGameUid: uid,
      inGameLevel: level,
    );

    setState(() => isSubmitting = true);
    final res = widget.appState.joinMatchWithSlot(
      matchId: widget.match.id,
      chosenSlot: selectedSlot!,
      inGameName: ign,
      inGameUid: uid,
    );
    setState(() => isSubmitting = false);

    if (res['success'] == true) {
      Navigator.of(context).pop();
      AdService.showInterstitialAd(context: context, force: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF065F46),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(res['message'] ?? 'Slot #$selectedSlot successfully booked!')),
            ],
          ),
        ),
      );
    } else {
      setState(() {
        errorText = res['message'];
      });
    }
  }

  void _watchAdToEarnCoin() {
    setState(() => _isWatchingAd = true);
    AdService.showRewardedAd(
      context: context,
      onUserEarnedReward: () {
        if (!mounted) return;
        final res = widget.appState.watchRewardedAd();
        setState(() => _isWatchingAd = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: res['coinAwarded'] == true ? const Color(0xFF065F46) : Colors.amber.shade900,
            content: Text(res['message'] ?? 'Ad completed!'),
          ),
        );
      },
      onAdDismissed: () {
        if (mounted && _isWatchingAd) {
          setState(() => _isWatchingAd = false);
        }
      },
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isWatchingAd) {
        setState(() => _isWatchingAd = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final userCoins = widget.appState.user.wallet.adCoins;
    final int feeCoins = match.entryFee.toInt();
    final bool hasEnoughCoins = feeCoins == 0 || userCoins >= feeCoins;
    final int adsWatchedSinceCoin = widget.appState.user.adTracker.adsWatchedSinceLastCoin;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 720),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.primaryAmber,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Text('🟡', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feeCoins == 0 ? 'FREE DIRECT ENTRY' : 'ENTRY FEE: 🟡 $feeCoins ${feeCoins == 1 ? "COIN" : "COINS"}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Color(0xFF78350F),
                          ),
                        ),
                        Text(
                          'Choose Your Match Slot',
                          style: AppTheme.gamingTitle(
                            fontSize: 18,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Match summary & Ad Coins Wallet status
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${match.matchFormat.name.toUpperCase()} • ${match.map.name.toUpperCase()} • Prize: ${match.prizePool.isCashPrize ? '₹${match.prizePool.totalPool.toInt()}' : '${match.prizePool.totalPool.toInt()} 🎟️ Coins'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              match.entryFeeDisplay,
                              style: AppTheme.gamingNumber(
                                fontSize: 13,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // User Ad Coins Balance Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: hasEnoughCoins ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasEnoughCoins ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '🟡 Your Ad Coins:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: hasEnoughCoins ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$userCoins 🟡',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: hasEnoughCoins ? const Color(0xFF047857) : const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                          if (!hasEnoughCoins)
                            InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.onEarnCoinsClick();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade900,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'EARN COINS',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Slot Picker Grid Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SELECT YOUR DESIRED SLOT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Color(0xFF475569),
                          ),
                        ),
                        Text(
                          selectedSlot != null ? 'Selected: Slot #$selectedSlot' : 'Tap a slot to pick',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: selectedSlot != null ? Colors.amber.shade800 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Slot Matrix Grid
                    Container(
                      height: 180,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: GridView.builder(
                        itemCount: match.maxSlots,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemBuilder: (context, index) {
                          final slotNum = index + 1;
                          final isTaken = match.isSlotTaken(slotNum);
                          final isSelected = selectedSlot == slotNum;
                          final participant = match.getParticipantBySlot(slotNum);

                          return InkWell(
                            onTap: isTaken
                                ? null
                                : () {
                                    setState(() {
                                      selectedSlot = slotNum;
                                      errorText = null;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isTaken
                                    ? const Color(0xFFE2E8F0)
                                    : isSelected
                                        ? AppTheme.primaryAmber
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isTaken
                                      ? const Color(0xFFCBD5E1)
                                      : isSelected
                                          ? const Color(0xFFB45309)
                                          : const Color(0xFF94A3B8),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '#$slotNum',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: isTaken
                                          ? const Color(0xFF94A3B8)
                                          : isSelected
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    isTaken ? (participant?.inGameName.substring(0, 3) ?? 'TAKEN') : 'FREE',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: isTaken ? Colors.red.shade400 : AppTheme.winningGreen,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Match Rules Card
                    const MatchRulesCard(initiallyExpanded: false),
                    const SizedBox(height: 14),

                    // In-Game Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FREE FIRE IN-GAME DETAILS (MANDATORY)',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Auto-Saves to Profile', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _ignController,
                      decoration: InputDecoration(
                        labelText: 'Free Fire In-Game Name (IGN)*',
                        hintText: 'e.g. ꧁★RAJ★꧂',
                        labelStyle: const TextStyle(fontSize: 12),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _uidController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Free Fire Numeric UID*',
                              hintText: 'e.g. 294819284',
                              labelStyle: const TextStyle(fontSize: 12),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _levelController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'FF Level (40+)*',
                              hintText: 'e.g. 52',
                              labelStyle: const TextStyle(fontSize: 12),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // If Insufficient coins: Show Quick Watch Ad Widget
                    if (!hasEnoughCoins) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFFB45309), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Watch 3 Ads = 1 🟡 Ad Coin',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF92400E)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Progress: $adsWatchedSinceCoin/3 Ads watched towards next coin.',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB45309),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _isWatchingAd ? null : _watchAdToEarnCoin,
                              child: Text(
                                _isWatchingAd ? '...' : '🎬 WATCH AD',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorText!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (selectedSlot != null && hasEnoughCoins)
                            ? AppTheme.primaryAmber
                            : (!hasEnoughCoins ? Colors.amber.shade700 : Colors.grey.shade300),
                        foregroundColor: (selectedSlot != null && hasEnoughCoins)
                            ? Colors.black
                            : (!hasEnoughCoins ? Colors.white : Colors.grey.shade600),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: (selectedSlot != null && !isSubmitting && !_isWatchingAd)
                          ? (hasEnoughCoins ? _executeJoin : _watchAdToEarnCoin)
                          : null,
                      child: Text(
                        selectedSlot == null
                            ? 'PICK A SLOT ABOVE'
                            : _isWatchingAd
                                ? 'PLAYING AD...'
                                : isSubmitting
                                    ? 'LOCKING SLOT...'
                                    : (!hasEnoughCoins
                                        ? '🎬 WATCH AD ($adsWatchedSinceCoin/3) TO EARN COIN'
                                        : (feeCoins == 0
                                            ? 'CONFIRM & LOCK SLOT #$selectedSlot (FREE)'
                                            : 'CONFIRM & LOCK SLOT #$selectedSlot (🟡 $feeCoins ${feeCoins == 1 ? "COIN" : "COINS"})')),
                        style: AppTheme.gamingTitle(
                          fontSize: 13,
                          color: (selectedSlot != null && hasEnoughCoins) ? Colors.black : Colors.white,
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
      ),
    );
  }
}
