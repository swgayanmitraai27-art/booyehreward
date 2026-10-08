# 🎮 Booyah Rewards - Complete System & VPS Setup Documentation

---

## 🌐 1. Dedicated AWS Lightsail VPS Server Details
* **Server IP (Public IPv4):** `35.154.113.3`
* **Private IPv4:** `172.26.15.179`
* **AWS Region:** Mumbai, Zone A (`ap-south-1a`)
* **OS:** Ubuntu 24.04 LTS (64-bit)
* **Hardware:** 2 GB RAM, 2 vCPUs, 60 GB SSD, 1.5 TB Monthly Transfer
* **SSH Key Path:** `C:\Users\Admin\Documents\Downloads\LightsailDefaultKey-ap-south-1.pem`
* **SSH Command:** `ssh -i "C:\Users\Admin\Documents\Downloads\LightsailDefaultKey-ap-south-1.pem" ubuntu@35.154.113.3`

---

## 🚀 2. Backend Architecture & PM2 Process
* **Backend Directory:** `/home/ubuntu/booyah-backend/`
* **Process Manager:** PM2 (Service Name: `booyah-api`)
* **Port:** `3000` (Reverse-Proxied through Nginx on Port `80`)
* **Database Storage:** `/home/ubuntu/booyah-backend/data/db.json` (Atomic disk persistence + in-memory caching)
* **Uploaded Images Directory:** `/home/ubuntu/booyah-backend/uploads/`
* **Custom Domain URL:** `http://vps.swgayanbhumi.in` (IP: `http://35.154.113.3`)
* **Public Uploads URL:** `http://vps.swgayanbhumi.in/uploads/{filename.png}`

---

## 📡 3. Live REST API & WebSockets Endpoints

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| `http://35.154.113.3/health` | `GET` | Health Check (Returns status: OK, version) |
| `http://35.154.113.3/api/sync?uid={UID}` | `GET` | **Unified Full Sync** (Matches, Banners, Modes, Config, Notifs, User profile) |
| `ws://35.154.113.3` | `WS` | **Realtime WebSocket** for instant match updates & room password broadcast |
| `http://35.154.113.3/api/matches` | `GET / POST` | List all matches / Create new match |
| `http://35.154.113.3/api/matches/:id` | `PUT / DELETE` | Update match / Delete match |
| `http://35.154.113.3/api/matches/:id/join` | `POST` | Join match slot (atomic balance deduction & anti-duplicate) |
| `http://35.154.113.3/api/matches/:id/credentials` | `POST` | Publish Room ID and Room Password |
| `http://35.154.113.3/api/matches/:id/declare` | `POST` | Declare winners, credit winningCash, and **Auto-Respawn Next Match** |
| `http://35.154.113.3/api/upload` | `POST` | **Direct Banner / Image Upload** (`multipart/form-data`) |
| `http://35.154.113.3/api/uploads` | `GET` | **VPS Upload Gallery** (Lists all previously uploaded banners) |
| `http://35.154.113.3/api/modes` | `GET / POST / DELETE` | **Dynamic Tournament Modes** (BR, CS, Lone Wolf, Custom Modes) |
| `http://35.154.113.3/api/banners` | `GET / POST / DELETE` | Dynamic Top Slider Promo Banners CRUD |
| `http://35.154.113.3/api/config` | `GET / POST` | App Settings (Category Banners, Safe Mode, Telegram URL) |
| `http://35.154.113.3/api/payments/webhook` | `POST` | **Razorpay Automated Payment Webhook** |
| `http://35.154.113.3/api/payments/manual-deposit` | `POST` | Manual UPI Deposit request (with UTR & Screenshot) |
| `http://35.154.113.3/api/payments/approve-deposit` | `POST` | Admin approve manual deposit |
| `http://35.154.113.3/api/withdrawals` | `GET / POST / PUT` | Instant UPI Withdrawal requests & approvals |
| `http://35.154.113.3/api/notifications` | `GET / POST` | Push Notifications (Global, Match-specific, Targeted) |

---

## 💳 4. Razorpay Webhook & Payment Architecture (No Changes Required!)
* **Existing Live Webhook (Active & Safe):**  
  👉 `https://www.swgayanbhumi.in/api/skillwinner/sync`
* **Razorpay Dashboard Status:**  
  ✅ **Aapko Razorpay Dashboard me kuch bhi badalne ki zaroorat nahi hai!** Jo pehle se `swgayanbhumi.in` par configured hai, wahi active rahega.
* **How It Works Seamlessly:**
  1. User app me dynamic Razorpay QR scan karta hai ya UPI se pay karta hai.
  2. Razorpay ka webhook aapke existing `https://www.swgayanbhumi.in` par jata hai.
  3. User ka wallet (`depositCash`) aur transaction history automatically credit ho jaati hai.
  4. App me turant success screen aur naya wallet balance show ho jata hai!
  5. **No Domain Mismatch / No Razorpay Account Risk!**

---

## 📅 5. Daily 12 Matches Schedule & 75/25 Prize Economy

### 1. BR (Full Map) - 48 Players (Per Kill + Top Placement)
* **Match 1 (₹10 Entry):** Prize Pool ₹360 | Top 3 Ranks (1st: ₹150, 2nd: ₹80, 3rd: ₹50) + ₹1.5/Kill
* **Match 2 (₹20 Entry):** Prize Pool ₹720 | Top 5 Ranks (1st: ₹250, 2nd: ₹150, 3rd: ₹100, 4th: ₹50, 5th: ₹30) + ₹3.0/Kill
* **Match 3 (₹50 Entry):** Prize Pool ₹1,800 | Top 10 Ranks (1st: ₹600, 2nd: ₹350, 3rd: ₹200, 4th-5th: ₹100, 6th-10th: ₹50) + ₹8.0/Kill
* **Match 4 (₹100 Entry):** Prize Pool ₹3,600 | Top 10 Ranks (1st: ₹1200, 2nd: ₹700, 3rd: ₹400, 4th-5th: ₹200, 6th-10th: ₹100) + ₹15.0/Kill

### 2. CS (Clash Squad 4v4) - 8 Players (Winning Team takes 75%)
* **Match 1 (₹10 Entry):** ₹60 Prize Pool
* **Match 2 (₹20 Entry):** ₹120 Prize Pool
* **Match 3 (₹50 Entry):** ₹300 Prize Pool
* **Match 4 (₹100 Entry):** ₹600 Prize Pool

### 3. Lone Wolf (1v1) - 2 Players (Winner takes 75%)
* **Match 1 (₹10 Entry):** ₹15 Prize Pool (10-15 min fast turnaround)
* **Match 2 (₹20 Entry):** ₹30 Prize Pool
* **Match 3 (₹50 Entry):** ₹75 Prize Pool
* **Match 4 (₹100 Entry):** ₹150 Prize Pool

### 4. Special Mega Tournaments
* **Weekly Mega Match (Sunday):** BR 48 Slots | ₹500 Entry | ₹18,000 Prize Pool
* **Monthly Jackpot (Month End):** BR 48 Slots | ₹1,000 Entry | ₹36,000 Prize Pool

### 🔄 Auto-Progression Engine:
When any tournament finishes and results are declared, the backend server **automatically creates the next sequential match** (`#02`, `#03`, `#04`...) so users can join tournaments 24/7 without manual admin creation!

---

## 🛡️ 6. Google Play Review Safe Mode Toggle
* **Controlled from Admin Panel:**
  * **OFF (Safe Review Mode):** Hides all real money text, ₹ entry matches, UPI withdrawals, and 4-wallet UI; displays only Free Ad Coins & Redeem store.
  * **ON (Real Cash Mode):** Instantly reveals full 4 wallets, ₹ matches, deposits, and UPI payouts across all connected apps.
* **API Route:** `POST http://35.154.113.3/api/config` with `{ "isRealCashModeEnabled": true/false }`

---

## 💬 7. Official Customer Support
* **Telegram Channel / Support URL:** `http://t.me/booyahrewardofficial`
* **Default Carousel Banner:** `https://i.ibb.co/W43nNfnY/Chat-GPT-Image-Oct-7-2026-10-03-53-AM-1.png`
