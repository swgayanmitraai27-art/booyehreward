import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'legal_policy_screen.dart';
import 'support_screen.dart';
import 'wallet_screen.dart';
import '../widgets/referral_status_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final AppState appState;

  const ProfileScreen({super.key, required this.appState});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _openEditProfileDialog() {
    final ignController = TextEditingController(text: widget.appState.user.inGameName);
    final uidController = TextEditingController(text: widget.appState.user.inGameId);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.primaryGold)),
        title: Text('EDIT GAMER PROFILE', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Free Fire In-Game Name (IGN)', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            TextField(controller: ignController, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Free Fire Numeric UID', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            TextField(controller: uidController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.black),
            onPressed: () async {
              if (ignController.text.trim().isEmpty) return;
              widget.appState.user.inGameName = ignController.text.trim();
              widget.appState.user.displayName = ignController.text.trim();
              widget.appState.user.inGameId = uidController.text.trim();
              await widget.appState.saveUser();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReferralCode() async {
    final code = widget.appState.user.referralCode;
    final text = '🔥 Free Fire India: India Ka Apna Esports Platform! Daily Free Custom Rooms khelo aur Booyah karke Google Play Redeem Codes jeeto! Use my code $code on signup for +20 Welcome Coins! 🚀';
    final url = 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: text));
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  Future<void> _launchUrl(String url) async {
    if (url.trim().isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final user = widget.appState.user;
        final social = widget.appState.socialLinks;

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              // ── 1. FREE FIRE GAMER PROFILE CARD ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryGold, width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 28,
                            backgroundColor: Color(0xFF1E293B),
                            backgroundImage: AssetImage('assets/imgasest/booyah_hero_logo.png'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.inGameName.isNotEmpty ? user.inGameName : user.displayName,
                                style: GoogleFonts.rajdhani(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'UID: ${user.inGameId.isNotEmpty ? user.inGameId : user.uid}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppTheme.primaryGold, size: 20),
                          onPressed: _openEditProfileDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Stats Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox('BOOYAH WINS', '${user.totalWins}', AppTheme.successGreen),
                        _buildStatBox('TOTAL KILLS', '${user.totalKills}', AppTheme.saffronOrange),
                        _buildStatBox('COINS', '${user.adCoins}', AppTheme.primaryGold),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── 2. 100% IN-APP CUSTOMER SUPPORT DESK BANNER ──
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SupportScreen(appState: widget.appState)),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cyanAccent, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cyanAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.cyanAccent),
                        ),
                        child: const Icon(Icons.headset_mic, color: AppTheme.cyanAccent, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '100% IN-APP SUPPORT',
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.cyanAccent,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.successGreen.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('ADMIN ONLINE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Got an issue with Room ID, Password, or Coins? Ask Admin directly in-app.',
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: AppTheme.cyanAccent, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── 3. VIRAL SQUAD REFER & EARN ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('REFER YOUR SQUAD & EARN', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                        const Icon(Icons.group_add, color: AppTheme.primaryGold, size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• दोस्त आपके कोड से साइन-अप करेगा -> उसे तुरंत +10 बोनस कॉइन्स मिलेंगे!\n• दोस्त 5 टूर्नामेंट मैच खेलेगा -> आपको +50 कॉइन्स आपके वॉलेट में मिलेंगे!',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.bgDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  user.referralCode,
                                  style: GoogleFonts.rajdhani(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppTheme.primaryGold),
                                ),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: user.referralCode));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral code copied!')));
                                  },
                                  child: const Icon(Icons.copy, color: AppTheme.primaryGold, size: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          icon: const Icon(Icons.share, size: 16),
                          label: Text('WHATSAPP', style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.bold)),
                          onPressed: _shareReferralCode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGold,
                        side: const BorderSide(color: AppTheme.primaryGold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.people_alt_outlined, size: 18),
                      label: Text('👥 आमंत्रित दोस्तों का स्टेटस देखें (Live Tracking)', style: GoogleFonts.rajdhani(fontSize: 13, fontWeight: FontWeight.bold)),
                      onPressed: () => ReferralStatusDialog.show(context, widget.appState),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── 4. OFFICIAL SOCIAL COMMUNITY HUBS ──
              Text('OFFICIAL SOCIAL COMMUNITY', style: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildSocialCard(
                      label: 'YouTube',
                      icon: Icons.play_arrow,
                      color: const Color(0xFFFF0000),
                      onTap: () => _launchUrl(social['youtube'] ?? 'https://youtube.com/@booyahrewards'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSocialCard(
                      label: 'Instagram',
                      icon: Icons.camera_alt,
                      color: const Color(0xFFE4405F),
                      onTap: () => _launchUrl(social['instagram'] ?? 'https://instagram.com/booyahrewards'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSocialCard(
                      label: 'Telegram',
                      icon: Icons.send,
                      color: const Color(0xFF0088CC),
                      onTap: () => _launchUrl(social['telegram'] ?? 'https://t.me/booyahrewards'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── 5. LEGAL & APP VERSION ──
              Container(
                decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.account_balance_wallet, color: AppTheme.primaryGold),
                      title: const Text('My Wallet & Withdrawals', style: TextStyle(fontSize: 13, color: Colors.white)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => WalletScreen(appState: widget.appState)));
                      },
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.policy, color: AppTheme.cyanAccent),
                      title: const Text('Fair Play Terms & Privacy Policy', style: TextStyle(fontSize: 13, color: Colors.white)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPolicyScreen()));
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: Text(
                  'BOOYAH REWARDS • v1.3.9+39\nIndia Ka Apna Esports Platform. Zero Entry Fee, Infinite Glory!\nCommunity Tournament Platform • Not affiliated with Garena',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white38, height: 1.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.rajdhani(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSocialCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
