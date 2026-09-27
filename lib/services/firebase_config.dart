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

  // Backend API Base URL
  static const String apiBaseUrl = "https://swgayanbhumi.in/api/payments";
  static const String orderEndpoint = "$apiBaseUrl/create-order";
  static const String verifyEndpoint = "$apiBaseUrl/verify";
  static const String defaultRazorpayKeyId = "rzp_live_TakGRfnTFl20dG";
}
