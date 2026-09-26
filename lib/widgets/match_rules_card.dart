import 'package:flutter/material.dart';
import 'ff_brand_elements.dart';

class MatchRulesCard extends StatefulWidget {
  final bool initiallyExpanded;

  const MatchRulesCard({
    super.key,
    this.initiallyExpanded = false,
  });

  @override
  State<MatchRulesCard> createState() => _MatchRulesCardState();
}

class _MatchRulesCardState extends State<MatchRulesCard> {
  late bool isExpanded;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => isExpanded = !isExpanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Image.asset('imgasest/FF_SHORT_LOGO.PNG.png', width: 16, height: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OFFICIAL MATCH RULES (नियम व शर्तें)',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF92400E),
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          'Min Level 40+ • Mobile Only • No Hacks • Mandatory POV',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9.5,
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      'LVL 40+',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.red.shade900),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF92400E),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFFDE68A)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRuleItem(
                    title: '1. Minimum FF Account Level 40+ (Anti-Hack):',
                    desc: 'Player ki Free Fire ID ka level minimum 40 ya usse zyada hona compulsory hai. Hack prevention ke liye 40 se kam level wali IDs ko room se bina refund kick/disqualify kar diya jayega.',
                    isCrucial: true,
                  ),
                  const SizedBox(height: 8),
                  _buildRuleItem(
                    title: '2. No Emulator / Tablets (Mobile Only):',
                    desc: 'Sirf Android & iOS Mobile phones allowed hain. PC, BlueStacks, LDPlayer, emulators aur tablet devices strictly banned hain.',
                  ),
                  const SizedBox(height: 8),
                  _buildRuleItem(
                    title: '3. No Hacks / Third-Party Apps:',
                    desc: 'Kisi bhi type ka Hack, Config files, Headshot scripts, Antenna, ya Modded APK use karne par instant ban aur account terminate hoga.',
                  ),
                  const SizedBox(height: 8),
                  _buildRuleItem(
                    title: '4. POV / Screen Recording Mandatory:',
                    desc: 'Har player ko gameplay / final circle ka POV screen record karna mandatory hai taaki dispute aane par fair play verify kiya ja sake.',
                  ),
                  const SizedBox(height: 8),
                  _buildRuleItem(
                    title: '5. No Teaming / Ghosting:',
                    desc: 'Enemy team se Teaming karna ya Stream Sniping/Ghosting karna sakht mana hai. Aisa karne par zero prize aur permanent ban milega.',
                  ),
                  const SizedBox(height: 8),
                  _buildRuleItem(
                    title: '6. IGN & UID Verification (Mandatory):',
                    desc: 'App mein register kiya hua Free Fire In-Game Name (IGN) aur numeric UID room ke player se match hona zaroori hai. Wrong UID disqualified hoga.',
                  ),
                  const SizedBox(height: 8),
                  _buildRuleItem(
                    title: '7. Punctuality (समय के पाबंद):',
                    desc: 'Room ID & Password match shuru hone se 15 minute pehle publish hoga. Jo team/player time par (min 5 min pehle) nahi aayegi, match unke bina hi start ho jayega.',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRuleItem({required String title, required String desc, bool isCrucial = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FfBulletPoint(size: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: isCrucial ? Colors.red.shade900 : const Color(0xFF78350F),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: Color(0xFF475569),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
