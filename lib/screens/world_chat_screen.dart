import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class WorldChatScreen extends StatefulWidget {
  final AppState appState;

  const WorldChatScreen({super.key, required this.appState});

  @override
  State<WorldChatScreen> createState() => _WorldChatScreenState();
}

class _WorldChatScreenState extends State<WorldChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    widget.appState.fetchWorldChat();
    // Refresh chat every 4 seconds for real-time multiplayer feel
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) widget.appState.fetchWorldChat();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? quickText]) async {
    final text = quickText ?? _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final ok = await widget.appState.sendChatMessage(text);
    if (!mounted) return;

    if (ok) {
      if (quickText == null) _msgController.clear();
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait 5 seconds before sending another message!')),
      );
    }
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final messages = widget.appState.chatMessages;

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: Column(
            children: [
              // ── PINNED ADMIN ANNOUNCEMENT BANNER ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.saffronOrange.withValues(alpha: 0.25),
                      AppTheme.primaryGold.withValues(alpha: 0.15),
                    ],
                  ),
                  border: const Border(bottom: BorderSide(color: AppTheme.primaryGold, width: 1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.campaign, color: AppTheme.primaryGold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '📢 Free Fire India: Share your Squad Code here to team up with real players!',
                        style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // ── CHAT MESSAGES STREAM ──
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.forum_outlined, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 10),
                            Text('World Chat is Quiet', style: GoogleFonts.rajdhani(fontSize: 18, color: Colors.white70)),
                            const SizedBox(height: 4),
                            const Text('Be the first gamer to say hello or share your squad code!',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, idx) {
                          final m = messages[idx];
                          final isSelf = m.uid == widget.appState.user.uid;
                          final isAdmin = m.senderName.toLowerCase().contains('admin') || m.uid.startsWith('admin');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isSelf)
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: isAdmin ? AppTheme.primaryGold : AppTheme.bgCard,
                                    child: Icon(
                                      isAdmin ? Icons.verified : Icons.person,
                                      size: 16,
                                      color: isAdmin ? Colors.black : Colors.white70,
                                    ),
                                  ),
                                if (!isSelf) const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: isSelf
                                          ? AppTheme.primaryGold.withValues(alpha: 0.2)
                                          : (isAdmin ? const Color(0xFF1E293B) : AppTheme.bgCard),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelf
                                            ? AppTheme.primaryGold
                                            : (isAdmin ? AppTheme.primaryGold : Colors.white12),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              m.senderName,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isAdmin
                                                    ? AppTheme.primaryGold
                                                    : (isSelf ? AppTheme.cyanAccent : AppTheme.saffronOrange),
                                              ),
                                            ),
                                            if (isAdmin) const SizedBox(width: 4),
                                            if (isAdmin)
                                              const Icon(Icons.star, size: 12, color: AppTheme.primaryGold),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          m.text,
                                          style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // ── QUICK RECRUIT PILLS ──
              Container(
                height: 34,
                margin: const EdgeInsets.only(bottom: 6),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    _buildQuickPill('CS 4v4 squad code ready! ⚔️'),
                    _buildQuickPill('Squad me 1 rusher chahiye! ⚡'),
                    _buildQuickPill('Bhai Room ID kab unlock hogi? 🔑'),
                    _buildQuickPill('Booyah kiya bhai logo! 👑'),
                  ],
                ),
              ),

              // ── MESSAGE INPUT BOX ──
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                decoration: const BoxDecoration(
                  color: AppTheme.bgCard,
                  border: Border(top: BorderSide(color: Colors.white12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type message or squad code...',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                          filled: true,
                          fillColor: AppTheme.bgDark,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGold,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _isSending
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.send, color: Colors.black, size: 20),
                        onPressed: _isSending ? null : () => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickPill(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        backgroundColor: AppTheme.bgCardLight,
        label: Text(text, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        side: const BorderSide(color: Colors.white12),
        onPressed: () => _sendMessage(text),
      ),
    );
  }
}
