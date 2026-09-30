import 'package:flutter/material.dart';
import '../models/voucher_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ff_brand_elements.dart';
import '../services/ad_service.dart';

class EarnCoinsScreen extends StatefulWidget {
  final AppState appState;

  const EarnCoinsScreen({super.key, required this.appState});

  @override
  State<EarnCoinsScreen> createState() => _EarnCoinsScreenState();
}

class _EarnCoinsScreenState extends State<EarnCoinsScreen> {
  int activeTab = 0; // 0: Watch & Earn, 1: Rewards Store

  void _showRedeemDialog(StoreItem item) {
    final whatsappController = TextEditingController(text: widget.appState.user.phoneNumber);
    final uidController = TextEditingController(text: widget.appState.user.inGameUid);
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(item.iconEmoji, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'REWARD REDEMPTION',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.amber),
                              ),
                              Text(item.title, style: AppTheme.gamingTitle(fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cost in Coins:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(
                          '${item.rewardCoinsPrice} 🎟️ Coins',
                          style: AppTheme.gamingNumber(fontSize: 16, color: const Color(0xFF78350F)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'ENTER YOUR WHATSAPP NUMBER',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'e.g. +91 9876543210',
                      prefixIcon: const Icon(Icons.phone, color: Colors.green, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'FREE FIRE UID (FOR TOP-UP)',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: uidController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 284719284',
                      prefixIcon: const Icon(Icons.sports_esports, color: Colors.amber, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),

                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (whatsappController.text.trim().length < 8) {
                          setDialogState(() => errorText = 'Please enter a valid WhatsApp Number.');
                          return;
                        }

                        final res = widget.appState.redeemStoreItem(
                          item: item,
                          whatsappNumber: whatsappController.text.trim(),
                          inGameUid: uidController.text.trim(),
                        );

                        Navigator.of(context).pop();

                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: AppTheme.winningGreen, size: 52),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Redemption Submitted!',
                                    style: AppTheme.gamingTitle(fontSize: 18, color: const Color(0xFF065F46)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    res['message'],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F172A),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('OKAY'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'CONFIRM & REDEEM (${item.rewardCoinsPrice} COINS)',
                        style: AppTheme.gamingTitle(fontSize: 13, color: Colors.white, isItalic: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.appState.user;
    user.adTracker.checkAndResetDaily();
    final tracker = user.adTracker;
    final progress = tracker.adsWatchedSinceLastCoin / 3.0;

    return Stack(
      children: [
        Positioned(
          right: -30,
          top: 30,
          child: const FfWatermark(size: 200, opacity: 0.04),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Segmented Navigation Header
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => activeTab = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: activeTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '🟡 Watch Ads (Earn Coins)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: activeTab == 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => activeTab = 1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: activeTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎁 Rewards Store', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              '${user.wallet.rewardCoins}🎟️',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (activeTab == 0) ...[
            // Tab 1: Rewarded Ads Hub
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF78350F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '3 ADS = 1 AD COIN 🟡',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Watch & Earn Free Coins',
                    style: AppTheme.gamingTitle(fontSize: 22, color: const Color(0xFF78350F)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Collect 🟡 Ad Coins to join Free Fire tournaments without spending real money!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress: ${tracker.adsWatchedSinceLastCoin} / 3 Ads Watched',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            Text(
                              '${3 - tracker.adsWatchedSinceLastCoin} more for 1 Coin',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryAmber),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        AdService.showRewardedAd(
                          context: context,
                          onUserEarnedReward: () {
                            final res = widget.appState.watchRewardedAd();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.amber.shade900,
                                  content: Text(res['message']),
                                ),
                              );
                            }
                          },
                        );
                      },
                      icon: const Icon(Icons.play_circle_fill, color: Colors.amber, size: 20),
                      label: Text(
                        'WATCH REWARDED AD (${tracker.dailyLimitRemaining} LEFT TODAY)',
                        style: AppTheme.gamingTitle(fontSize: 13, color: Colors.white, isItalic: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Tab 2: Rewards Store (Exchange Winning Coins for Play Codes & Diamonds)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR REWARD COINS BALANCE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text('🎟️', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 4),
                          Text(
                            '${user.wallet.rewardCoins} Coins',
                            style: AppTheme.gamingNumber(fontSize: 20, color: const Color(0xFF1E3A8A)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Text(
                    'Won in Free Matches\nRedeem for Codes & 💎',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Store Catalog Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.appState.storeItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final item = widget.appState.storeItems[index];
                final canRedeem = user.wallet.rewardCoins >= item.rewardCoinsPrice;

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(item.iconEmoji, style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                            maxLines: 2,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.rewardCoinsPrice} 🎟️ Coins',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canRedeem ? const Color(0xFF0F172A) : Colors.grey.shade300,
                                foregroundColor: canRedeem ? Colors.white : Colors.grey.shade600,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: canRedeem ? () => _showRedeemDialog(item) : null,
                              child: Text(
                                canRedeem ? 'REDEEM' : 'NEED COINS',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
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
}
