# 🎮 Arena Rewards (Booyah Rewards) — Master Project & Server Documentation

This document contains **ALL** server credentials, SSH keys, admin URLs, database locations, Shorebird OTA patch commands, and monetization rules for the Arena Rewards ecosystem.

---

## 🌐 1. VPS Server & SSH Access Details
- **Cloud Provider**: AWS Lightsail (Mumbai `ap-south-1a`)
- **Public Server IP**: `35.154.113.3`
- **Private IPv4**: `172.26.15.179`
- **OS**: Ubuntu 24.04 LTS (64-bit)
- **Domain Name**: `https://vps.swgayanbhumi.in`
- **API Base URL**: `https://vps.swgayanbhumi.in/api`
- **Web Admin Panel URL**: `https://vps.swgayanbhumi.in/admin/`

### 🔑 SSH Credentials & Direct Login:
- **SSH Key Path (on your PC)**:
  `C:\Users\Admin\Documents\Downloads\LightsailDefaultKey-ap-south-1.pem`
- **Direct SSH Command (PowerShell / Terminal)**:
  ```bash
  ssh -o StrictHostKeyChecking=no -i "C:\Users\Admin\Documents\Downloads\LightsailDefaultKey-ap-south-1.pem" ubuntu@35.154.113.3
  ```

### 📂 Server Directories & PM2 Management:
- **Live Backend Directory**: `/home/ubuntu/arena-backend/`
- **Static Admin Panel HTML**: `/home/ubuntu/arena-backend/public/index.html`
- **Database File**: `/home/ubuntu/arena-backend/data/db.json`
- **Uploaded Images & Proofs**: `/home/ubuntu/arena-backend/uploads/`
- **PM2 Service Name**: `arena-api` (Runs under `root`)

#### Essential PM2 Commands:
```bash
sudo pm2 status
sudo pm2 restart arena-api
sudo pm2 logs arena-api --lines 50
```

---

## 📢 2. Web Admin Panel & Notice Board
- **URL**: [https://vps.swgayanbhumi.in/admin/](https://vps.swgayanbhumi.in/admin/)
- **Features**:
  1. **📢 Tournament Notice Board (Live App Announcement)**: Type any announcement, select quick presets, and click **"PUBLISH NOTICE TO LIVE APP NOW"**. The notice is instantly broadcast to all users on the Leaderboard screen.
  2. **💰 Set Weekly Prize Pool**: Enter amount (e.g. ₹5,000, ₹10,000) to auto-calculate rank prizes for Top 10 players.
  3. **👥 Real Registered Devices Directory**: View real players, weekly scores, and phone/UPI payout claims.
  4. **⚡ Boost / Change Player Score**: Enter device UID and score to adjust leaderboard positions.
  5. **🎁 Winner Proofs & Reviews Manager**: Upload payment screenshots (UPI / Play Store receipts) that show in the app's Community Winner Proofs section.

---

## 🚀 3. Shorebird OTA Patching Guide

### Active Releases on Shorebird Cloud:
| Release Version | Release ID | Target Platform | Flutter Engine | Status |
| :--- | :--- | :--- | :--- | :--- |
| **`1.3.9+39`** | `925085` | Android | `3.41.6` (`76ca3dff01`) | **ACTIVE (Latest Play Store)** |
| **`1.3.8+38`** | `916512` | Android | `3.41.6` (`76ca3dff01`) | **ACTIVE** |
| **`1.3.6+36`** | `902720` | Android | `3.41.6` (`76ca3dff01`) | **ACTIVE** |
| **`1.3.5+35`** | `893515` | Android | `3.41.6` (`76ca3dff01`) | **ACTIVE** |

### How to Deploy Live OTA Patches (No Play Store review needed):

> [!IMPORTANT]
> **Thermal & Overheating Protection Rule**: Entry-level laptops (e.g. 2-Core / 4-Thread CPUs like AMD Athlon 300U) will overheat and shut down if Gradle runs with default multi-threading.
> Always deploy **ONE RELEASE AT A TIME** with a **15-minute Cool-Down pause** between each release, with `BelowNormal` priority and `workers.max=1`.

#### 1. Setup Heat Protection in `android/gradle.properties`:
Ensure `android/gradle.properties` contains:
```properties
org.gradle.jvmargs=-Xmx1280m -XX:MaxMetaspaceSize=256m
org.gradle.workers.max=1
org.gradle.parallel=false
org.gradle.caching=true
```

#### 2. Kill Lingering Background Daemons (Free RAM):
```powershell
Get-Process -Name java -ErrorAction SilentlyContinue | Stop-Process -Force
```

#### 3. Sequential Deployment Commands:
```powershell
# Step 1: Open project directory
cd "C:\Users\Admin\Desktop\Booyah Rewards - Copy (2)"

# Step 2: Prevent web platform collision
if (Test-Path "flutter.js") { Rename-Item "flutter.js" "flutter.js.bak" -Force }

# Step 3: Set Low CPU Priority (Prevents Overheating)
[System.Diagnostics.Process]::GetCurrentProcess().PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal

# Step 4: Deploy to Version 39 (Wait until it says: ✅ Published Patch)
@("y", "y", "y") | & "$env:USERPROFILE\.shorebird\bin\shorebird.ps1" patch --platforms=android --allow-asset-diffs --allow-native-diffs --release-version=1.3.9+39

# [Cool-down 15 Minutes before next version]

# Step 5: Deploy to Version 38 (Wait until it says: ✅ Published Patch)
@("y", "y", "y") | & "$env:USERPROFILE\.shorebird\bin\shorebird.ps1" patch --platforms=android --allow-asset-diffs --allow-native-diffs --release-version=1.3.8+38

# [Cool-down 15 Minutes before next version]

# Step 6: Deploy to Version 36 (Only after Version 38 completes)
@("y", "y", "y") | & "$env:USERPROFILE\.shorebird\bin\shorebird.ps1" patch --platforms=android --allow-asset-diffs --allow-native-diffs --release-version=1.3.6+36

# [Cool-down 15 Minutes before next version]

# Step 7: Deploy to Version 35 (Only after Version 36 completes)
@("y", "y", "y") | & "$env:USERPROFILE\.shorebird\bin\shorebird.ps1" patch --platforms=android --allow-asset-diffs --allow-native-diffs --release-version=1.3.5+35

# Step 8: Restore flutter.js
if (Test-Path "flutter.js.bak") { Rename-Item "flutter.js.bak" "flutter.js" -Force }

# Step 9: Verify Live Status
& "$env:USERPROFILE\.shorebird\bin\shorebird.ps1" patches list --release-version=1.3.9+39
& "$env:USERPROFILE\.shorebird\bin\shorebird.ps1" patches list --release-version=1.3.8+38
& "$env:USERPROFILE\.shorebird\bin\shorebird.ps1" patches list --release-version=1.3.6+36
& "$env:USERPROFILE\.shorebird\bin\shorebird.ps1" patches list --release-version=1.3.5+35
```

---

## 🎮 4. In-Game Monetization & Ad Strategy (Updated)
1. **100% Unlimited Free Play (No Ad Barrier to Play Games)**:
   - Users can play and replay ANY game (Knife Hit, Fruit Slash, Puzzle Blast, TicTacToe, Speed Tap) completely FREE without watching an ad to start or restart.
   - The previous daily 1st free game limit and forced ad-on-replay gate have been **removed**.
2. **Rewarded Ads ONLY for Extra Features & Power-Ups**:
   - **Revive / Extra Lives**: Watch a Rewarded Ad to continue a run (Fruit Slash 3 Lives, Knife Hit 1 Life / clear logs, Puzzle Blast undo move, Speed Tap extra time).
   - **2X Score Boost**: Watch a Rewarded Ad to double the current score before submitting to leaderboard.
   - **Fruit Slash**: Golden Star Fruit (16% spawn rate) prompts Rewarded Ad for 2X Multiplier.
3. **⏱️ Global 60-Second Cooldown Timer on Rewarded Ads**:
   - Every Rewarded Ad (Spin, Scratch, Revive, 2X Score) is bound to a strict **60-second cooldown timer**.
   - After completing one Rewarded Ad, the user must wait 60 seconds before another rewarded ad can be triggered anywhere across the app.
   - Prevents ad spam, invalid traffic penalties, and protects Google AdMob account standing.
4. **Task-Based Earning Hub (Spin & Scratch)**:
   - Disconnected from the tournament leaderboard: points earned from Spin & Scratch go **100% directly into the user's In-App Wallet** (0 added to Leaderboard score).
   - Controlled math (100 Coins = ₹1.00) guarantees a 50% profit margin.

---

## 🤖 5. Pro-Player Bot System (Top 50 Zero-Risk Financial Shield & ₹1,000 Daily Prize Pool)

### 📌 Overview & Purpose:
During active growth and AdMob Net-30/60 reconciliation cycles, the VPS backend uses **50 Realistic Indian Pro-Player Bots** to protect the top prize brackets while giving real users an attainable daily reward:
1. **Financial Shield (Top 50 Safe)**: Ensures Ranks 1 to 50 are reserved for bots, keeping 100% of the high-value prize pool (₹895/day) virtual with **₹0 real financial liability**.
2. **Real Users Earning Zone (Ranks 51 - 100)**: Real players compete in Ranks 51 to 100 and receive **₹2.10 (210 Coins)** credited directly to their In-App Wallet every night at 12:00 AM IST.

---

### 💰 ₹1,000 Daily Prize Pool Distribution Table (Bots vs Real Users)

| Rank Bracket | Kitne Players | Per Player Reward | Total Daily Kharch | Paisa Kiske Paas Jayega? |
| :--- | :--- | :--- | :--- | :--- |
| **Rank 1** | 1 | ₹150 | ₹150 | 🤖 Aapka Bot (Safe - Virtual ₹0) |
| **Rank 2** | 1 | ₹80 | ₹80 | 🤖 Aapka Bot (Safe - Virtual ₹0) |
| **Rank 3** | 1 | ₹50 | ₹50 | 🤖 Aapka Bot (Safe - Virtual ₹0) |
| **Rank 4 - 10** | 7 | ₹25 | ₹175 | 🤖 Aapka Bot (Safe - Virtual ₹0) |
| **Rank 11 - 50** | 40 | ₹11 | ₹440 | 🤖 Aapka Bot (Safe - Virtual ₹0) |
| **Rank 51 - 100** | 50 | ₹2.10 (210 Coins) | ₹105 | 👤 **Real Users (Wallet me direct add)** |
| **TOTAL** | **100 Players** | — | **₹1,000** | **Real Payout: Only ₹105 / Day** |

> [!NOTE]
> Out of the ₹1,000 displayed prize pool, **₹895 is 100% safe inside your bot accounts**. Only ₹105 is credited as 210 wallet coins across 50 real players.

---

### 🎲 90,000+ Dynamic Indian Gamer Name Pool (25-Year Lifetime):
Bots do not have fixed/repetitive names. A smart algorithm procedurally generates realistic Indian gamer handles for all 50 bots:
* **100+ Indian First Names**: `Aman`, `Rahul`, `Rohit`, `Deepak`, `Vishal`, `Aryan`, `Sachin`, `Vikram`, `Sahil`, `Karan`, `Suraj`, `Manish`, `Gaurav`, `Pooja`, `Neha`, etc.
* **30+ Gaming Clan Prefixes**: `OP_`, `Pro_`, `Legend_`, `FF_`, `Dark_`, `King_`, `Gaming_`, `Master_`, `Elite_`, `God_`, `Vip_`, `Alpha_`, etc.
* **30+ Gamer Suffixes & Digits**: `_99`, `_Pro`, `_YT`, `_Official`, `_007`, `_FF`, `_Boss`, `_X`, `_07`, `_777`, `_Gamer`, `_Max`, etc.

* **Daily Rotation**: Har raat 12:00:00 AM IST par 50 naye aur unique naam rotate hote hain.
* **Dynamic Score Updates**: Har 2-3 ghante mein bots ka score natural curve mein badhta rehta hai taki real players rank 51 se upar na aa sakein.

#### 🧮 How Long Will 90,000 Names Last? (हिसाब):
$$\text{Total Combinations} = 100 \times 30 \times 30 = \mathbf{90,000+} \text{ unique handles}$$
$$\text{Days Capacity} = \frac{90,000 \text{ names}}{50 \text{ bots per day}} = \mathbf{1,800 \text{ दिन}} \approx \mathbf{5 \text{ साल (बिना किसी रिपीटेशन के)}}$$
* **Daily Rotation**: Har raat 12:00:00 AM IST par 50 naye aur unique naam rotate hote hain.
* Real users ko hamesha lagta hai ki pure India se naye-naye gamers aakar khel rahe hain aur rank le ja rahe hain.

---

### 🛑 6. How to Turn OFF / ON Bot Shield (बॉट सिस्टम को बंद या चालू कैसे करें)

Jab aapka Google AdMob ka payout jama ho jaye aur aap real players ko Top 50 me aane dena chahein, to aap ise **3 aasan tareeqon** se manage kar sakte hain:

#### 🟢 Method 1: Web Admin Panel (1-Click - Sabse Aasan)
1. Browser me open karein: **[https://vps.swgayanbhumi.in/admin/](https://vps.swgayanbhumi.in/admin/)**
2. **`🛡️ TOP 50 BOT FINANCIAL SHIELD`** card par jayein.
3. **Band karne ke liye**: **`🛑 TURN OFF BOT SHIELD`** button dabayein.
   * *Status turant `DISABLED (REAL PLAYERS WIN)` ho jayega aur bots leaderboard se hat jayenge. Real players direct Top ranks par aa jayenge.*
4. **Wapas Chalu karne ke liye**: **`🟢 TURN ON BOT SHIELD`** button dabayein.
   * *50 bots wapas Top 50 par set hokar shield on kar denge.*

#### 💻 Method 2: Single-Line SSH Terminal Command
PowerShell ya Terminal se direct command chalayein:

* **To TURN OFF (Band karein):**
  ```powershell
  ssh -o StrictHostKeyChecking=no -i "C:\Users\Admin\Documents\Downloads\LightsailDefaultKey-ap-south-1.pem" ubuntu@35.154.113.3 "curl -s -X POST http://localhost:3000/api/admin/toggle-bot-shield -H 'Content-Type: application/json' -H 'x-admin-source: vps-web-dashboard' -d '{\"enabled\":false}'"
  ```

* **To TURN ON (Wapas Chalu karein):**
  ```powershell
  ssh -o StrictHostKeyChecking=no -i "C:\Users\Admin\Documents\Downloads\LightsailDefaultKey-ap-south-1.pem" ubuntu@35.154.113.3 "curl -s -X POST http://localhost:3000/api/admin/toggle-bot-shield -H 'Content-Type: application/json' -H 'x-admin-source: vps-web-dashboard' -d '{\"enabled\":true}'"
  ```

#### ⚙️ Method 3: Direct Server Config (`data/db.json`)
VPS par `/home/ubuntu/arena-backend/data/db.json` me `"config"` object ke andar:
```json
"config": {
  "enableBotShield": false
}
```
Set karke `sudo pm2 restart arena-api` kar dein.

---

### 🏆 7. Daily Tournament Cycle & Midnight Automatic Cron Job

#### ⏰ Raat ke 12:00 Baje Ka Automatic Process (00:00:00 IST):
```
[Raat ke 12:00 Baje Ka Automatic Process]
                  │
                  ▼
┌──────────────────────────────────────────────────┐
│      Fetch Daily Leaderboard Scores (Real)       │
└─────────────────┬────────────────────────────────┘
                  │
                  ├─► Check Rank 1 to 50 ──► 🤖 (Bots Account: Virtual / Ignore Payout)
                  │
                  └─► Check Rank 51 to 100 👤 (Real Users)
                                    │
                                    ▼
         ┌──────────────────────────────────────────────────┐
         │ Loop through each User ID in Rank 51-100         │
         │ UPDATE user_wallet SET coins = coins + 210       │
         │ (₹2.10 Daily Tournament Reward Credited)         │
         └──────────────────────────┬───────────────────────┘
                                    │
                                    ▼
         ┌──────────────────────────────────────────────────┐
         │ Clear Leaderboard Table & Reset Bot Scores For   │
         │ The New Day (Deploy 50 Fresh Indian Bot Names)   │
         └──────────────────────────────────────────────────┘
```

1. **Tournament Type**: **Daily Championship (₹1,000 Prize Pool)**.
2. **Winner Processing (Midnight IST)**:
   - **Ranks 1 to 50 (Bots)**: Payout ignored (Virtual ₹895 remains safe).
   - **Ranks 51 to 100 (Real Players)**: Har real player ke wallet me **₹2.10 (210 Coins)** automatic add ho jate hain.
3. **Leaderboard Reset**: Har raat 12 baje sabhi players ke leaderboard score `0` par reset ho jate hain aur 50 naye bot profiles baseline scores ke sath active ho jate hain.

---

### 🎡 8. Rewarded Spin Wheel Model (100 Coins = ₹1)

#### 📋 Spin Wheel Rules & Ad Flow:
1. **Disconnected from Leaderboard**: Spin karne par leaderboard me `0` score jayega. Spin se jo bhi points milenge, seedhe user ke **In-App Wallet** me credit honge.
2. **10 Daily Spins**:
   - **Pehla Spin FREE**: User jab din me pehli baar spin screen par aayega, pehla spin 100% free milega (bina ad ke).
   - **Agli 9 Spins par Rewarded Video Ad**: Har spin se pehle 1 Rewarded Video Ad chalegi. Ad poori dekhne ke baad hi wheel ghumega aur coins credit honge.
3. **⏱️ 60-Second Cooldown**: Ek spin/ad ke baad agle spin ke liye 60-second ka countdown timer chalega.

#### 🪙 Coin Math & Probability Table (50% Margin Guarantee):
AdMob average payout: ~₹0.10 (10 paise) per rewarded video ad.
Setup: **100 Coins = ₹1.00 (1 Coin = 1 Paisa)**.

| Wheel Slot (User ko dikhega) | Coin Value | Winning Chance (Probability) | Asli Math (Parde ke peeche) |
| :--- | :--- | :--- | :--- |
| **50 Coins (Jackpot)** | ₹0.50 | **1%** | 100 me se sirf 1 bande ko milega (Hype). |
| **10 Coins** | ₹0.10 | **9%** | Kabhi-kabhi milega. |
| **5 Coins** | ₹0.05 | **60%** | Sabse zyada baar yahi aayega (Core Average). |
| **2 Coins** | ₹0.02 | **20%** | Yeh bhi aksar aayega. |
| **0 Coins (Try Again)** | ₹0.00 | **10%** | 100% profit aapka (Ad chali, coins 0). |

* **Average Result (10 Spins)**: User ko milenge average **50 Coins (₹0.50)**, jabki aapke AdMob me aayenge **₹1.00**!

---

### 💳 9. Rewarded Scratch Card Model (100 Coins = ₹1)

#### 📋 Scratch Card Rules & Ad Flow:
1. **10 Daily Scratch Cards**: Daily 10 cards milenge.
2. **Disconnected from Leaderboard**: Points seedhe user wallet me credit honge.
3. **Anti-Cheat Ad Trigger**: Card par 30% ungli ghumaate hi Rewarded Video Ad load hogi. Poori ad dekhne par hi reward unveil hoga aur wallet me add hoga.
4. **⏱️ 60-Second Cooldown**: Rewarded ad dekhne ke baad 60s cooldown lagu hoga.

#### 🪙 Coin Math & Probability Table:
| Scratch Unveil | Coin Value | Probability | Asli Math |
| :--- | :--- | :--- | :--- |
| **100 Coins (Mega Jackpot)** | ₹1.00 | **1%** | 100 me se kisi 1 bande ko milega. |
| **20 Coins** | ₹0.20 | **4%** | Kam logon ko milega. |
| **5 Coins** | ₹0.05 | **75%** | Sabse zyada baar yahi niklega (Average). |
| **2 Coins** | ₹0.02 | **10%** | Kabhi-kabhi aayega. |
| **0 Coins (Better Luck)** | ₹0.00 | **10%** | 100% profit aapka. |

* **Average Result (10 Cards)**: User ko milenge average **50 Coins (₹0.50)**, aur aapke AdMob me aayenge **₹1.00**!

---

### 📊 10. Combined Daily Earnings & The ₹50 Lock (Parde Ke Peeche Ka Asli Math)

| Feature | Ads Watched | User Earnings | Developer AdMob Revenue | Net Daily Margin |
| :--- | :--- | :--- | :--- | :--- |
| **Spin Wheel (10 Spins)** | 10 Rewarded Ads | 50 Coins (₹0.50) | ₹1.00 | +₹0.50 (50%) |
| **Scratch Card (10 Cards)** | 10 Rewarded Ads | 50 Coins (₹0.50) | ₹1.00 | +₹0.50 (50%) |
| **Daily Fixed Tasks Total** | **20 Rewarded Ads** | **100 Coins (₹1.00)** | **₹2.00** | **+₹1.00 (50% NET PROFIT)** |

#### 🔒 The ₹50 Minimum Withdrawal Lock:
* **Minimum Withdrawal Limit**: **₹50 (5,000 Coins)** par set hai.
* Ek regular casual user jo game tournament me nahi jeet pata, wo sirf roz aakar Spin aur Scratch karta hai:
  - Daily Earning = ₹1.00 (100 Coins)
  - ₹50 Withdrawal Goal Poora Hoga = **50 Din me**.
  - In 50 dinon me wo akela user aapko AdMob me kitna kamakar dega? **50 days × ₹2.00 = ₹100.00**.
  - **Aapka Net Profit**: Jab wo 50vein din ₹50 ka Google Play Code ya UPI maangega, aap use bina kisi jhijhak ke doge kyunki uski wajah se aapke AdMob me pehle hi ₹100 aa chuke hain!

---

### 🎮 11. Unlimited Free Game Play & Global 60-Second Cooldown Rules

1. **Games 100% Free**:
   - Sabhi games (Knife Hit, Fruit Slash, Puzzle Blast, TicTacToe, Speed Tap) ko khelne ya replay karne par **koi bhi ad nahi aayegi**. Khelna bilkul FREE hai!
2. **Ads Sirf Extra Features / Power-Ups Ke Liye**:
   - **Revive (Life/Knives/Move)**: Game over hone par dobara bachne ke liye Rewarded Ad.
   - **2X Score Boost**: Match khatam hone par score double karke leaderboard par chadhane ke liye Rewarded Ad.
3. **Global 60-Second Cooldown Timer**:
   - App me kisi bhi jagah (Spin, Scratch, Revive, 2X Score) jaise hi ek Rewarded Ad complete hoti hai, **60-second ka global cooldown timer start ho jata hai**.
   - Cooldown ke dauran koi naya Rewarded Ad request trigger nahi hoga aur user ko timer countdown dikhega: `⏳ कृपया XX सेकंड प्रतीक्षा करें`.
   - Isse invalid traffic (IVT), Google AdMob policy violation, aur ad fatigue se 100% suraksha milti hai.

