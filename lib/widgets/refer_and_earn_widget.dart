import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_state.dart';
import '../utils/url_launcher_util.dart';

class ReferAndEarnCard extends StatefulWidget {
  final AppState appState;

  const ReferAndEarnCard({super.key, required this.appState});

  @override
  State<ReferAndEarnCard> createState() => _ReferAndEarnCardState();
}

class _ReferAndEarnCardState extends State<ReferAndEarnCard> {
  final TextEditingController _refInputController = TextEditingController();
  bool _isApplying = false;
  String? _applyMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _refInputController.dispose();
    super.dispose();
  }

  void _copyReferralCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        content: Text('🎉 Referral Code $code copied to clipboard! Share with friends.'),
      ),
    );
  }

  void _shareOnWhatsApp(String code) {
    final shareText = Uri.encodeComponent(
      '🔥 Play Free Fire Tournaments & Win Real Cash on Booyah Rewards!\n\n'
      '🎁 Use my Referral Code *${code.toUpperCase()}* and BOTH of us will get 10 Bonus Coins instantly!\n\n'
      '👉 Join Now: https://booyehreward.vercel.app',
    );
    UrlLauncherUtil.openUrl('https://wa.me/?text=$shareText');
  }

  void _shareOnTelegram(String code) {
    final shareText = Uri.encodeComponent(
      '🔥 Play Free Fire Tournaments & Win Real Cash on Booyah Rewards!\n\n'
      '🎁 Use my Referral Code *${code.toUpperCase()}* and BOTH of us will get 10 Bonus Coins instantly!\n\n'
      '👉 Join Now: https://booyehreward.vercel.app',
    );
    UrlLauncherUtil.openUrl('https://t.me/share/url?url=https://booyehreward.vercel.app&text=$shareText');
  }

  Future<void> _handleApplyCode() async {
    final code = _refInputController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isApplying = true;
      _applyMessage = null;
    });

    final res = await widget.appState.applyReferralCode(code);

    if (mounted) {
      setState(() {
        _isApplying = false;
        _isSuccess = res['success'] == true;
        _applyMessage = res['message']?.toString() ?? 'Processed';
      });

      if (_isSuccess) {
        _refInputController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.appState.user;
    final myCode = user.referralCode.isNotEmpty ? user.referralCode : 'BYH77889';
    final hasReferredBy = user.referredBy != null && user.referredBy!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withAlpha(120)),
                ),
                child: const Row(
                  children: [
                    Text('🎁', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 5),
                    Text(
                      'REFER & EARN BONUS',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '10 Coins Each',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF34D399)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Description
          const Text(
            'Invite Friends & Both Get 10 Coins!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Share your code with friends. When they join, both of you receive 10 Bonus Cash + 10 Ad Coins for match entry.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), height: 1.3),
          ),
          const SizedBox(height: 14),

          // User's Unique Code Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withAlpha(25)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR REFERRAL CODE',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        myCode,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _copyReferralCode(myCode),
                  icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                  tooltip: 'Copy Code',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Share Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareOnWhatsApp(myCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _shareOnTelegram(myCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0088CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Telegram', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _copyReferralCode(myCode),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Referral Stats Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${user.totalReferrals}',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const Text('Friends Joined', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
                Container(height: 24, width: 1, color: Colors.white24),
                Column(
                  children: [
                    Text(
                      '${user.totalReferralCoins}',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w900, color: Colors.amber),
                    ),
                    const Text('Coins Earned', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 👥 FRIENDS JOINED LIST (Attribution)
          const Text(
            'FRIENDS WHO USED YOUR CODE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),

          Builder(
            builder: (context) {
              final myFriends = widget.appState.allGlobalReferralRecords
                  .where((r) => r.referrerCode == myCode || r.referrerUid == user.uid)
                  .toList();

              if (myFriends.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withAlpha(15)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.people_outline, color: Color(0xFF94A3B8), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No friends joined yet. Share your 6-digit code on WhatsApp to earn 10 coins for each friend!',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: myFriends.map((rec) {
                  final timeStr = '${rec.createdAt.day}/${rec.createdAt.month} ${rec.createdAt.hour.toString().padLeft(2, '0')}:${rec.createdAt.minute.toString().padLeft(2, '0')}';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withAlpha(20)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.amber,
                          child: Text(
                            rec.referredName.isNotEmpty ? rec.referredName[0].toUpperCase() : 'F',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rec.referredName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                              ),
                              Text(
                                'UID: ${rec.referredUid} • $timeStr',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF34D399).withAlpha(80)),
                          ),
                          child: const Text(
                            '+10 Coins ✓',
                            style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w900, fontSize: 9.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 14),

          // "Have a Referral Code?" Input Box
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),

          if (hasReferredBy) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF059669).withAlpha(90)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Referred by: ${user.referredBy} (10 Bonus Coins Claimed)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Text(
              'HAVE A FRIEND\'S REFERRAL CODE?',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _refInputController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter Referral Code',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withAlpha(15),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isApplying ? null : _handleApplyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isApplying
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Apply', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ],
            ),
            if (_applyMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                _applyMessage!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _isSuccess ? const Color(0xFF34D399) : Colors.redAccent,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
