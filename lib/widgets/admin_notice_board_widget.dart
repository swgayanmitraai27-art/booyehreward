import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';

class AdminNoticeBoardWidget extends StatefulWidget {
  final AppState appState;

  const AdminNoticeBoardWidget({super.key, required this.appState});

  @override
  State<AdminNoticeBoardWidget> createState() => _AdminNoticeBoardWidgetState();
}

class _AdminNoticeBoardWidgetState extends State<AdminNoticeBoardWidget> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  bool _isToggling = false;
  bool _isExpanded = true;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  bool get _isAdmin {
    final user = widget.appState.user;
    return user.role == 'admin' || AuthService.isAdminIdentifier(user.email, user.uid);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    final res = await widget.appState.postNoticeBoardMessage(text);
    if (mounted) {
      setState(() => _isSending = false);
      if (res['success'] == true) {
        _messageController.clear();
        FocusScope.of(context).unfocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text(res['message'] ?? 'मैसेज भेजने में समस्या हुई'),
          ),
        );
      }
    }
  }

  void _showEditNoticeDialog() {
    final titleController = TextEditingController(text: widget.appState.noticeBoard.title);
    final bodyController = TextEditingController(text: widget.appState.noticeBoard.body);
    final adminMsgController = TextEditingController();
    bool allowUsers = widget.appState.noticeBoard.allowUserMessages;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: const Color(0xFF1E293B),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.campaign_rounded, color: Colors.amber, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'एडमिन नोटिस बदलें',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 10),

                  const Text(
                    'नोटिस टाइटल (Headline)',
                    style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      hintText: 'e.g. 📢 ज़रूरी सूचना: नया टूर्नामेंट लाइव है!',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'नोटिस विवरण (Message Content)',
                    style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: bodyController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      hintText: 'यहाँ पूरा संदेश लिखें जो सभी प्लेयर्स को दिखेगा...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Allow user messages switch
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'यूज़र मैसेज अनुमति (Allow Users)',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'ऑन करने पर यूज़र्स मैसेज लिख सकेंगे',
                              style: TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                        Switch(
                          value: allowUsers,
                          activeThumbColor: Colors.amber,
                          onChanged: (val) {
                            setDialogState(() => allowUsers = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'नया एडमिन कमेंट जोड़ें (वैकल्पिक)',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: adminMsgController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      hintText: 'बोर्ड पर एडमिन की तरफ से कोई कमेंट...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setDialogState(() => isSaving = true);
                              final ok = await widget.appState.adminUpdateNoticeBoard(
                                title: titleController.text,
                                body: bodyController.text,
                                allowUserMessages: allowUsers,
                                adminMessage: adminMsgController.text,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: ok ? const Color(0xFF16A34A) : Colors.red,
                                    content: Text(ok ? 'नोटिस सफलतापूर्वक अपडेट हो गया!' : 'अपडेट विफल हुआ'),
                                  ),
                                );
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 18),
                      label: Text(
                        isSaving ? 'सेव हो रहा है...' : 'तुरंत पब्लिश करें',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.appState.noticeBoard;
    final allowUserMessages = board.allowUserMessages;
    final formattedDate = DateFormat('dd MMM, hh:mm a').format(board.updatedAt);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Premium dark slate
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withAlpha(35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
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
                        color: Colors.amber.withAlpha(40),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 1.5),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: Colors.amber, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '📢 एडमिन सूचना पट्ट',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'OFFICIAL',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'लाइव अपडेट्स • $formattedDate',
                          style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_isAdmin) ...[
                      InkWell(
                        onTap: _showEditNoticeDialog,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit, size: 12, color: Colors.black),
                              SizedBox(width: 3),
                              Text(
                                'Edit',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.amber,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Main Notice Highlight Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E1065), Color(0xFF1E1B4B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA855F7).withAlpha(120), width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.push_pin, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          board.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    board.body,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Admin Quick Toggle Bar (Only visible to Admin)
          if (_isAdmin)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withAlpha(60)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        allowUserMessages ? '🟢 यूज़र मैसेज चालू हैं' : '🔴 यूज़र मैसेज बंद हैं',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: allowUserMessages ? const Color(0xFF4ADE80) : const Color(0xFFF87171),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Chat Toggle:',
                        style: TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                      const SizedBox(width: 6),
                      _isToggling
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                            )
                          : Switch(
                              value: allowUserMessages,
                              activeThumbColor: Colors.amber,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (val) async {
                                setState(() => _isToggling = true);
                                await widget.appState.adminToggleUserMessages(val);
                                if (mounted) setState(() => _isToggling = false);
                              },
                            ),
                    ],
                  ),
                ],
              ),
            ),

          if (_isExpanded) ...[
            // 3. Discussion & Recent Messages Section
            if (board.messages.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'लाइव बातचीत (${board.messages.length})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (allowUserMessages)
                      const Row(
                        children: [
                          Icon(Icons.fiber_manual_record, color: Color(0xFF22C55E), size: 10),
                          SizedBox(width: 4),
                          Text(
                            'चैट खुली है',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                margin: const EdgeInsets.symmetric(horizontal: 14),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: board.messages.take(15).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final msg = board.messages[index];
                    final isMsgAdmin = msg.isAdmin;
                    final msgTime = DateFormat('hh:mm a').format(msg.createdAt);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMsgAdmin ? const Color(0xFF312E81) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isMsgAdmin ? const Color(0xFFF59E0B) : Colors.white10,
                          width: isMsgAdmin ? 1.2 : 0.8,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: isMsgAdmin ? Colors.amber.withAlpha(40) : Colors.white10,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isMsgAdmin ? Icons.star_rounded : Icons.person_rounded,
                              size: 13,
                              color: isMsgAdmin ? Colors.amber : Colors.white70,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      msg.senderName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: isMsgAdmin ? Colors.amber : Colors.white,
                                      ),
                                    ),
                                    if (isMsgAdmin) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'ADMIN',
                                          style: TextStyle(
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    Text(
                                      msgTime,
                                      style: const TextStyle(fontSize: 9, color: Colors.white38),
                                    ),
                                    if (_isAdmin) ...[
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => widget.appState.adminDeleteNoticeBoardMessage(msg.id),
                                        child: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  msg.text,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            // 4. Input Area: Allowed vs Locked
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: allowUserMessages || _isAdmin
                  ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF1E293B),
                              hintText: _isAdmin
                                  ? 'एडमिन के रूप में लिखें...'
                                  : 'अपना सवाल या मैसेज लिखें...',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white24),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.amber),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _isSending ? null : _sendMessage,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isSending
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_rounded, size: 14, color: Colors.white54),
                          SizedBox(width: 6),
                          Text(
                            '🔒 यूज़र मैसेज अभी एडमिन द्वारा बंद हैं (Admin Only)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
