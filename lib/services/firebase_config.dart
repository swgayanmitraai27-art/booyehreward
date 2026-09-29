/// Booyah Rewards (SkillWinner) - Firebase Connection Configuration
/// Project: sw-gyanmitra-finall2-426-dcc41
class FirebaseConfig {
  static const String apiKey = "AIzaSyCLTHMklWsgiydXuF3QssaR9XtHtHLjd_8";
  static const String authDomain = "sw-gyanmitra-finall2-426-dcc41.firebaseapp.com";
  static const String projectId = "sw-gyanmitra-finall2-426-dcc41";
  static const String storageBucket = "sw-gyanmitra-finall2-426-dcc41.firebasestorage.app";
  static const String messagingSenderId = "841226454678";
  static const String appId = "1:841226454678:web:4d42dfa3dddb5714f2e4b7";

  // Firestore Database Collection Names
  static const String usersCollection = "skillwinner_users";
  static const String transactionsCollection = "skillwinner_transactions";
  static const String matchesCollection = "skillwinner_matches";
  static const String financialLedgerCollection = "financial_ledger";

  // Web Push VAPID Key Pair for FCM Web Notifications
  static const String vapidKey = "BJfkFsBwWGuabGkeDJARmVXfKuL8QXkppIuc9q5OJ5XM5L1qAsZJydzU1G7GusbuY_7A87Rr6qPQFdDaXCSnln0";

  // Backend API Base URL - Using www.swgayanbhumi.in to prevent 308 CORS browser redirect
  static const String apiBaseUrl = "https://www.swgayanbhumi.in/api/payments";
  static const String pushNotificationEndpoint = "https://www.swgayanbhumi.in/api/push-notification";
  static const String orderEndpoint = "https://www.swgayanbhumi.in/api/payments/create-order";
  static const String verifyEndpoint = "https://www.swgayanbhumi.in/api/payments/verify";
  static const String defaultRazorpayKeyId = "rzp_live_TakGRfnTFl20dG";
}
