import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ff_brand_elements.dart';

class BooyahFooter extends StatelessWidget {
  const BooyahFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          // Platform Header with BOOYAH_ICON
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'imgasest/BOOYAH_ICON.PNG.png',
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Text(
                  'BOOYAH REWARDS',
                  style: AppTheme.gamingTitle(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Crucial: "Made with ❤️ for [FREE_FIRE_LOGO.PNG.png] Lovers"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                const Text(
                  'MADE WITH ❤️ FOR',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                    letterSpacing: 0.8,
                  ),
                ),
                const FreeFireLogoInline(height: 18),
                const Text(
                  'LOVERS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryAmber,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Fair Play & Instant Payout bullet points with FF_SHORT_LOGO
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FfBulletPoint(size: 13),
              const Text(
                '100% Fair Play Verified',
                style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              const FfBulletPoint(size: 13),
              const Text(
                'Instant UPI & Voucher Payouts',
                style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '© 2026 Booyah Rewards Platform. All rights reserved.',
            style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
