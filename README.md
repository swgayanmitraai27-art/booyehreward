# 🏆 Booyah Rewards - Free Fire Esports Tournament Platform
**Version:** `v2.2.0+22`  
**Platform Support:** Android (`.apk`, `.aab`) & Web (Vercel)  
**Package Name:** `com.swgayanbhumi.app`  

---

## 📖 Project Overview
**Booyah Rewards** is a high-performance, hybrid Free & Paid esports tournament platform engineered for Free Fire & Free Fire MAX players. It combines real-cash competitive tournaments with free ad-rewarded tournaments, automated prize pool allocations, live wallet management, automated dynamic match starts, and real-time push notification broadcasts.

---

## 🚀 Key Systems & Features

### 1. 📊 75/25 Platform Economy Model
- **Distributable Prize Pool:** Strictly **75%** of the total match entry fee collection.
- **Organizer Commission:** Fixed **25%** platform gross commission.
- **Zero Financial Deficit:** Match payouts are algorithmically locked to the 75% pool.

---

### 2. ⚡ Dynamic Auto-Start Engine (Low-Liquidity Automation)
- **Database Trigger:** When joined player count reaches 100% capacity (e.g., `8/8` for CS, `48/48` for BR), the match status automatically shifts from `upcoming` to `roomFilling`.
- **15-Minute Countdown Timer:** Active across the Tournament Lobby and My Matches screens.
- **Automated Player Push Notification:**
  > *"🚨 Your Match is FULL! The Room ID and Password will be provided in exactly 15 minutes. Open the app now!"*
- **High-Urgency Admin Alert Banner:** Flashing alert banner in Admin Panel with a 1-click **[PUBLISH ROOM ID & PASSWORD NOW]** shortcut.

---

### 3. 🎯 BR & CS Prize Distribution Math Engine

#### A. Battle Royale (BR Full Map - 48 Players)
$$\text{Total Collection} = \text{Entry Fee} \times \text{Max Slots}$$
$$\text{Prize Pool (75\%)} = \text{Total Collection} \times 0.75$$
$$\text{Max Possible Kills} = \text{Max Slots} - 1 \quad (\text{e.g., } 47 \text{ kills for } 48 \text{ players})$$
$$\text{Reserved Kill Pool} = \text{Max Possible Kills} \times \text{Per-Kill Reward}$$
$$\text{Remaining Rank Pool} = \text{Prize Pool (75\%)} - \text{Reserved Kill Pool}$$

**Rank Presets:**
- **Top 3:** Rank 1 (50%), Rank 2 (30%), Rank 3 (20%)
- **Top 5 (Esports):** Rank 1 (40%), Rank 2 (25%), Rank 3 (15%), Rank 4 (10%), Rank 5 (10%)
- **Top 10 (Wide):** Rank 1 (30%), Rank 2 (20%), Rank 3 (15%), Rank 4 & 5 (7.5% each), Rank 6–10 (4% each)
- **Duo/Squad BR:** Rank prizes are divided equally among team members:
  $$\text{Individual Rank Prize} = \frac{\text{Team Rank Prize}}{\text{Team Size}}$$

#### B. Clash Squad (CS) & Lone Wolf (LW)
- Per-Kill reward is disabled (₹0).
- **100%** of the 75% Distributable Prize Pool is split equally among members of the winning team.

---

### 4. 📢 Realtime Push Notifications & FCM Broadcast Center
Admin can dispatch live push notifications via Cloud Messaging / Firestore stream from the Admin Dashboard:
1. **🌍 Global Broadcast (All Users):** Mega match alerts, cashback offers, Sunday cups.
2. **🎮 Match-Specific Alerts:** Instant push notification when Room ID & Password are published.
3. **👤 Single User Direct Alert:** Withdrawal approvals, deposit additions, KYC/UID notifications.
4. **Interactive Android Lockscreen Preview Mockup** included directly in the Admin Panel.

---

### 5. 💰 Multi-Wallet Architecture & Store Redemptions
- **💵 Deposit Cash:** Real cash added via Razorpay UPI (Non-withdrawable, 100% usable for matches).
- **🎁 Bonus Cash:** Welcome & deposit cashback bonuses (Playable priority).
- **🏆 Winning Cash:** Real cash won from tournaments (Withdrawable directly via UPI, min ₹50).
- **🟡 Ad Coins (Reward Coins):** Coins earned by watching rewarded video ads (Used for Free matches or redeemed for Google Play codes / Free Fire Diamonds delivered via WhatsApp).

---

## 🗄️ Firestore Database Schema

| Collection Name | Purpose |
| :--- | :--- |
| `skillwinner_users` | Player profiles, 4-wallet balances, stats, in-game UID, and roles. |
| `skillwinner_matches` | Tournaments, participants, teams, credentials, financial breakdowns, and status. |
| `skillwinner_transactions` | Immutable financial ledger of deposits, entries, winnings, and withdrawals. |
| `skillwinner_withdrawals` | UPI payout requests with PENDING / COMPLETED / REJECTED lifecycle. |
| `skillwinner_voucher_claims` | Store redemption claims with WhatsApp numbers for Play code / Diamond delivery. |
| `skillwinner_notifications` | Push notification history and in-app notification center records. |
| `skillwinner_banners` | Dynamic carousel banners and promo click URLs. |
| `skillwinner_settings` | Global app configuration and Telegram customer support link. |

---

## 🛠️ Build & Release Instructions

### 1. Prerequisites
- Flutter SDK `^3.11.4` (or latest stable)
- Java `JDK 17`
- Android SDK (`targetSdkVersion 36`, `compileSdkVersion 36`, `minSdkVersion 21`)

### 2. Build Commands

```bash
# Get dependencies
flutter pub get

# Code health check (0 errors / 0 warnings required)
flutter analyze

# Build Signed Release Android App Bundle (.aab for Google Play Console)
flutter build appbundle --release

# Build Signed Release APK (for direct mobile installation)
flutter build apk --release

# Build Web Version (for Vercel deployment)
flutter build web --release
```

### 3. Keystore & Signing Configuration
- Keystore file: `android/upload-keystore.jks`
- Key configuration: `android/key.properties`
- Google Services: `android/app/google-services.json`
- Web VAPID Key: Configured in `lib/services/firebase_config.dart`

---

## 📁 Release Artifacts
- **Play Store AAB:** `C:\Users\Admin\Desktop\Booyah_Rewards_v2.2.0.aab`
- **Release APK:** `C:\Users\Admin\Desktop\Booyah_Rewards_v2.2.0.apk`
- **Live Web Deployment:** Pushed to GitHub repository [`booyehreward`](https://github.com/swgayanmitraai27-art/booyehreward.git) -> Automatic Vercel deployment.
