Future<String> requestBrowserNotificationPermission() async {
  return 'unsupported';
}

void showBrowserNotification(String title, String body, {String? imageUrl, String? url}) {
  // No-op for non-web platforms (Native Android handles its own notifications)
}
