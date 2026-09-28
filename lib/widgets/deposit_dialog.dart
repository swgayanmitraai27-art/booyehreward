import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/url_launcher_util.dart';

class DepositDialog extends StatefulWidget {
  final AppState appState;

  const DepositDialog({super.key, required this.appState});

  @override
  State<DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<DepositDialog> {
  final TextEditingController _amountController = TextEditingController(text: '100');
  final TextEditingController _utrController = TextEditingController();

  final String merchantVpa = 'samashermaurya9935@okaxis';
  final String merchantName = 'SkillWinner';

  bool isSubmittingUtr = false;
  bool isQrLoading = false;
  String? currentQrImageUrl;
  String? activeQrId;
  Timer? _qrPollingTimer;
  Map<String, dynamic>? successData;
  String? errorMsg;
  String? successNotice;

  @override
  void initState() {
    super.initState();
    _fetchOrGenerateQr(100);
  }

  @override
  void dispose() {
    _qrPollingTimer?.cancel();
    _amountController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  double get currentAmount => double.tryParse(_amountController.text.trim()) ?? 0;
  double get bonusCash => currentAmount * 0.10; // 10% Extra Deposit Cash
  double get totalDepositCash => currentAmount + bonusCash;

  String get _upiIntentUrl {
    final amt = currentAmount.toInt();
    final uid = widget.appState.user.uid.length > 6 ? widget.appState.user.uid.substring(0, 6) : widget.appState.user.uid;
    return 'upi://pay?pa=$merchantVpa&pn=$merchantName&am=$amt&cu=INR&tn=SkillWinner_Deposit_$uid';
  }

  String get _defaultQrUrl {
    return 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${Uri.encodeComponent(_upiIntentUrl)}';
  }

  Future<void> _fetchOrGenerateQr(double amt) async {
    if (amt < 10) return;
    setState(() {
      isQrLoading = true;
      errorMsg = null;
    });

    try {
      final res = await http.post(
        Uri.parse('https://www.swgayanbhumi.in/api/skillwinner/qr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.appState.user.uid,
          'amount': amt,
        }),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['imageUrl'] != null) {
          if (mounted) {
            setState(() {
              currentQrImageUrl = data['imageUrl'];
              activeQrId = data['qrId'];
              isQrLoading = false;
            });
            _startQrPoller(data['qrId']);
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        currentQrImageUrl = _defaultQrUrl;
        isQrLoading = false;
      });
    }
  }

  void _startQrPoller(String qrId) {
    _qrPollingTimer?.cancel();
    _qrPollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      try {
        final res = await http.get(
          Uri.parse('https://www.swgayanbhumi.in/api/skillwinner/qr/check?qrId=$qrId&userId=${widget.appState.user.uid}'),
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['paid'] == true || data['status'] == 'SUCCESS') {
            timer.cancel();
            await widget.appState.refreshFromFirestore();
            if (mounted) {
              setState(() {
                successData = {
                  'amount': data['amount'] ?? currentAmount,
                  'bonus': data['extraBonus'] ?? bonusCash,
                  'total': data['totalDepositCash'] ?? totalDepositCash,
                  'txId': data['paymentId'] ?? qrId,
                };
              });
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _launchUpiIntent([String? packageScheme]) async {
    final amt = currentAmount;
    if (amt < 10) {
      setState(() => errorMsg = 'Minimum deposit amount is ₹10.');
      return;
    }

    String url = _upiIntentUrl;
    if (packageScheme != null) {
      url = '$packageScheme://$url';
    }

    await UrlLauncherUtil.openUrl(url);
  }

  Future<void> _submitUtrNumber() async {
    final utr = _utrController.text.trim();
    if (utr.isEmpty || utr.length < 6) {
      setState(() => errorMsg = 'Please enter a valid 12-digit UPI UTR / Reference ID.');
      return;
    }
    final amt = currentAmount;
    if (amt < 10) {
      setState(() => errorMsg = 'Minimum deposit amount is ₹10.');
      return;
    }

    setState(() {
      isSubmittingUtr = true;
      errorMsg = null;
    });

    try {
      final res = await http.post(
        Uri.parse('https://www.swgayanbhumi.in/api/skillwinner/qr/submit_utr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.appState.user.uid,
          'amount': amt,
          'utr': utr,
        }),
      ).timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        widget.appState.depositCash(amt, 'UTR-$utr');
        await widget.appState.refreshFromFirestore();
        if (mounted) {
          setState(() {
            isSubmittingUtr = false;
            successData = {
              'amount': amt,
              'bonus': bonusCash,
              'total': totalDepositCash,
              'txId': 'UTR-$utr',
            };
          });
        }
        return;
      } else {
        setState(() {
          isSubmittingUtr = false;
          errorMsg = data['error'] ?? 'UTR verification failed. Please check the reference number.';
        });
      }
    } catch (e) {
      // Fallback local credit if network delay
      widget.appState.depositCash(amt, 'UTR-$utr');
      if (mounted) {
        setState(() {
          isSubmittingUtr = false;
          successData = {
            'amount': amt,
            'bonus': bonusCash,
            'total': totalDepositCash,
            'txId': 'UTR-$utr',
          };
        });
      }
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied: $text'),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
        padding: const EdgeInsets.all(18),
        child: successData != null ? _buildSuccessView() : _buildQrPaymentBody(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppTheme.winningGreen, size: 40),
          ),
          const SizedBox(height: 14),
          Text(
            'Deposit Cash Credited!',
            style: AppTheme.gamingTitle(fontSize: 20, color: const Color(0xFF065F46)),
          ),
          const SizedBox(height: 6),
          const Text(
            '10% Extra Deposit Cash has been added to your wallet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount Paid', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    Text('₹${(successData!['amount'] as num).toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('10% Extra Deposit Bonus', style: TextStyle(fontSize: 13, color: Color(0xFF047857), fontWeight: FontWeight.w600)),
                    Text('+₹${(successData!['bonus'] as num).toStringAsFixed(1)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Credited Deposit Cash', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    Text('₹${(successData!['total'] as num).toStringAsFixed(1)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                _qrPollingTimer?.cancel();
                Navigator.of(context).pop();
              },
              child: const Text('DONE & PLAY MATCHES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrPaymentBody() {
    return SingleChildScrollView(
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.qr_code_scanner_rounded, color: Colors.blue.shade700, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DIRECT UPI & QR CODE',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'Add Deposit Cash',
                        style: AppTheme.gamingTitle(fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _qrPollingTimer?.cancel();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 10% Extra Bonus Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              children: [
                const Text('🎁', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recharge ₹${currentAmount.toInt()} ➔ Get ₹${totalDepositCash.toStringAsFixed(1)} Deposit Cash (10% Extra Cash)!',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Presets Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [10, 20, 50, 100, 200, 500].map((amt) {
              final isSelected = currentAmount.toInt() == amt;
              return InkWell(
                onTap: () {
                  _amountController.text = amt.toString();
                  setState(() {});
                  _fetchOrGenerateQr(amt.toDouble());
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? const Color(0xFF0F172A) : Colors.transparent),
                  ),
                  child: Text(
                    '₹$amt',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // QR CODE DISPLAY CARD
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.blue.shade100, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isQrLoading
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                        : Image.network(
                            currentQrImageUrl ?? _defaultQrUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Image.network(_defaultQrUrl),
                          ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '📸 Screenshot QR & Pay with GPay / PhonePe / Paytm',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // UPI ID COPY BAR
          InkWell(
            onTap: () => _copy(merchantVpa, 'UPI ID'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Text(
                        merchantVpa,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Text('COPY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8))),
                      SizedBox(width: 3),
                      Icon(Icons.copy_rounded, size: 13, color: Color(0xFF1D4ED8)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // DIRECT UPI APPS ROW (ONE-TAP LAUNCH)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  onPressed: () => _launchUpiIntent(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFF1D4ED8)),
                      SizedBox(width: 4),
                      Text('Open UPI App', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // UTR / REFERENCE SUBMISSION
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ENTER 12-DIGIT UPI UTR / TXN ID',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _utrController,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'e.g. 427819284712',
                          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onPressed: isSubmittingUtr ? null : _submitUtrNumber,
                      child: isSubmittingUtr
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('SUBMIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (errorMsg != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMsg!,
              style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
