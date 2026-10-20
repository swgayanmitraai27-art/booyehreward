import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class InteractiveUserGuideDialog extends StatefulWidget {
  final VoidCallback? onGoToMatches;
  final VoidCallback? onGoToEarnCoins;
  final VoidCallback? onGoToWallet;

  const InteractiveUserGuideDialog({
    super.key,
    this.onGoToMatches,
    this.onGoToEarnCoins,
    this.onGoToWallet,
  });

  static const String prefKey = 'has_seen_interactive_app_guide_v2';

  /// Check if user has already seen the interactive guide
  static Future<bool> hasSeenGuide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(prefKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark guide as seen
  static Future<void> markGuideSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, true);
    } catch (_) {}
  }

  /// Static helper to show dialog
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onGoToMatches,
    VoidCallback? onGoToEarnCoins,
    VoidCallback? onGoToWallet,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => InteractiveUserGuideDialog(
        onGoToMatches: onGoToMatches,
        onGoToEarnCoins: onGoToEarnCoins,
        onGoToWallet: onGoToWallet,
      ),
    );
  }

  @override
  State<InteractiveUserGuideDialog> createState() => _InteractiveUserGuideDialogState();
}

class _InteractiveUserGuideDialogState extends State<InteractiveUserGuideDialog> {
  int _currentStep = 0;
  bool _step1Clicked = false;
  bool _step2Clicked = false;
  bool _step3Copied = false;
  bool _step4Claimed = false;

  final int _totalSteps = 5;

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _finishGuide();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _finishGuide() {
    InteractiveUserGuideDialog.markGuideSeen();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Bar
            _buildHeader(),

            // Step Progress Dots & Indicator
            _buildProgressBar(),

            // Dynamic Step Card Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Footer Navigation Buttons
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAmber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Colors.black, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'APP KAISE USE KAREIN?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryAmber,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Step ${_currentStep + 1} of $_totalSteps: ${_getStepTitle()}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
            onPressed: _finishGuide,
            tooltip: 'Band Karein',
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Free Coins Kamao';
      case 1:
        return 'Match Join Karo';
      case 2:
        return 'Room ID & Pass';
      case 3:
        return 'Booyah & Rupaye';
      case 4:
        return 'UPI / Code Withdraw';
      default:
        return 'App Guide';
    }
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Container(
              height: 5,
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 6 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: isCurrent
                    ? AppTheme.primaryAmber
                    : (isCompleted ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      case 4:
        return _buildStep5();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: FREE COINS
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFDE68A), width: 2),
            ),
            child: const Text('🟡', style: TextStyle(fontSize: 38)),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            '1. Free Entry Coins Kaise Lein?',
            style: AppTheme.gamingTitle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Text(
            'Aapko match khelne ke liye ek bhi rupya deposit karne ki zaroorat nahi hai!\n\n'
            '• Roz app kholo aur Daily Check-in se FREE Coins lo.\n'
            '• "Earn/Store" tab me jakar chhote video ads dekho aur unlimited Ad Coins pao.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.45, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 14),

        // Interactive "Click Here" Button
        Text(
          'Try Karke Dekhein (Yahan Click Karo):',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () {
            setState(() => _step1Clicked = true);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _step1Clicked ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _step1Clicked ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _step1Clicked ? Icons.check_circle : Icons.touch_app_rounded,
                  color: _step1Clicked ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _step1Clicked ? '✅ Bahut Badhiya! +1 Ad Coin Added!' : '👉 Click Karo: [📺 Watch Ad & Claim Coin]',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: _step1Clicked ? const Color(0xFF15803D) : const Color(0xFF92400E),
                        ),
                      ),
                      Text(
                        _step1Clicked ? 'Coins aane ke baad aap direct Free Fire match join kar sakte hain!' : 'Click karke dekhein coin kaise judta hai',
                        style: TextStyle(
                          fontSize: 10,
                          color: _step1Clicked ? const Color(0xFF16A34A) : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // STEP 2: JOIN MATCH
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
            ),
            child: const Text('⚔️', style: TextStyle(fontSize: 38)),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            '2. Match Kaise Join Karein?',
            style: AppTheme.gamingTitle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Text(
            '• "Matches" tab me CS 4v4 ya Battle Royale match chunein.\n'
            '• Match card par "JOIN NOW" par click karein.\n'
            '• Apna Free Fire Game Name (IGN) aur UID dalein, aur manpasand Slot number select karein.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.45, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Try Karke Dekhein (Yahan Click Karo):',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () {
            setState(() => _step2Clicked = true);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _step2Clicked ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _step2Clicked ? const Color(0xFF16A34A) : const Color(0xFF3B82F6),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _step2Clicked ? Icons.check_circle : Icons.sports_esports_rounded,
                  color: _step2Clicked ? const Color(0xFF16A34A) : const Color(0xFF1D4ED8),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _step2Clicked ? '✅ Slot 1 Book Ho Gaya!' : '👉 Click Karo: [🎮 Slot 1 Select Karein]',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: _step2Clicked ? const Color(0xFF15803D) : const Color(0xFF1E40AF),
                        ),
                      ),
                      Text(
                        _step2Clicked ? 'Aapka slot confirm ho gaya hai! Ab Room details dekhein.' : 'Click karke dekhein slot kaise select hota hai',
                        style: TextStyle(
                          fontSize: 10,
                          color: _step2Clicked ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // STEP 3: ROOM ID & PASSWORD
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFECACA), width: 2),
            ),
            child: const Text('🔑', style: TextStyle(fontSize: 38)),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            '3. Room ID aur Password Kab Milega?',
            style: AppTheme.gamingTitle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Text(
            '• Match shuru hone se theek 10-15 minute pehle Match Card par Room ID aur Password unlock ho jayega.\n'
            '• "COPY" button dabayein, Free Fire game kholen, Custom Room me paste karein aur join ho jayein.\n'
            '• Yahan koi bahari random player nahi aayega, sirf app ke verified players khelenge!',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.45, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Try Karke Dekhein (Yahan Click Karo):',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () {
            setState(() => _step3Copied = true);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _step3Copied ? const Color(0xFFDCFCE7) : const Color(0xFFFDF4FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _step3Copied ? const Color(0xFF16A34A) : const Color(0xFFA855F7),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _step3Copied ? Icons.check_circle : Icons.copy_rounded,
                  color: _step3Copied ? const Color(0xFF16A34A) : const Color(0xFF7E22CE),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _step3Copied ? '✅ Room ID Copied: 9847120' : '👉 Click Karo: [📋 Copy Room ID: 9847120]',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: _step3Copied ? const Color(0xFF15803D) : const Color(0xFF6B21A8),
                        ),
                      ),
                      Text(
                        _step3Copied ? 'Ab bas Free Fire Custom Room me enter karein aur khelein!' : 'Click karke dekhein copy kaise hota hai',
                        style: TextStyle(
                          fontSize: 10,
                          color: _step3Copied ? const Color(0xFF16A34A) : const Color(0xFF9333EA),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // STEP 4: WIN DIRECT RUPEES (₹)
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
            ),
            child: const Text('💰', style: TextStyle(fontSize: 38)),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            '4. Booyah & Asli Rupaye (₹) Ki Jeet!',
            style: AppTheme.gamingTitle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Text(
            'Yahan koi fake ya confusion wale coins nahi hain, seedha ASLI RUPAYE (₹) milte hain!\n\n'
            '• Free Fire match me kills karein aur Booyah layein.\n'
            '• Match khatam hote hi Admin winner verify karega aur Jeet ki Rashi seedha aapke wallet me Rupaye (₹) me credit ho jayegi.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.45, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Try Karke Dekhein (Yahan Click Karo):',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () {
            setState(() => _step4Claimed = true);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _step4Claimed ? const Color(0xFFDCFCE7) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _step4Claimed ? const Color(0xFF16A34A) : const Color(0xFF22C55E),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _step4Claimed ? Icons.check_circle : Icons.emoji_events_rounded,
                  color: const Color(0xFF16A34A),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _step4Claimed ? '🎉 Booyah! ₹50 Cash Wallet Me Credit Hua!' : '👉 Click Karo: [🏆 Claim ₹50 Winning Cash]',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      Text(
                        _step4Claimed ? 'Aapka Jeeta hua paisa seedha Wallet me aa gaya hai!' : 'Click karke dekhein prize rupaye kaise aate hain',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // STEP 5: INSTANT UPI & GOOGLE PLAY CODE
  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFDE68A), width: 2),
            ),
            child: const Text('💸', style: TextStyle(fontSize: 38)),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            '5. Direct UPI Cash ya Redeem Code!',
            style: AppTheme.gamingTitle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Text(
            'Apne jeete hue rupaye (₹) ko nikalna sabse aasan hai!\n\n'
            '• "Wallet" tab me "WITHDRAW" par click karein.\n'
            '• Apna PhonePe, Google Pay, ya Paytm UPI ID daalein aur Instant Real Cash paayein.\n'
            '• Ya seedha Google Play Store Redeem Code lein aur Free Fire me Diamonds top-up karein!',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.45, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 14),

        // Quick Highlights Grid
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Column(
                  children: [
                    Text('⚡ Instant UPI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8))),
                    SizedBox(height: 2),
                    Text('PhonePe / GPay / Paytm', style: TextStyle(fontSize: 9, color: Color(0xFF2563EB))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Column(
                  children: [
                    Text('🎁 Play Redeem Code', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF047857))),
                    SizedBox(height: 2),
                    Text('Instant Free Fire Top-Up', style: TextStyle(fontSize: 9, color: Color(0xFF059669))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios_rounded, size: 12),
                  SizedBox(width: 4),
                  Text('Peeche', style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w800)),
                ],
              ),
            )
          else
            TextButton(
              onPressed: _finishGuide,
              child: const Text(
                'Skip Karein',
                style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
              ),
            ),

          ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentStep == _totalSteps - 1 ? const Color(0xFF16A34A) : AppTheme.primaryAmber,
              foregroundColor: _currentStep == _totalSteps - 1 ? Colors.white : Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              children: [
                Text(
                  _currentStep == _totalSteps - 1 ? '🚀 SAMAJH GAYA! ABHI KHELEIN' : 'AAGE BADHO ➔',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
