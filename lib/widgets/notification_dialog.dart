import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class NotificationDialog extends StatefulWidget {
  final AppState appState;

  const NotificationDialog({super.key, required this.appState});

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog> {
  String _permStatus = 'default';

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await widget.appState.notificationService.getPermissionStatus();
    if (mounted) {
      setState(() {
        _permStatus = status;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    final res = await widget.appState.notificationService.requestPermission();
    if (mounted) {
      setState(() {
        _permStatus = res;
      });
      if (res == 'granted') {
        widget.appState.notificationService.triggerTestBrowserNotification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF047857),
            content: Text('🎉 Browser Pop-up Notifications ENABLED! Test notification sent.'),
          ),
        );
      } else if (res == 'denied') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFDC2626),
            content: Text('🔒 Notification is BLOCKED in your browser! See instructions below.'),
          ),
        );
      }
    }
  }

  void _sendTestPopup() {
    widget.appState.notificationService.triggerTestBrowserNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF047857),
        content: Text('🔔 Test desktop pop-up notification dispatched!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifs = widget.appState.notifications;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 620),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active, color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOTIFICATIONS',
                        style: AppTheme.gamingTitle(fontSize: 16, color: const Color(0xFF0F172A), isItalic: false),
                      ),
                      Text(
                        'Live Match Alerts & Announcements',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Permission Status & Action Card
            if (_permStatus == 'denied')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.lock_outline, color: Color(0xFFDC2626), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Browser Notifications Are BLOCKED',
                          style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Browser ne notification pop-up block kiya hua hai. Ise Allow karne ke 2 aasan steps:',
                      style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('1️⃣ Upar URL bar me 🔒 Lock icon (site settings) par click karein.', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                          SizedBox(height: 3),
                          Text('2️⃣ "Notifications" ko "Allow" karein aur Page Refresh (F5) karein!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else if (_permStatus == 'granted')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF059669), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Browser Pop-up Alerts ACTIVE',
                            style: TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                          Text(
                            'Desktop & Mobile popups enabled',
                            style: TextStyle(color: Color(0xFF047857), fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _sendTestPopup,
                      icon: const Icon(Icons.notifications_active, size: 14),
                      label: const Text('TEST POPUP', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF047857),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_outlined, color: Colors.amber, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Browser & App Push Alerts',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            'Get 15m room alert & password instantly',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _requestNotificationPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('ENABLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            const Divider(height: 1),
            const SizedBox(height: 10),

            // Notification List
            Expanded(
              child: notifs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text('No notifications yet', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Match full countdowns & room IDs appear here.', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: notifs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final n = notifs[index];
                        final isRoomNotif = n.type == NotificationType.roomCredentials || n.type == NotificationType.matchFull;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isRoomNotif ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isRoomNotif ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRoomNotif ? '🚨' : '📢',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.title,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      n.body,
                                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${n.createdAt.hour.toString().padLeft(2, '0')}:${n.createdAt.minute.toString().padLeft(2, '0')} • ${n.createdAt.day}/${n.createdAt.month}',
                                      style: TextStyle(fontSize: 9.5, color: Colors.grey[500]),
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
          ],
        ),
      ),
    );
  }
}
