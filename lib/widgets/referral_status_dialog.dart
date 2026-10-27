import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class ReferralStatusDialog extends StatefulWidget {
  final AppState appState;
  const ReferralStatusDialog({super.key, required this.appState});

  static Future<void> show(BuildContext context, AppState appState) async {
    await appState.fetchMyReferrals();
    if (!context.mounted) return;
    return showDialog(
      context: context,
      builder: (ctx) => ReferralStatusDialog(appState: appState),
    );
  }

  @override
  State<ReferralStatusDialog> createState() => _ReferralStatusDialogState();
}

class _ReferralStatusDialogState extends State<ReferralStatusDialog> {
  bool _isLoading = false;

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await widget.appState.fetchMyReferrals();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _share() async {
    final code = widget.appState.user.referralCode;
    final text = '🔥 Free Fire India Esports App! 100% Free Entry custom rooms mein khelo aur Google Play Redeem Codes jeeto! Mera referral code: $code use karo for +10 Bonus Coins! 🚀 Download now: https://vps.swgayanbhumi.in/app/';
    final url = 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: text));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('शेयर लिंक कॉपी हो गया!')));
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('शेयर लिंक कॉपी हो गया!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.appState.user;
    final referrals = widget.appState.myReferrals;
    final totalEarned = widget.appState.totalReferralCoinsEarned;
    final pendingCount = widget.appState.pendingReferralsCount;
    final unlockedCount = widget.appState.unlockedReferralsCount;

    return Dialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group_add, color: AppTheme.primaryGold, size: 24),
                    const SizedBox(width: 8),
                    Text('रेफर करें और 50 कॉइन्स पाएं', style: AppTheme.gamingTitle(fontSize: 18)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Flexible content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Rule explanation card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified, color: AppTheme.primaryGold, size: 16),
                              const SizedBox(width: 6),
                              Text('🎯 रेफरल रिवॉर्ड नियम', style: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '• आपके दोस्त को कोड डालने पर तुरंत +10 बोनस कॉइन्स मिलेंगे।\n• जब आपका दोस्त 5 टूर्नामेंट मैच खेल लेगा (5 Matches Entry), तब आपको +50 कॉइन्स आपके वॉलेट में मिलेंगे!',
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Referral Code Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGold),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('आपका रेफरल कोड', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              Text(user.referralCode, style: GoogleFonts.rajdhani(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppTheme.primaryGold)),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy, color: AppTheme.primaryGold),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: user.referralCode));
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('रेफरल कोड कॉपी हो गया!')));
                                },
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.share, size: 16),
                                label: const Text('शेयर', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: _share,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Summary Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatBadge('कुल दोस्त', '${referrals.length}', Colors.blueAccent),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatBadge('बाकी (Pending)', '$pendingCount', Colors.orangeAccent),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatBadge('अनलॉक्ड', '$unlockedCount (+$totalEarned)', Colors.greenAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Friends live tracking list header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('👥 आमंत्रित दोस्तों का स्टेटस (${referrals.length})', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        if (_isLoading)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGold))
                        else
                          InkWell(
                            onTap: _refresh,
                            child: const Row(
                              children: [
                                Icon(Icons.refresh, size: 14, color: AppTheme.primaryGold),
                                SizedBox(width: 4),
                                Text('रिफ्रेश', style: TextStyle(color: AppTheme.primaryGold, fontSize: 11)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Friends List or Empty state
                    if (referrals.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.person_outline, size: 36, color: Colors.white30),
                            SizedBox(height: 8),
                            Text(
                              'अभी तक किसी दोस्त ने आपका कोड उपयोग नहीं किया है।\nऊपर से अपना कोड शेयर करें और जब वे 5 मैच खेलेंगे तो आपको +50 कॉइन्स मिलेंगे!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: referrals.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = referrals[index];
                          final name = item['name'] ?? 'Player';
                          final inGameName = item['inGameName'] ?? '';
                          final matches = (item['matchesPlayed'] as num?)?.toInt() ?? 0;
                          final target = (item['targetMatches'] as num?)?.toInt() ?? 5;
                          final rem = (item['remainingMatches'] as num?)?.toInt() ?? 0;
                          final isUnlocked = item['isUnlocked'] == true;
                          final progress = (matches / target).clamp(0.0, 1.0);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUnlocked ? Colors.green.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isUnlocked ? Colors.green.withValues(alpha: 0.4) : Colors.white12,
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
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor: isUnlocked ? Colors.green.withValues(alpha: 0.2) : Colors.white10,
                                          child: Icon(
                                            isUnlocked ? Icons.check : Icons.person,
                                            size: 16,
                                            color: isUnlocked ? Colors.greenAccent : Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            if (inGameName.isNotEmpty && inGameName != name)
                                              Text(
                                                'IGN: $inGameName',
                                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isUnlocked ? Colors.green.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isUnlocked ? Colors.greenAccent : Colors.amber,
                                        ),
                                      ),
                                      child: Text(
                                        isUnlocked ? '✅ +50 कॉइन्स मिले' : '⏳ $rem मैच बाकी',
                                        style: TextStyle(
                                          color: isUnlocked ? Colors.greenAccent : Colors.amber,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.white10,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isUnlocked ? Colors.greenAccent : AppTheme.primaryGold,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'प्रोग्रेस: $matches/$target मैच खेले',
                                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                                    ),
                                    Text(
                                      isUnlocked ? 'रिवॉर्ड अनलॉक हो गया!' : '5 मैच पूरे होने पर +50 कॉइन्स',
                                      style: TextStyle(
                                        color: isUnlocked ? Colors.greenAccent : Colors.white38,
                                        fontSize: 10,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 2),
          Text(val, style: GoogleFonts.rajdhani(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
