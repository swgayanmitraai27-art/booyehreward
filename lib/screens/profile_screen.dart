import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/ff_brand_elements.dart';
import '../widgets/match_rules_card.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppState appState;

  const ProfileScreen({super.key, required this.appState});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _uidController;
  late TextEditingController _levelController;
  String? errorText;
  bool isSaved = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.appState.user.inGameName);
    _uidController = TextEditingController(text: widget.appState.user.inGameUid);
    _levelController = TextEditingController(text: widget.appState.user.inGameLevel.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _uidController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.appState.user;
    final stats = user.stats;
    final isLevelEligible = user.inGameLevel >= 40;

    return Stack(
      children: [
        Positioned(
          right: -30,
          bottom: 40,
          child: const FfWatermark(size: 220, opacity: 0.04),
        ),

        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User ID Card
              Container(
                padding: const EdgeInsets.all(18),
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryAmber,
                      child: Text(
                        (user.inGameName != null && user.inGameName!.isNotEmpty)
                            ? user.inGameName![0].toUpperCase()
                            : (user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'B'),
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                user.displayName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const FreeFireLogoInline(height: 14),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'IGN: ${user.inGameName}',
                                style: const TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isLevelEligible ? const Color(0xFFECFDF5) : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: isLevelEligible ? const Color(0xFFA7F3D0) : Colors.red.shade300),
                                ),
                                child: Text(
                                  'LVL ${user.inGameLevel} ${isLevelEligible ? '✓' : '⚠️ <40'}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: isLevelEligible ? const Color(0xFF065F46) : Colors.red.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'FF UID: ${user.inGameUid}',
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'PLAYER CAREER STATS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.6,
                children: [
                  _buildStatCard('MATCHES PLAYED', '${stats.matchesPlayed}', Icons.sports_esports, Colors.blue),
                  _buildStatCard('BOOYAHS WON', '${stats.matchesWon}', Icons.emoji_events, AppTheme.primaryAmber),
                  _buildStatCard('TOTAL KILLS', '${stats.totalKills}', Icons.crisis_alert, Colors.red),
                  widget.appState.isRealCashModeEnabled
                      ? _buildStatCard('TOTAL WON (₹)', '₹${stats.totalWinningsCash.toInt()}', Icons.currency_rupee, AppTheme.winningGreen)
                      : _buildStatCard('REWARD COINS WON', '${stats.totalRewardCoinsWon} 🎟️', Icons.stars, AppTheme.winningGreen),
                ],
              ),
              const SizedBox(height: 18),

              // Match Rules Card
              const MatchRulesCard(initiallyExpanded: false),
              const SizedBox(height: 18),

              const Text(
                'UPDATE FREE FIRE IN-GAME DETAILS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'In-Game Name (IGN)*',
                        prefixIcon: const Icon(Icons.person, color: AppTheme.primaryAmber, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _uidController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Free Fire UID (Numeric)*',
                              prefixIcon: const Icon(Icons.sports_esports, color: AppTheme.primaryAmber, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _levelController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'FF ID Level (40+)*',
                              hintText: 'e.g. 52',
                              prefixIcon: const Icon(Icons.shield, color: Colors.blue, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Color(0xFF64748B)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Note: Ye aapki Free Fire Game Profile ka Account Level hai (App level nahi). Hack prevention ke liye minimum Level 40+ hona compulsory hai.',
                              style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                    const SizedBox(height: 14),

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
                          final ign = _nameController.text.trim();
                          final uid = _uidController.text.trim();
                          final level = int.tryParse(_levelController.text.trim()) ?? 0;

                          if (ign.isEmpty) {
                            setState(() => errorText = 'Free Fire In-Game Name (IGN) zaroori hai.');
                            return;
                          }
                          if (uid.isEmpty || uid.length < 6) {
                            setState(() => errorText = 'Valid numeric Free Fire UID zaroori hai (min 6 digits).');
                            return;
                          }
                          if (level < 40) {
                            setState(() => errorText = 'Anti-Hack Rule: Minimum Free Fire Level 40+ hona zaroori hai!');
                            return;
                          }

                          widget.appState.updateUserProfile(
                            inGameName: ign,
                            inGameUid: uid,
                            inGameLevel: level,
                          );
                          setState(() {
                            isSaved = true;
                            errorText = null;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppTheme.winningGreen,
                              content: Text('Free Fire details & Level updated successfully!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text(
                          'SAVE FREE FIRE DETAILS',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await widget.appState.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => AuthScreen(appState: widget.appState)),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                  label: const Text(
                    'LOGOUT ACCOUNT',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w800, color: Colors.redAccent),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    backgroundColor: const Color(0xFFFFF1F2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
