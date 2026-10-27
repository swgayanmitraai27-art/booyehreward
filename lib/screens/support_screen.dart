import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  final AppState appState;

  const SupportScreen({super.key, required this.appState});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  @override
  void initState() {
    super.initState();
    widget.appState.fetchMySupportTickets();
  }

  void _openNewTicketDialog() {
    String selectedCategory = 'Room ID / Password Issue';
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.bgDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.primaryGold, width: 2)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '🎧 100% IN-APP SUPPORT',
                      style: GoogleFonts.rajdhani(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGold,
                        letterSpacing: 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Admin will reply directly inside your app within minutes.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                Text(
                  'SELECT ISSUE CATEGORY',
                  style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      dropdownColor: AppTheme.bgCard,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: [
                        'Room ID / Password Issue',
                        'Coins / Wallet Issue',
                        'Tournament Slot Issue',
                        'Redeem Code Delayed',
                        'Other Query',
                      ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'SUBJECT',
                  style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: subjectController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. Room password not opening',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: AppTheme.bgCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'YOUR MESSAGE / DETAILS',
                  style: GoogleFonts.rajdhani(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cyanAccent),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Describe your issue in detail...',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                    filled: true,
                    fillColor: AppTheme.bgCard,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (messageController.text.trim().isEmpty) return;
                            setModalState(() => isSubmitting = true);
                            final ok = await widget.appState.submitSupportTicket(
                              selectedCategory,
                              subjectController.text.trim().isNotEmpty
                                  ? subjectController.text.trim()
                                  : selectedCategory,
                              messageController.text.trim(),
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: ok ? AppTheme.successGreen : AppTheme.errorRed,
                                content: Text(ok
                                    ? 'Ticket submitted! Admin will reply here shortly.'
                                    : 'Failed to submit ticket.'),
                              ),
                            );
                          },
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(
                            'SUBMIT SUPPORT TICKET',
                            style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final tickets = widget.appState.mySupportTickets;

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            backgroundColor: AppTheme.bgDark,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.primaryGold),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.headset_mic, color: AppTheme.primaryGold, size: 24),
                const SizedBox(width: 8),
                Text(
                  'CUSTOMER SUPPORT',
                  style: GoogleFonts.rajdhani(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: AppTheme.primaryGold),
                onPressed: () => widget.appState.fetchMySupportTickets(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primaryGold,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add_comment),
            label: Text('NEW TICKET', style: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, letterSpacing: 1)),
            onPressed: _openNewTicketDialog,
          ),
          body: widget.appState.isSupportLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
              : tickets.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.bgCard,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.support_agent, size: 54, color: AppTheme.primaryGold),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'How Can We Help You?',
                              style: GoogleFonts.rajdhani(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Got an issue with Room Password, Coins, or Match Slot? Tap the button below to message Admin directly.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGold,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: Text('ASK ADMIN DIRECTLY', style: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.bold)),
                              onPressed: _openNewTicketDialog,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: tickets.length,
                      itemBuilder: (context, idx) {
                        final t = tickets[idx];
                        final isReplied = t.status == 'REPLIED';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isReplied ? AppTheme.successGreen.withValues(alpha: 0.5) : Colors.white12,
                            ),
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: idx == 0,
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isReplied ? AppTheme.successGreen : AppTheme.saffronOrange).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t.status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isReplied ? AppTheme.successGreen : AppTheme.saffronOrange,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t.subject,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${t.category} • ${t.ticketId}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ),
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgDark.withValues(alpha: 0.5),
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...t.messages.map((m) {
                                      final isAdmin = m.sender == 'admin';
                                      return Align(
                                        alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isAdmin
                                                ? AppTheme.successGreen.withValues(alpha: 0.2)
                                                : AppTheme.bgCard,
                                            border: Border.all(
                                              color: isAdmin ? AppTheme.successGreen : Colors.white24,
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (isAdmin)
                                                    const Icon(Icons.verified, size: 14, color: AppTheme.successGreen),
                                                  if (isAdmin) const SizedBox(width: 4),
                                                  Text(
                                                    isAdmin ? 'OFFICIAL ADMIN REPLY' : 'YOU',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: isAdmin ? AppTheme.successGreen : AppTheme.cyanAccent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                m.text,
                                                style: const TextStyle(fontSize: 13, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}
