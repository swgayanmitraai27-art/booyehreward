import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum LegalPolicyType { terms, privacy }

class LegalPolicyScreen extends StatefulWidget {
  final LegalPolicyType initialType;

  const LegalPolicyScreen({
    super.key,
    this.initialType = LegalPolicyType.terms,
  });

  @override
  State<LegalPolicyScreen> createState() => _LegalPolicyScreenState();
}

class _LegalPolicyScreenState extends State<LegalPolicyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialType == LegalPolicyType.terms ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyEmail(BuildContext context, String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 20),
            const SizedBox(width: 8),
            Text('Email copied: $email', style: GoogleFonts.inter(fontSize: 13)),
          ],
        ),
        backgroundColor: AppTheme.bgCard,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryGold, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'LEGAL & POLICIES',
          style: GoogleFonts.rajdhani(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppTheme.primaryGold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGold,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryGold,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: GoogleFonts.rajdhani(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          unselectedLabelStyle: GoogleFonts.rajdhani(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'TERMS & CONDITIONS', icon: Icon(Icons.gavel_outlined, size: 20)),
            Tab(text: 'PRIVACY POLICY', icon: Icon(Icons.policy_outlined, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTermsTab(context),
          _buildPrivacyTab(context),
        ],
      ),
    );
  }

  Widget _buildBadgeHeader({required String title, required String subtitle, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGold, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textWhite,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String number,
    required String title,
    required List<Widget> children,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.6)),
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: GoogleFonts.rajdhani(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryGold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (icon != null) Icon(icon, color: AppTheme.primaryGold.withValues(alpha: 0.7), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildParagraph(String text, {bool isMuted = false, FontWeight? fontWeight, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          height: 1.55,
          color: color ?? (isMuted ? AppTheme.textMuted : AppTheme.textWhite),
          fontWeight: fontWeight ?? FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildBullet(String boldPrefix, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 6, color: AppTheme.primaryGold),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AppTheme.textWhite),
                children: [
                  TextSpan(
                    text: boldPrefix,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                  ),
                  TextSpan(
                    text: description,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBadgeHeader(
          title: 'TERMS AND CONDITIONS',
          subtitle: 'Last Updated & Effective: October 13, 2026\nPROGA 2025 & DPDPA 2023 Compliant',
          icon: Icons.verified_user_outlined,
        ),

        _buildSectionCard(
          number: '1',
          title: 'ACCEPTANCE OF TERMS',
          children: [
            _buildParagraph(
              'By downloading, installing, or accessing this mobile application (the "Platform"), you agree to be legally bound by these Terms and Conditions ("T&C"). If you do not agree to these terms, you must immediately uninstall and discontinue use of the Platform.',
            ),
          ],
        ),

        _buildSectionCard(
          number: '2',
          title: 'ELIGIBILITY & STRICT AGE RESTRICTION (18+)',
          icon: Icons.person_off_outlined,
          children: [
            _buildParagraph(
              'Access to the Platform is strictly restricted to individuals who are eighteen (18) years of age or older. By accessing the Platform, you legally declare and warrant that you have completed 18 years of age.',
            ),
            _buildParagraph(
              'In strict compliance with Section 9 of the Digital Personal Data Protection Act (DPDPA), 2023, we do not permit minors to use the Platform, nor do we track, monitor, or serve targeted advertisements to children. Any account suspected of belonging to a minor will be immediately terminated, and all associated data will be permanently erased.',
              color: AppTheme.errorRed,
            ),
          ],
        ),

        _buildSectionCard(
          number: '3',
          title: 'NATURE OF PLATFORM: ONLINE SOCIAL GAME',
          icon: Icons.sports_esports_outlined,
          children: [
            _buildParagraph(
              'The Platform exclusively offers casual, skill-based mini-games (e.g., Knife Hit, Fruit Slash, Puzzles). The Platform is classified as an "Online Social Game" under Section 2(i) of the Promotion and Regulation of Online Gaming Act, 2025 (PROGA).',
            ),
            _buildBullet('Zero Deposit Policy: ', 'The Platform does not accept, require, or facilitate the deposit of real money, digital currency, or any other financial stake.'),
            _buildBullet('Not an Online Money Game: ', 'Because you do not wager, bet, or stake money to play, the Platform explicitly falls outside the definition of an "Online Money Game" under Section 2(g) of PROGA, 2025.'),
          ],
        ),

        _buildSectionCard(
          number: '4',
          title: 'AD-REWARD MECHANISM & VIRTUAL UTILITIES',
          icon: Icons.smart_display_outlined,
          children: [
            _buildParagraph(
              'The Platform is entirely free-to-play and is monetized via third-party advertising networks (including Google AdMob, Unity Ads, and AppLovin).',
            ),
            _buildBullet('In-Game Utilities Only: ', 'Watching Rewarded Video Ads grants strictly in-game virtual utilities (such as extra lives, revives, or score multipliers).'),
            _buildBullet('No Cash for Ads: ', 'Under no circumstances are users compensated with direct cash, monetary equivalents, or financial rewards simply for viewing or clicking advertisements. Virtual items hold no real-world monetary value and cannot be transferred, sold, or redeemed for cash.'),
          ],
        ),

        _buildSectionCard(
          number: '5',
          title: 'WEEKLY LEADERBOARD TOURNAMENT & PRIZES',
          icon: Icons.emoji_events_outlined,
          children: [
            _buildParagraph(
              'The Platform operates a Weekly Leaderboard Tournament governed by the following strict rules:',
            ),
            _buildBullet('No Purchase Necessary: ', 'Participation in the tournament is 100% free. No entry fee, subscription, or purchase is required to enter or win.'),
            _buildBullet('Skill-Based Outcome: ', 'Rankings are determined solely by the highest verified cumulative game score achieved through human physical dexterity, reflex, and cognitive skill.'),
            _buildBullet('Top 10 Distribution: ', 'The Top 10 ranked players on the weekly leaderboard will receive sponsored promotional prizes (e.g., Google Play Redeem Codes, Amazon Vouchers, or UPI transfers) funded entirely by the developer’s ad revenue pool.'),
            _buildBullet('Daily Payout & Wallet: ', 'Verified prize money/vouchers are automatically credited daily to the user’s In-App Wallet at 00:00:00 IST. Users can withdraw directly to their verified UPI or Google Play voucher inbox once reaching ₹50, post anti-fraud and ad-network reconciliation.'),
          ],
        ),

        _buildSectionCard(
          number: '6',
          title: 'TAXATION & TDS COMPLIANCE (SECTION 194BA)',
          icon: Icons.receipt_long_outlined,
          children: [
            _buildParagraph(
              'All promotional cash prizes disbursed via the Platform are subject to the Income Tax Act, 1961. Under Section 194BA and Rule 133, a flat 30% Tax Deducted at Source (TDS) applies to all "Net Winnings".',
            ),
            _buildBullet('Net Winnings Basis: ', 'Because the Platform requires zero deposits, your entire promotional prize constitutes Net Winnings.'),
            _buildBullet('Mandatory PAN Verification: ', 'We are legally mandated to deduct 30% TDS prior to processing cash payouts. To receive cash payouts, users must provide a valid Permanent Account Number (PAN) card. Failure to provide a PAN will result in the forfeiture of the cash prize. Users may alternatively elect to receive non-cash promotional digital vouchers where permissible under Indian law.'),
          ],
        ),

        _buildSectionCard(
          number: '7',
          title: 'ANTI-CHEAT, FAIR PLAY & ACCOUNT BAN',
          icon: Icons.security_outlined,
          children: [
            _buildParagraph(
              'The Platform relies on server-side validation, encrypted score signatures, and device fingerprinting to ensure competitive integrity. We enforce a zero-tolerance policy against cheating.',
            ),
            _buildParagraph(
              'Your account will be permanently banned, and all accumulated scores and unredeemed prizes will be immediately voided, if you use or attempt to use:',
              isMuted: true,
            ),
            _buildBullet('Prohibited Scripts: ', 'Auto-clicker scripts, bots, or macro automation software.'),
            _buildBullet('Client Tampering: ', 'Modified APKs, memory editors, or reverse-engineered clients.'),
            _buildBullet('Virtual Environments: ', 'Android emulators, rooted devices, or jailbroken operating systems to manipulate gameplay.'),
          ],
        ),

        _buildSectionCard(
          number: '8',
          title: 'PLATFORM & STORE DISCLAIMER',
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Google LLC, Alphabet Inc., and Apple Inc. are not sponsors of, nor are they involved in any capacity with, the Weekly Leaderboard Tournament, contests, sweepstakes, or the disbursement of any promotional prizes offered within this Platform.',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textWhite, height: 1.5),
              ),
            ),
          ],
        ),

        _buildSectionCard(
          number: '9',
          title: 'GRIEVANCE REDRESSAL MECHANISM',
          icon: Icons.contact_support_outlined,
          children: [
            _buildParagraph(
              'In compliance with the Information Technology (Intermediary Guidelines and Digital Media Ethics Code) Rules, 2021, we have appointed a Grievance Officer to address user complaints promptly.',
            ),
            _buildBullet('Grievance Officer: ', 'Aditya Maurya'),
            _buildBullet('Official Email: ', 'support@swgayanbhumi.in'),
            _buildBullet('Physical Jurisdiction: ', 'India'),
            _buildBullet('Resolution Timeline: ', 'Acknowledgement within 24 hours; resolution within 15 days of receipt.'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: AppTheme.bgDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _copyEmail(context, 'support@swgayanbhumi.in'),
              icon: const Icon(Icons.copy, size: 16),
              label: Text('Copy Grievance Email', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
            ),
          ],
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPrivacyTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBadgeHeader(
          title: 'PRIVACY POLICY',
          subtitle: 'Last Updated & Effective: October 13, 2026\nDigital Personal Data Protection Act (DPDPA) 2023 Compliant',
          icon: Icons.shield_outlined,
        ),

        _buildSectionCard(
          number: '1',
          title: 'INTRODUCTION',
          children: [
            _buildParagraph(
              'This Privacy Policy explains how we ("Data Fiduciary") collect, process, and protect your personal data when you use our Flutter-based mobile gaming application (the "Platform"). We are strictly committed to complying with the Digital Personal Data Protection Act (DPDPA), 2023.',
            ),
          ],
        ),

        _buildSectionCard(
          number: '2',
          title: 'STRICT PROHIBITION ON CHILDREN\'S DATA',
          icon: Icons.child_care_outlined,
          children: [
            _buildParagraph(
              'In absolute compliance with Section 9 of the DPDPA 2023, this Platform is strictly restricted to individuals aged 18 and older. We do not collect verifiable parental consent because we categorically prohibit minors from accessing the Platform.',
              color: AppTheme.errorRed,
              fontWeight: FontWeight.bold,
            ),
            _buildParagraph(
              'We do not engage in behavioral monitoring, tracking, or targeted advertising directed at children. If we become aware that a user is under 18, we will immediately delete their personal data and terminate their account.',
            ),
          ],
        ),

        _buildSectionCard(
          number: '3',
          title: 'DATA WE COLLECT & PURPOSE OF PROCESSING',
          icon: Icons.storage_outlined,
          children: [
            _buildParagraph(
              'We collect data strictly on the principles of data minimization and purpose limitation under the DPDPA 2023:',
            ),
            _buildBullet('Device & Analytics Data: ', 'We collect your Device ID (e.g., Google Advertising ID), IP address, device model, and gameplay analytics.\nPurpose: To serve contextual and personalized ads (via AdMob, Unity, AppLovin), track game performance, and conduct device fingerprinting for anti-cheat server-side validation.'),
            _buildBullet('KYC & Payout Details (Winners Only): ', 'If you rank in the Top 10 on the Weekly Leaderboard and qualify for a promotional prize, we collect your Name, PAN Card Number, and UPI ID/Bank Details (or email for digital gift vouchers).\nPurpose: To facilitate statutory TDS deduction under Section 194BA of the Income Tax Act, verify age/identity to prevent fraud, and process the legal disbursement of prize money through RBI-regulated payment aggregators.'),
          ],
        ),

        _buildSectionCard(
          number: '4',
          title: 'SHARING OF DATA WITH THIRD PARTIES',
          icon: Icons.share_outlined,
          children: [
            _buildParagraph(
              'Your personal data is never sold to third parties. We only share data with authorized Data Processors to fulfill the operational and legal requirements of the Platform:',
            ),
            _buildBullet('Advertising Networks: ', 'Google AdMob, Unity Ads, and AppLovin for serving advertisements and delivering ad-reward virtual utilities.'),
            _buildBullet('Payment Aggregators: ', 'RBI-regulated entities (e.g., Razorpay, Cashfree, bank transfer networks) to process wallet withdrawals and conduct mandatory Anti-Money Laundering (AML) checks.'),
            _buildBullet('Government Authorities: ', 'The Income Tax Department of India (for TDS filing and Form 16A generation) or law enforcement agencies if mandated by a legally binding order.'),
          ],
        ),

        _buildSectionCard(
          number: '5',
          title: 'YOUR RIGHTS AS A DATA PRINCIPAL (DPDPA 2023)',
          icon: Icons.assignment_ind_outlined,
          children: [
            _buildParagraph(
              'Under the DPDPA 2023, you hold the following rights regarding your personal data:',
            ),
            _buildBullet('Right to Access: ', 'You can request a summary of the personal data we process and the identities of all third-party processors with whom it has been shared.'),
            _buildBullet('Right to Correction & Erasure: ', 'You can request the correction of inaccurate data or the total deletion of your data when it is no longer necessary for the purpose it was collected.'),
            _buildBullet('Right to Withdraw Consent: ', 'You can withdraw your consent for data processing at any time via in-app settings or support request. (Note: Withdrawing consent for device identifiers will restrict ad-rewarded virtual utilities, and withdrawing consent for KYC data will forfeit pending prize payouts).'),
            _buildBullet('Right to Nominate: ', 'You may nominate an individual to exercise your data rights in the event of death or incapacity.'),
          ],
        ),

        _buildSectionCard(
          number: '6',
          title: 'DATA SECURITY & RETENTION',
          icon: Icons.lock_outline,
          children: [
            _buildParagraph(
              'We employ industry-standard cryptographic safeguards, TLS encryption, and secure server-side logic to protect your data.',
            ),
            _buildParagraph(
              'We retain your device and gameplay data only as long as your account remains active. Financial and KYC data (PAN/UPI) are retained for a minimum of seven (7) years post-payout strictly to satisfy statutory tax and AML audit obligations under Indian law.',
            ),
          ],
        ),

        _buildSectionCard(
          number: '7',
          title: 'CONTACT & GRIEVANCE OFFICER',
          icon: Icons.contact_mail_outlined,
          children: [
            _buildParagraph(
              'For data-related requests, consent withdrawal, or privacy grievances, please contact our appointed Grievance Officer pursuant to the IT Rules 2021 and DPDPA 2023:',
            ),
            _buildBullet('Grievance Officer: ', 'Aditya Maurya'),
            _buildBullet('Official Email: ', 'support@swgayanbhumi.in'),
            _buildBullet('Response Timeline: ', 'Acknowledgement within 24 hours; resolution within 15 days.'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: AppTheme.bgDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _copyEmail(context, 'support@swgayanbhumi.in'),
              icon: const Icon(Icons.copy, size: 16),
              label: Text('Copy Privacy Support Email', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold)),
            ),
          ],
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
