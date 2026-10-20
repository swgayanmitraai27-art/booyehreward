import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/voucher_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class WithdrawDialog extends StatefulWidget {
  final AppState appState;
  final int initialTab; // 0: UPI, 1: Redeem Code

  const WithdrawDialog({
    super.key,
    required this.appState,
    this.initialTab = 0,
  });

  @override
  State<WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<WithdrawDialog> {
  late int _selectedTab;
  late TextEditingController _amountController;
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _inGameUidController = TextEditingController();

  bool isProcessing = false;
  String? errorMsg;
  String? successMsg;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _amountController = TextEditingController(text: '${widget.appState.minWithdrawalCoins}');
    _whatsappController.text = widget.appState.user.phoneNumber;
    _inGameUidController.text = widget.appState.user.inGameUid ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiController.dispose();
    _whatsappController.dispose();
    _inGameUidController.dispose();
    super.dispose();
  }

  void _processUPIWithdrawal() {
    setState(() {
      errorMsg = null;
      successMsg = null;
    });

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final upiId = _upiController.text.trim();
    final minCoins = widget.appState.minWithdrawalCoins;

    if (amount < minCoins) {
      setState(() => errorMsg = 'Minimum withdrawal limit is ₹$minCoins Real Cash.');
      return;
    }

    if (amount > widget.appState.user.wallet.winningCash) {
      setState(() => errorMsg = 'Insufficient Winning Cash! Aapke paas ₹${widget.appState.user.wallet.winningCash.toInt()} hain.');
      return;
    }

    if (!upiId.contains('@')) {
      setState(() => errorMsg = 'Please enter a valid UPI ID (e.g. 9876543210@ybl, yourname@oksbi).');
      return;
    }

    setState(() => isProcessing = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final res = widget.appState.requestWithdrawal(amount, upiId);
      setState(() {
        isProcessing = false;
        if (res['success'] == true) {
          successMsg = res['message'];
        } else {
          errorMsg = res['message'];
        }
      });
    });
  }

  void _confirmClaimRedeemCode(StoreItem item) {
    setState(() {
      errorMsg = null;
      successMsg = null;
    });

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('🎟️', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Cost (Winning Cash):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                      ),
                      Text(
                        '₹${item.priceInRupees}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'WHATSAPP NUMBER (FOR CODE DELIVERY)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'e.g. 9876543210',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  'FREE FIRE UID (OPTIONAL)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _inGameUidController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'e.g. 284719284',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '⚡ Admin aapke WhatsApp par Google Play Redeem Code direct send karenge.',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: () {
                  final phone = _whatsappController.text.trim();
                  if (phone.length < 8) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kripya valid WhatsApp number dalein!')),
                    );
                    return;
                  }

                  Navigator.of(ctx).pop();

                  final res = widget.appState.redeemStoreItem(
                    item: item,
                    whatsappNumber: phone,
                    inGameUid: _inGameUidController.text.trim(),
                  );

                  setState(() {
                    if (res['success'] == true) {
                      successMsg = res['message'];
                    } else {
                      errorMsg = res['message'];
                    }
                  });
                },
                child: Text(
                  'CONFIRM & PAY ₹${item.priceInRupees}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winningCash = widget.appState.user.wallet.winningCash;
    final minCoins = widget.appState.minWithdrawalCoins;
    final enteredAmount = double.tryParse(_amountController.text.trim()) ?? 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('💰', style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WINNING CASH WITHDRAWAL',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          Text(
                            'Paisa Kaise Lena Hai?',
                            style: AppTheme.gamingTitle(fontSize: 17),
                          ),
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
              const SizedBox(height: 12),

              // Available Balance Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KUL JEETI HUI RASHI (WINNINGS)',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '100% Real Cash Payout',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                        ),
                      ],
                    ),
                    Text(
                      '₹${winningCash.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2-TAB SWITCH: [ ⚡ UPI Transfer ] vs [ 🎟️ Redeem Code ]
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTab = 0;
                            errorMsg = null;
                            successMsg = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTab == 0
                                ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4)]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('⚡', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                'UPI Transfer',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: _selectedTab == 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTab = 1;
                            errorMsg = null;
                            successMsg = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _selectedTab == 1
                                ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4)]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🎟️', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                'Redeem Code',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: _selectedTab == 1 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
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
              const SizedBox(height: 14),

              // SUCCESS MESSAGE BANNER
              if (successMsg != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.winningGreen, size: 44),
                      const SizedBox(height: 8),
                      Text(
                        'Request Submit Ho Gayi!',
                        style: AppTheme.gamingTitle(fontSize: 16, color: const Color(0xFF065F46)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        successMsg!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF065F46), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OKAY & BAND KAREIN'),
                      ),
                    ],
                  ),
                ),
              ] else if (_selectedTab == 0) ...[
                // --- TAB 0: UPI TRANSFER CONTENT ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'KITNA WITHDRAW KARNA HAI (MIN ₹$minCoins)',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _amountController.text = '${winningCash.toInt()}';
                        });
                      },
                      child: const Text(
                        'Pura Nikalein',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFFD97706)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Text('₹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 6),

                // Quick Preset Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        label: const Text('₹50', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () => setState(() => _amountController.text = '50'),
                      ),
                      const SizedBox(width: 4),
                      ActionChip(
                        label: const Text('₹100', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () => setState(() => _amountController.text = '100'),
                      ),
                      const SizedBox(width: 4),
                      ActionChip(
                        label: const Text('₹200', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () => setState(() => _amountController.text = '200'),
                      ),
                      const SizedBox(width: 4),
                      ActionChip(
                        label: const Text('₹500', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () => setState(() => _amountController.text = '500'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  'APNA UPI ID DALEIN (PHONEPE / GPAY / PAYTM)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _upiController,
                  decoration: InputDecoration(
                    hintText: 'e.g. 9876543210@paytm ya user@oksbi',
                    hintStyle: const TextStyle(fontSize: 11.5, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),

                if (errorMsg != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMsg!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (winningCash >= minCoins && enteredAmount >= minCoins)
                          ? AppTheme.winningGreen
                          : Colors.grey.shade300,
                      foregroundColor: (winningCash >= minCoins && enteredAmount >= minCoins)
                          ? Colors.white
                          : Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: (winningCash >= minCoins && enteredAmount >= minCoins && !isProcessing)
                        ? _processUPIWithdrawal
                        : null,
                    child: isProcessing
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 8),
                              Text('SUBMITTING...'),
                            ],
                          )
                        : Text(
                            'SUBMIT UPI WITHDRAWAL (₹${enteredAmount.toStringAsFixed(0)})',
                            style: AppTheme.gamingTitle(fontSize: 13, color: Colors.white, isItalic: false),
                          ),
                  ),
                ),
              ] else ...[
                // --- TAB 1: GOOGLE PLAY REDEEM CODES (ADMIN STORE ITEMS) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SELECT GOOGLE PLAY REDEEM CODE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
                    ),
                    Text(
                      '${widget.appState.storeItems.length} Codes Available',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (widget.appState.storeItems.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        'Abhi koi Redeem Code available nahi hai. Admin jald add karega.',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.appState.storeItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = widget.appState.storeItems[index];
                      final canAfford = winningCash >= item.priceInRupees;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: canAfford ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: canAfford ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(item.iconEmoji, style: const TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                                  ),
                                  Text(
                                    'Value: ${item.rewardValue} • Cost: ₹${item.priceInRupees}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canAfford ? const Color(0xFF16A34A) : Colors.grey.shade300,
                                foregroundColor: canAfford ? Colors.white : Colors.grey.shade600,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: canAfford ? () => _confirmClaimRedeemCode(item) : null,
                              child: Text(
                                canAfford ? 'CLAIM (₹${item.priceInRupees})' : 'NEED ₹${item.priceInRupees}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                if (errorMsg != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMsg!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ],

                // Past Claims Summary
                if (widget.appState.voucherClaims.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    '📋 AAPKE CLAIM KIYE HUE CODES',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.appState.voucherClaims.take(3).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final claim = widget.appState.voucherClaims[index];
                      final isDelivered = claim.status == VoucherClaimStatus.delivered;

                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDelivered ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDelivered ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  claim.itemTitle,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  isDelivered
                                      ? (claim.redeemCode != null ? 'Code: ${claim.redeemCode}' : 'Delivered on WhatsApp')
                                      : 'Status: Pending (WhatsApp Delivery in 2 hrs)',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDelivered ? const Color(0xFF047857) : const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                            if (isDelivered && claim.redeemCode != null)
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16, color: Color(0xFF047857)),
                                tooltip: 'Copy Code',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: claim.redeemCode!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Redeem Code copied!')),
                                  );
                                },
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDelivered ? const Color(0xFF16A34A) : Colors.amber.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isDelivered ? 'DELIVERED' : 'PENDING',
                                  style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
