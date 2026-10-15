const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');
const multer = require('multer');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const PORT = process.env.PORT || 3000;
const DB_FILE = path.join(__dirname, 'data', 'db.json');
const UPLOAD_DIR = path.join(__dirname, 'uploads');

if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

// Multer storage for direct image uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOAD_DIR),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.png';
    const cleanName = path.basename(file.originalname, ext).replace(/[^a-zA-Z0-9_-]/g, '_');
    cb(null, `banner_${Date.now()}_${cleanName}${ext}`);
  }
});
const upload = multer({
  storage,
  limits: { fileSize: 15 * 1024 * 1024 } // 15MB limit
});

app.use(cors());
app.use(bodyParser.json({ limit: '15mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '15mb' }));
app.use('/uploads', express.static(UPLOAD_DIR));

// --- DATABASE STATE ---
let db = {
  matches: [],
  users: {},
  transactions: [],
  withdrawals: [],
  voucherClaims: [],
  weeklyDistributions: [],
  referrals: [],
  banners: [],
  notifications: [],
  tournamentModes: [
    {
      key: 'BR',
      title: 'Full Map (BR)',
      bannerUrl: 'https://i.ibb.co/PvV4vz0X/brhomescreen.png',
      defaultSlots: 48,
      mode: 'br',
      enabled: true
    },
    {
      key: 'CS',
      title: 'Clash Squad (CS)',
      bannerUrl: 'https://i.ibb.co/S4qX9RW5/cshomescreen.png',
      defaultSlots: 8,
      mode: 'cs',
      enabled: true
    },
    {
      key: 'LONE_WOLF',
      title: 'Lone Wolf',
      bannerUrl: 'https://i.ibb.co/9ktcjYSX/lonewolfhomescreen.png',
      defaultSlots: 2,
      mode: 'loneWolf',
      enabled: true
    }
  ],
  config: {
    telegramSupportUrl: 'http://t.me/booyahrewardofficial',
    isRealCashModeEnabled: false,
    brBannerUrl: 'https://i.ibb.co/PvV4vz0X/brhomescreen.png',
    csBannerUrl: 'https://i.ibb.co/S4qX9RW5/cshomescreen.png',
    lwBannerUrl: 'https://i.ibb.co/9ktcjYSX/lonewolfhomescreen.png',
    appVersion: '1.3.4',
    minAppVersion: '1.3.4',
    minBuildNumber: 34,
    weeklyRank1Prize: 200,
    weeklyRank2Prize: 150,
    weeklyRank3Prize: 100,
    isForceUpdateEnabled: true,
    playStoreUrl: 'https://play.google.com/store/apps/details?id=com.swgayanbhumi.app',
    updateTitle: '⚡ App Update Required',
    updateMessage: 'Booyah Rewards ka naya version Play Store par live hai. Kripya tournaments me bina kisi problem ke continue karne ke liye app ko update karein!',
    minWithdrawalAmount: 50,
    minWithdrawalCoins: 50,
    upiQRPaymentUrl: 'upi://pay?pa=7307222384@ybl&pn=BooyahRewards&cu=INR',
    razorpayKeyId: 'rzp_live_default_key',
    razorpayKeySecret: ''
  },

  matchCounters: {
    'BR_10': 1, 'BR_20': 1, 'BR_50': 1, 'BR_100': 1,
    'CS_10': 1, 'CS_20': 1, 'CS_50': 1, 'CS_100': 1,
    'LW_10': 1, 'LW_20': 1, 'LW_50': 1, 'LW_100': 1,
    'MEGA_500': 1, 'JACKPOT_1000': 1
  },
  storeItems: [
    {
      id: 'store_gp_100',
      title: '₹100 Google Play Redeem Code',
      description: '1000 Reward Coins (Won in Free Matches) = ₹100 Google Play Redeem Code sent to your WhatsApp.',
      imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=300&auto=format&fit=crop&q=80',
      iconEmoji: '🎟️',
      rewardCoinsPrice: 1000,
      rewardValue: '₹100 Redeem Code'
    }
  ],
  stats: {
    totalAdsWatched: 0,
    totalMatchesPlayed: 0,
    totalPrizesDistributed: 0
  }
};

// --- PERSISTENCE HELPERS ---
function loadDB() {
  console.log('[DB] Checking DB_FILE:', DB_FILE, 'Exists:', fs.existsSync(DB_FILE));
  try {
    if (fs.existsSync(DB_FILE)) {
      const data = fs.readFileSync(DB_FILE, 'utf8');
      const parsed = JSON.parse(data);
      db = { ...db, ...parsed };
      if (!Array.isArray(db.storeItems) || db.storeItems.length === 0) {
        db.storeItems = [
          {
            id: 'store_gp_100',
            title: '₹100 Google Play Redeem Code',
            description: '1000 Reward Coins (Won in Free Matches) = ₹100 Google Play Redeem Code sent to your WhatsApp.',
            imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=300&auto=format&fit=crop&q=80',
            iconEmoji: '🎟️',
            rewardCoinsPrice: 1000,
            rewardValue: '₹100 Redeem Code'
          }
        ];
      } else {
        db.storeItems = db.storeItems.filter(item =>
          item.id !== 'store_ff_100' &&
          item.id !== 'store_ff_210' &&
          item.id !== 'store_gp_10' &&
          item.id !== 'store_gp_40' &&
          !(item.title || '').toLowerCase().includes('diamond')
        );
        if (db.storeItems.length === 0) {
          db.storeItems = [
            {
              id: 'store_gp_100',
              title: '₹100 Google Play Redeem Code',
              description: '1000 Reward Coins (Won in Free Matches) = ₹100 Google Play Redeem Code sent to your WhatsApp.',
              imageUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=300&auto=format&fit=crop&q=80',
              iconEmoji: '🎟️',
              rewardCoinsPrice: 1000,
              rewardValue: '₹100 Redeem Code'
            }
          ];
        }
      }
      console.log(`[DB] Loaded successfully. Matches: ${db.matches.length}, Users: ${Object.keys(db.users).length}`);
      // Auto-Repair: ensure anyone in db.referrals has referralCoins & referredBy credited properly
      if (Array.isArray(db.referrals)) {
        db.referrals.forEach(ref => {
          if (ref.referredUid && db.users[ref.referredUid]) {
            const u = db.users[ref.referredUid];
            const w = ensureUserWallet(u);
            if (!u.referredBy) u.referredBy = ref.referrerCode;
            if ((w.referralCoins || 0) < 5) {
              w.referralCoins = Math.max(w.referralCoins || 0, 5);
              u.wallets = w;
              u.wallet = w;
              u.referralCoins = w.referralCoins;
              u.referral_coins = w.referralCoins;
            }
          }
          if (ref.referrerUid && db.users[ref.referrerUid]) {
            const u = db.users[ref.referrerUid];
            const w = ensureUserWallet(u);
            if ((w.referralCoins || 0) < 5) {
              w.referralCoins = Math.max(w.referralCoins || 0, 5);
              u.wallets = w;
              u.wallet = w;
              u.referralCoins = w.referralCoins;
              u.referral_coins = w.referralCoins;
            }
          }
        });
        saveDB();
      }
    } else {
      console.log('[DB] No existing db.json found. Seeding initial data...');
      seedInitialData();
      saveDB();
    }
  } catch (err) {
    console.error('[DB] Load error:', err);
    seedInitialData();
  }
}

let saveTimeout = null;
function saveDB() {
  if (saveTimeout) clearTimeout(saveTimeout);
  saveTimeout = setTimeout(() => {
    try {
      const dir = path.dirname(DB_FILE);
      if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
      fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2), 'utf8');
    } catch (err) {
      console.error('[DB] Save error:', err);
    }
  }, 300);
}

// --- UNIFIED USER WALLET HELPER ---
function ensureUserWallet(user) {
  if (!user) return null;
  if (!user.wallet && !user.wallets) {
    user.wallet = { adCoins: 0, referralCoins: 0, rewardCoins: 0, depositCash: 0, winningCash: 0, bonusCash: 0 };
    user.wallets = user.wallet;
  } else if (!user.wallet) {
    user.wallet = user.wallets;
  } else if (!user.wallets) {
    user.wallets = user.wallet;
  }
  user.wallet.adCoins = Number(user.wallet.adCoins || user.wallets.adCoins || 0);
  user.wallet.referralCoins = Number(user.wallet.referralCoins || user.wallets.referralCoins || 0);
  user.wallet.rewardCoins = Number(user.wallet.rewardCoins || user.wallets.rewardCoins || 0);
  user.wallet.depositCash = Number(user.wallet.depositCash || user.wallets.depositCash || 0);
  user.wallet.winningCash = Number(user.wallet.winningCash || user.wallets.winningCash || 0);
  user.wallet.bonusCash = Number(user.wallet.bonusCash || user.wallets.bonusCash || 0);
  user.wallets = user.wallet;
  return user.wallet;
}

// --- WEBSOCKET BROADCAST ---
function broadcast(type, payload) {
  const message = JSON.stringify({ type, payload, timestamp: new Date().toISOString() });
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

wss.on('connection', (ws) => {
  ws.send(JSON.stringify({ type: 'CONNECTED', message: 'Booyah Realtime WebSocket Connected' }));
});

// --- MATCH GENERATION HELPER ---
function calculatePrizePool(entryFee, maxSlots, mode) {
  const totalCollection = entryFee * maxSlots;
  const grossPrizePool = totalCollection * 0.75; // 75% Prize Pool
  const perKill = mode === 'br' ? Math.max(1.0, Math.round((entryFee * 0.15) * 10) / 10) : 0;

  let firstPlace = 0;
  let secondPlace = null;
  let thirdPlace = null;
  let fourthPlace = null;
  let fifthPlace = null;

  if (mode === 'br') {
    if (entryFee <= 10) {
      firstPlace = Math.round(grossPrizePool * 0.50);
      secondPlace = Math.round(grossPrizePool * 0.30);
      thirdPlace = Math.round(grossPrizePool * 0.20);
    } else if (entryFee <= 20) {
      firstPlace = Math.round(grossPrizePool * 0.40);
      secondPlace = Math.round(grossPrizePool * 0.25);
      thirdPlace = Math.round(grossPrizePool * 0.18);
      fourthPlace = Math.round(grossPrizePool * 0.10);
      fifthPlace = Math.round(grossPrizePool * 0.07);
    } else {
      firstPlace = Math.round(grossPrizePool * 0.35);
      secondPlace = Math.round(grossPrizePool * 0.22);
      thirdPlace = Math.round(grossPrizePool * 0.15);
      fourthPlace = Math.round(grossPrizePool * 0.10);
      fifthPlace = Math.round(grossPrizePool * 0.08);
    }
  } else {
    // CS & Lone Wolf: Winner team/player gets entire 75% pool
    firstPlace = Math.round(grossPrizePool);
  }

  return {
    totalPool: grossPrizePool,
    perKill,
    firstPlace,
    secondPlace,
    thirdPlace,
    fourthPlace,
    fifthPlace
  };
}

function createScheduledMatch({ key, titlePrefix, entryFee, maxSlots, mode, teamType, matchFormat, mapType, bannerUrl, scheduleOffsetMinutes = 30 }) {
  const matchIndex = db.matchCounters[key] || 1;
  const numStr = matchIndex.toString().padStart(2, '0');
  const matchId = `match_${key.toLowerCase()}_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
  const prizePool = calculatePrizePool(entryFee, maxSlots, mode);

  return {
    id: matchId,
    title: `${titlePrefix} #${numStr}`,
    bannerImage: bannerUrl,
    gameType: 'freeFire',
    mode,
    teamType,
    matchFormat,
    map: mapType,
    matchType: entryFee > 0 ? 'paid' : 'free',
    entryFeeType: entryFee > 0 ? 'cash' : 'adCoins',
    entryFee,
    prizePool,
    maxSlots,
    filledSlots: 0,
    credentials: { roomId: '', roomPassword: '', isRevealed: false },
    status: 'upcoming',
    matchTime: new Date(Date.now() + scheduleOffsetMinutes * 60 * 1000).toISOString(),
    participants: [],
    registeredTeams: [],
    hasUserWatchedAdToUnlockRoom: false,
    hostName: 'Booyah Esports Official'
  };
}

function seedInitialData() {
  if (db.matches && db.matches.length > 0) return;
  db.banners = [
    {
      id: 'banner_tg_official',
      title: 'Official Telegram Support & Daily Updates',
      imageUrl: 'https://i.ibb.co/W43nNfnY/Chat-GPT-Image-Oct-7-2026-10-03-53-AM-1.png',
      clickUrl: 'http://t.me/booyahrewardofficial',
      isActive: true,
      createdAt: new Date().toISOString()
    }
  ];

  const brBanner = db.config.brBannerUrl;
  const csBanner = db.config.csBannerUrl;
  const lwBanner = db.config.lwBannerUrl;

  db.matches = [
    // 0. Free Tournaments (0 ₹ / Free Entry - Play for Ad Coins & Redeem Codes)
    createScheduledMatch({ key: 'BR_FREE', titlePrefix: 'Free BR Solo (0 ₹ Entry)', entryFee: 0, maxSlots: 48, mode: 'br', teamType: 'solo', matchFormat: 'solo', mapType: 'bermuda', bannerUrl: brBanner, scheduleOffsetMinutes: 15 }),
    createScheduledMatch({ key: 'CS_FREE', titlePrefix: 'Free CS 4v4 Squad (0 ₹ Entry)', entryFee: 0, maxSlots: 8, mode: 'cs', teamType: 'squad', matchFormat: 'cs4v4', mapType: 'bermuda', bannerUrl: csBanner, scheduleOffsetMinutes: 20 }),
    createScheduledMatch({ key: 'LW_FREE', titlePrefix: 'Free Lone Wolf 1v1 (0 ₹ Entry)', entryFee: 0, maxSlots: 2, mode: 'loneWolf', teamType: 'solo', matchFormat: 'loneWolf1v1', mapType: 'bermuda', bannerUrl: lwBanner, scheduleOffsetMinutes: 10 }),

    // 1. BR Full Map (4 Matches)
    createScheduledMatch({ key: 'BR_10', titlePrefix: 'BR Solo (₹10 Entry)', entryFee: 10, maxSlots: 48, mode: 'br', teamType: 'solo', matchFormat: 'solo', mapType: 'bermuda', bannerUrl: brBanner, scheduleOffsetMinutes: 30 }),
    createScheduledMatch({ key: 'BR_20', titlePrefix: 'BR Solo (₹20 Entry)', entryFee: 20, maxSlots: 48, mode: 'br', teamType: 'solo', matchFormat: 'solo', mapType: 'purgatory', bannerUrl: brBanner, scheduleOffsetMinutes: 60 }),
    createScheduledMatch({ key: 'BR_50', titlePrefix: 'BR Solo (₹50 Entry)', entryFee: 50, maxSlots: 48, mode: 'br', teamType: 'solo', matchFormat: 'solo', mapType: 'bermuda', bannerUrl: brBanner, scheduleOffsetMinutes: 90 }),
    createScheduledMatch({ key: 'BR_100', titlePrefix: 'BR Solo (₹100 Entry)', entryFee: 100, maxSlots: 48, mode: 'br', teamType: 'solo', matchFormat: 'solo', mapType: 'kalahari', bannerUrl: brBanner, scheduleOffsetMinutes: 120 }),

    // 2. Clash Squad (4 Matches)
    createScheduledMatch({ key: 'CS_10', titlePrefix: 'CS 4v4 Squad (₹10 Entry)', entryFee: 10, maxSlots: 8, mode: 'cs', teamType: 'squad', matchFormat: 'cs4v4', mapType: 'bermuda', bannerUrl: csBanner, scheduleOffsetMinutes: 15 }),
    createScheduledMatch({ key: 'CS_20', titlePrefix: 'CS 4v4 Squad (₹20 Entry)', entryFee: 20, maxSlots: 8, mode: 'cs', teamType: 'squad', matchFormat: 'cs4v4', mapType: 'bermuda', bannerUrl: csBanner, scheduleOffsetMinutes: 25 }),
    createScheduledMatch({ key: 'CS_50', titlePrefix: 'CS 4v4 Squad (₹50 Entry)', entryFee: 50, maxSlots: 8, mode: 'cs', teamType: 'squad', matchFormat: 'cs4v4', mapType: 'bermuda', bannerUrl: csBanner, scheduleOffsetMinutes: 45 }),
    createScheduledMatch({ key: 'CS_100', titlePrefix: 'CS 4v4 Squad (₹100 Entry)', entryFee: 100, maxSlots: 8, mode: 'cs', teamType: 'squad', matchFormat: 'cs4v4', mapType: 'bermuda', bannerUrl: csBanner, scheduleOffsetMinutes: 60 }),

    // 3. Lone Wolf (4 Matches)
    createScheduledMatch({ key: 'LW_10', titlePrefix: 'Lone Wolf 1v1 (₹10 Entry)', entryFee: 10, maxSlots: 2, mode: 'loneWolf', teamType: 'solo', matchFormat: 'loneWolf1v1', mapType: 'bermuda', bannerUrl: lwBanner, scheduleOffsetMinutes: 10 }),
    createScheduledMatch({ key: 'LW_20', titlePrefix: 'Lone Wolf 1v1 (₹20 Entry)', entryFee: 20, maxSlots: 2, mode: 'loneWolf', teamType: 'solo', matchFormat: 'loneWolf1v1', mapType: 'bermuda', bannerUrl: lwBanner, scheduleOffsetMinutes: 20 }),
    createScheduledMatch({ key: 'LW_50', titlePrefix: 'Lone Wolf 1v1 (₹50 Entry)', entryFee: 50, maxSlots: 2, mode: 'loneWolf', teamType: 'solo', matchFormat: 'loneWolf1v1', mapType: 'bermuda', bannerUrl: lwBanner, scheduleOffsetMinutes: 30 }),
    createScheduledMatch({ key: 'LW_100', titlePrefix: 'Lone Wolf 1v1 (₹100 Entry)', entryFee: 100, maxSlots: 2, mode: 'loneWolf', teamType: 'solo', matchFormat: 'loneWolf1v1', mapType: 'bermuda', bannerUrl: lwBanner, scheduleOffsetMinutes: 40 }),

    // 4. Special Mega & Jackpot
    createScheduledMatch({ key: 'MEGA_500', titlePrefix: 'Weekly Mega Sunday (₹500 Entry)', entryFee: 500, maxSlots: 48, mode: 'br', teamType: 'solo', matchFormat: 'solo', mapType: 'bermuda', bannerUrl: brBanner, scheduleOffsetMinutes: 1440 }),
    createScheduledMatch({ key: 'JACKPOT_1000', titlePrefix: 'Monthly Jackpot (₹1000 Entry)', entryFee: 1000, maxSlots: 48, mode: 'br', teamType: 'solo', matchFormat: 'solo', mapType: 'bermuda', bannerUrl: brBanner, scheduleOffsetMinutes: 2880 })
  ];

  console.log('[Seed] 12 Daily Matches + Special Mega Matches initialized.');
}

function autoRespawnCompletedMatch(completedMatch) {
  let key = null;
  let titlePrefix = '';
  const fee = completedMatch.entryFee;
  const mode = completedMatch.mode;

  if (mode === 'br') {
    if (fee === 10) { key = 'BR_10'; titlePrefix = 'BR Solo (₹10 Entry)'; }
    else if (fee === 20) { key = 'BR_20'; titlePrefix = 'BR Solo (₹20 Entry)'; }
    else if (fee === 50) { key = 'BR_50'; titlePrefix = 'BR Solo (₹50 Entry)'; }
    else if (fee === 100) { key = 'BR_100'; titlePrefix = 'BR Solo (₹100 Entry)'; }
  } else if (mode === 'cs') {
    if (fee === 10) { key = 'CS_10'; titlePrefix = 'CS 4v4 Squad (₹10 Entry)'; }
    else if (fee === 20) { key = 'CS_20'; titlePrefix = 'CS 4v4 Squad (₹20 Entry)'; }
    else if (fee === 50) { key = 'CS_50'; titlePrefix = 'CS 4v4 Squad (₹50 Entry)'; }
    else if (fee === 100) { key = 'CS_100'; titlePrefix = 'CS 4v4 Squad (₹100 Entry)'; }
  } else if (mode === 'loneWolf') {
    if (fee === 10) { key = 'LW_10'; titlePrefix = 'Lone Wolf 1v1 (₹10 Entry)'; }
    else if (fee === 20) { key = 'LW_20'; titlePrefix = 'Lone Wolf 1v1 (₹20 Entry)'; }
    else if (fee === 50) { key = 'LW_50'; titlePrefix = 'Lone Wolf 1v1 (₹50 Entry)'; }
    else if (fee === 100) { key = 'LW_100'; titlePrefix = 'Lone Wolf 1v1 (₹100 Entry)'; }
  }

  if (key) {
    db.matchCounters[key] = (db.matchCounters[key] || 1) + 1;
    const bannerUrl = mode === 'br' ? db.config.brBannerUrl : (mode === 'cs' ? db.config.csBannerUrl : db.config.lwBannerUrl);
    const newMatch = createScheduledMatch({
      key,
      titlePrefix,
      entryFee: completedMatch.entryFee,
      maxSlots: completedMatch.maxSlots,
      mode: completedMatch.mode,
      teamType: completedMatch.teamType,
      matchFormat: completedMatch.matchFormat,
      mapType: completedMatch.map,
      bannerUrl,
      scheduleOffsetMinutes: mode === 'loneWolf' ? 15 : (mode === 'cs' ? 25 : 45)
    });
    db.matches.unshift(newMatch);
    saveDB();
    broadcast('MATCH_SPAWNED', newMatch);
    console.log(`[AutoRespawn] Created fresh replacement tournament: ${newMatch.title}`);
  }
}

// --- API ROUTES ---

// 1. Direct Image File Upload
app.post('/api/upload', upload.single('image'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, message: 'No image file uploaded' });
  }
  const host = req.get('host') || '35.154.113.3';
  const protocol = req.protocol === 'https' ? 'https' : 'http';
  const fileUrl = `${protocol}://${host}/uploads/${req.file.filename}`;

  console.log(`[Upload] Image uploaded: ${fileUrl}`);
  res.json({
    success: true,
    fileUrl,
    filename: req.file.filename,
    size: req.file.size
  });
});

// 2. Get Uploaded Images Gallery
app.get('/api/uploads', (req, res) => {
  try {
    const files = fs.readdirSync(UPLOAD_DIR);
    const host = req.get('host') || '35.154.113.3';
    const protocol = req.protocol === 'https' ? 'https' : 'http';
    const fileList = files
      .filter(f => /\.(png|jpg|jpeg|webp|gif)$/i.test(f))
      .map(f => {
        const stats = fs.statSync(path.join(UPLOAD_DIR, f));
        return {
          filename: f,
          url: `${protocol}://${host}/uploads/${f}`,
          createdAt: stats.mtime.toISOString(),
          size: stats.size
        };
      })
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.json({ success: true, files: fileList });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// 3. Unified Sync Endpoint
app.get('/api/sync', (req, res) => {
  const { uid, email } = req.query;
  let user = uid && db.users[uid] ? db.users[uid] : null;
  if (!user && email) {
    user = Object.values(db.users || {}).find(u => u.email && u.email.toLowerCase() === email.toLowerCase());
  }

  if (user) {
    ensureUserWallet(user);
  }
  const activeBanners = db.banners.filter(b => b.isActive);

  res.json({
    success: true,
    matches: db.matches,
    banners: activeBanners,
    modes: db.tournamentModes || [],
    config: db.config,
    notifications: (db.notifications || []).slice(0, 30),
    referrals: db.referrals || [],
    transactions: (db.transactions || []).slice(0, 100),
    allUsers: Object.values(db.users || {}),
    storeItems: db.storeItems || [],
    voucherClaims: db.voucherClaims || [],
    user,
    stats: db.stats
  });
});

app.post('/api/skillwinner/sync', (req, res) => {
  const { action, uid, data } = req.body;

  if (action === 'set_real_cash_mode') {
    db.config.isRealCashModeEnabled = !!data?.isRealCashModeEnabled;
    saveDB();
    broadcast('CONFIG_UPDATED', db.config);
    return res.json({ success: true, isRealCashModeEnabled: db.config.isRealCashModeEnabled });
  }

  const user = uid && db.users[uid] ? db.users[uid] : null;
  res.json({
    success: true,
    matches: db.matches,
    banners: db.banners.filter(b => b.isActive),
    modes: db.tournamentModes || [],
    config: db.config,
    notifications: db.notifications.slice(0, 30),
    user,
    stats: db.stats
  });
});

// Dynamic Tournament Modes CRUD
app.get('/api/modes', (req, res) => {
  res.json({ success: true, modes: db.tournamentModes || [] });
});

app.post('/api/modes', (req, res) => {
  const { key, title, bannerUrl, defaultSlots, mode, enabled } = req.body;
  if (!key || !title) return res.status(400).json({ success: false, message: 'Key and title required' });

  if (!db.tournamentModes) db.tournamentModes = [];
  const cleanKey = key.toUpperCase().replace(/\s+/g, '_');
  const index = db.tournamentModes.findIndex(m => m.key.toUpperCase() === cleanKey);

  const modeObj = {
    key: cleanKey,
    title,
    bannerUrl: bannerUrl || 'https://i.ibb.co/PvV4vz0X/brhomescreen.png',
    defaultSlots: parseInt(defaultSlots) || 48,
    mode: mode || 'br',
    enabled: enabled !== undefined ? enabled : true
  };

  if (index >= 0) {
    db.tournamentModes[index] = { ...db.tournamentModes[index], ...modeObj };
  } else {
    db.tournamentModes.push(modeObj);
  }

  if (cleanKey === 'BR') db.config.brBannerUrl = modeObj.bannerUrl;
  if (cleanKey === 'CS') db.config.csBannerUrl = modeObj.bannerUrl;
  if (cleanKey === 'LONE_WOLF') db.config.lwBannerUrl = modeObj.bannerUrl;

  saveDB();
  broadcast('MODES_UPDATED', db.tournamentModes);
  res.json({ success: true, mode: modeObj, modes: db.tournamentModes });
});

app.delete('/api/modes/:key', (req, res) => {
  const { key } = req.params;
  const cleanKey = key.toUpperCase();
  if (['BR', 'CS', 'LONE_WOLF'].includes(cleanKey)) {
    const m = db.tournamentModes.find(item => item.key.toUpperCase() === cleanKey);
    if (m) m.enabled = false;
  } else {
    db.tournamentModes = db.tournamentModes.filter(item => item.key.toUpperCase() !== cleanKey);
  }
  saveDB();
  broadcast('MODES_UPDATED', db.tournamentModes);
  res.json({ success: true, modes: db.tournamentModes });
});


// 4. Matches CRUD
app.get('/api/matches', (req, res) => {
  res.json({ success: true, matches: db.matches });
});

function refundMatchParticipants(match) {
  if (!match || !Array.isArray(match.participants) || match.participants.length === 0) return;
  console.log(`[Refund] Processing refund for match #${match.matchNumber || match.id} (${match.participants.length} players)`);
  for (const p of match.participants) {
    const user = db.users[p.uid];
    if (!user) continue;
    if (!user.wallet) user.wallet = { adCoins: 0, rewardCoins: 0, depositCash: 0, winningCash: 0, bonusCash: 0 };
    if (!user.wallets) user.wallets = user.wallet;

    const refundAmt = Number(p.amountPaid) || Number(match.entryFee) || 0;
    const isCash = p.paidWith === 'DEPOSIT_CASH' || match.entryFeeType === 'cash' || match.matchType === 'paid';

    if (!isCash) {
      user.wallet.adCoins = (user.wallet.adCoins || 0) + refundAmt;
      user.wallets.adCoins = user.wallet.adCoins;

      const txn = {
        id: `txn_ref_${Date.now()}_${(p.uid || '').substring(0, 5)}`,
        userId: p.uid,
        userName: user.displayName || user.inGameName,
        amount: refundAmt,
        currency: 'AD_COINS',
        type: 'matchRefund',
        walletAffected: 'adCoins',
        title: '🟡 Match Refund: Ad Coins Returned',
        description: `Match #${match.matchNumber || match.title} cancelled by admin. Entry refund.`,
        status: 'SUCCESS',
        createdAt: new Date().toISOString()
      };
      if (!db.transactions) db.transactions = [];
      db.transactions.unshift(txn);

      if (!db.notifications) db.notifications = [];
      db.notifications.unshift({
        id: `notif_ref_${Date.now()}_${(p.uid || '').substring(0, 5)}`,
        title: '🟡 Ad Coins Refunded!',
        body: `मुकाबला #${match.matchNumber || match.title} रद्द हो गया है। आपके ${refundAmt} Ad Coins वापस आपके वॉलेट में रिफंड कर दिए गए हैं।`,
        createdAt: new Date().toISOString(),
        type: 'matchResult',
        targetType: 'user',
        targetId: p.uid
      });
    } else {
      user.wallet.depositCash = (user.wallet.depositCash || 0) + refundAmt;
      user.wallets.depositCash = user.wallet.depositCash;

      const txn = {
        id: `txn_ref_${Date.now()}_${(p.uid || '').substring(0, 5)}`,
        userId: p.uid,
        userName: user.displayName || user.inGameName,
        amount: refundAmt,
        currency: 'INR',
        type: 'matchRefund',
        walletAffected: 'depositCash',
        title: '💵 Match Refund: Entry Cash Returned',
        description: `Match #${match.matchNumber || match.title} cancelled by admin. Entry refund.`,
        status: 'SUCCESS',
        createdAt: new Date().toISOString()
      };
      if (!db.transactions) db.transactions = [];
      db.transactions.unshift(txn);

      if (!db.notifications) db.notifications = [];
      db.notifications.unshift({
        id: `notif_ref_${Date.now()}_${(p.uid || '').substring(0, 5)}`,
        title: '💵 Cash Entry Refunded!',
        body: `मुकाबला #${match.matchNumber || match.title} रद्द हो गया है। आपके ₹${refundAmt} Deposit Cash आपके वॉलेट में वापस रिफंड कर दिए गए हैं।`,
        createdAt: new Date().toISOString(),
        type: 'matchResult',
        targetType: 'user',
        targetId: p.uid
      });
    }
    if (user.stats && user.stats.matchesPlayed > 0) {
      user.stats.matchesPlayed -= 1;
    }
  }
}

app.post('/api/matches', (req, res) => {
  const match = {
    ...req.body,
    id: req.body.id || `match_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
    filledSlots: req.body.participants?.length || 0,
    status: req.body.status || 'upcoming',
    participants: req.body.participants || [],
    registeredTeams: req.body.registeredTeams || []
  };
  db.matches.unshift(match);

  // Auto-broadcast personalized notification to all users in Hindi
  try {
    const bannerUrl = match.bannerUrl || 'https://vps.swgayanbhumi.in/uploads/banner_1791739318242_update_banner.jpg';
    const titleText = match.title || 'Free Fire महा-मुकाबला';
    const entryText = match.entryFee > 0 ? `${match.entryFee} Coins/₹` : 'FREE';
    const prizeText = match.prizePool?.totalPool || 400;

    for (const u of Object.values(db.users || {})) {
      const uName = u.displayName || u.inGameName || 'खिलाड़ी';
      if (!db.notifications) db.notifications = [];
      db.notifications.unshift({
        id: `notif_m_${Date.now()}_${(u.uid || '').substring(0, 5)}`,
        title: `🎮 ${uName}, नया मुकाबला तैयार है!`,
        body: `${titleText} में ₹${prizeText} जीतें! सिर्फ ${entryText} देकर अभी अपनी सीट बुक करें! ⚡`,
        imageUrl: bannerUrl,
        matchId: match.id,
        type: 'matchCreated',
        targetType: 'user',
        targetId: u.uid,
        createdAt: new Date().toISOString()
      });
    }
  } catch(e) {
    console.error('[Match Notification Error]:', e);
  }

  saveDB();
  broadcast('MATCH_CREATED', match);
  res.json({ success: true, match });
});

app.put('/api/matches/:id', (req, res) => {
  const { id } = req.params;
  const index = db.matches.findIndex(m => m.id === id);
  if (index === -1) {
    db.matches.unshift(req.body);
    saveDB();
    broadcast('MATCH_CREATED', req.body);
    return res.json({ success: true, match: req.body });
  }

  const prevStatus = db.matches[index].status;
  db.matches[index] = { ...db.matches[index], ...req.body };

  if (prevStatus !== 'cancelled' && db.matches[index].status === 'cancelled') {
    refundMatchParticipants(db.matches[index]);
  }

  saveDB();
  broadcast('MATCH_UPDATED', db.matches[index]);

  if (prevStatus !== 'completed' && db.matches[index].status === 'completed') {
    autoRespawnCompletedMatch(db.matches[index]);
  }

  res.json({ success: true, match: db.matches[index] });
});

app.delete('/api/matches/:id', (req, res) => {
  const { id } = req.params;
  const match = db.matches.find(m => m.id === id);
  if (match) {
    if (match.status !== 'completed' && !match.isRefunded) {
      match.isRefunded = true;
      refundMatchParticipants(match);
    }
    db.matches = db.matches.filter(m => m.id !== id);
    saveDB();
    broadcast('MATCH_DELETED', { id });
    return res.json({ success: true, id });
  }
  res.status(404).json({ success: false, message: 'Match not found' });
});

app.post('/api/admin/reset_matches', (req, res) => {
  db.matches = Array.isArray(req.body.matches) ? req.body.matches : [];
  saveDB();
  broadcast('MATCHES_UPDATED', db.matches);
  res.json({ success: true, count: db.matches.length, matches: db.matches });
});

app.delete('/api/admin/delete_all_matches', (req, res) => {
  db.matches = [];
  saveDB();
  broadcast('MATCHES_CLEARED', {});
  res.json({ success: true, message: 'All matches deleted' });
});

// 5. Join Match Slot
app.post('/api/matches/:id/join', (req, res) => {
  const { id } = req.params;
  const { uid, inGameName, inGameUid, slotNumber, paidWith, amountPaid, teamName } = req.body;

  const match = db.matches.find(m => m.id === id);
  if (!match) return res.status(404).json({ success: false, message: 'Match not found' });

  if (match.status === 'completed' || match.status === 'cancelled') {
    return res.status(400).json({ success: false, message: 'Match is already completed or cancelled!' });
  }

  if (match.participants.some(p => p.slotNumber === slotNumber)) {
    return res.status(400).json({ success: false, message: `Slot #${slotNumber} already taken!` });
  }

  if (match.participants.some(p => p.uid === uid)) {
    return res.status(400).json({ success: false, message: 'You have already joined this match!' });
  }

  const effectiveFee = Number(amountPaid) || Number(match.entryFee) || 0;
  const isFreeCoinMatch = match.matchType === 'free' || match.entryFeeType === 'adCoins' || paidWith === 'AD_COINS' || paidWith === 'AD_AND_REF_COINS';
  const user = db.users[uid];
  if (user) {
    const wallet = ensureUserWallet(user);
    if (isFreeCoinMatch) {
      if (effectiveFee > 0) {
        const maxRefCap = Math.floor(effectiveFee * 0.50);
        const usableRef = Math.min(wallet.referralCoins || 0, maxRefCap);
        const requiredAd = Math.max(0, effectiveFee - usableRef);
        if ((wallet.adCoins || 0) < requiredAd) {
          return res.status(400).json({
            success: false,
            message: `Free Match Rule: Max 50% (${maxRefCap} Coins) Referral Coins use ho sakte hain! Baaki ${requiredAd} 🟡 Ad Coins ke liye Ads dekhein.`
          });
        }
        wallet.referralCoins = Math.max(0, (wallet.referralCoins || 0) - usableRef);
        wallet.adCoins = Math.max(0, (wallet.adCoins || 0) - requiredAd);
      }
    } else {
      const totalCash = (wallet.bonusCash || 0) + (wallet.depositCash || 0) + (wallet.winningCash || 0);
      if (totalCash < effectiveFee) {
        return res.status(400).json({ success: false, message: 'Insufficient Cash balance!' });
      }
      let remaining = effectiveFee;
      if (wallet.bonusCash >= remaining) {
        wallet.bonusCash -= remaining;
        remaining = 0;
      } else {
        remaining -= wallet.bonusCash;
        wallet.bonusCash = 0;
        if (wallet.depositCash >= remaining) {
          wallet.depositCash -= remaining;
          remaining = 0;
        } else {
          remaining -= wallet.depositCash;
          wallet.depositCash = 0;
          wallet.winningCash = Math.max(0, wallet.winningCash - remaining);
        }
      }
    }
    user.wallets = wallet;
    user.stats = user.stats || {};
    user.stats.matchesPlayed = (user.stats.matchesPlayed || 0) + 1;
  }

  const participant = {
    uid,
    inGameName,
    inGameUid,
    slotNumber,
    paidWith: paidWith || (isFreeCoinMatch ? 'AD_COINS' : 'DEPOSIT_CASH'),
    amountPaid: effectiveFee,
    joinedAt: new Date().toISOString(),
    kills: 0,
    teamName
  };

  match.participants.push(participant);
  match.filledSlots = match.participants.length;
  if (match.filledSlots >= match.maxSlots && match.status === 'upcoming') {
    match.status = 'roomFilling';
  }

  saveDB();
  broadcast('MATCH_JOINED', { matchId: id, participant, filledSlots: match.filledSlots, status: match.status });
  res.json({ success: true, match, user });
});

// 6. Update Credentials (Room ID & Password)
app.post('/api/matches/:id/credentials', (req, res) => {
  const { id } = req.params;
  const { roomId, roomPassword, isRevealed, publisherUid, publisherName } = req.body;
  const match = db.matches.find(m => m.id === id);
  if (!match) return res.status(404).json({ success: false, message: 'Match not found' });

  match.credentials = {
    roomId: roomId !== undefined ? roomId : match.credentials.roomId,
    roomPassword: roomPassword !== undefined ? roomPassword : match.credentials.roomPassword,
    isRevealed: isRevealed !== undefined ? isRevealed : true
  };

  if (publisherUid) match.roomPublishedByAdminUid = publisherUid;
  if (publisherName) match.roomPublishedByAdminName = publisherName;
  match.roomPublishedAt = new Date().toISOString();

  if (match.credentials.roomId && match.status === 'upcoming') {
    match.status = 'roomFilling';
  }

  // AUTOMATIC 25% HOST PROFIT COMMISSION:
  let hostCommissionCredited = 0;
  const isPaid = match.matchType === 'paid' || (match.entryFee && match.entryFee > 0);
  if (isPaid && !match.hostCommissionPaid && publisherUid) {
    const totalCollection = (match.entryFee || 0) * ((match.participants && match.participants.length) || match.joinedCount || 0);
    const prizeTotal = (match.prizePool && (match.prizePool.totalPool || match.prizePool.totalPrize)) || 0;
    let profit = totalCollection - prizeTotal;
    if (profit <= 0) profit = totalCollection * 0.25;
    const commission = Math.round((profit * 0.25) * 100) / 100;

    if (commission > 0) {
      const hostUser = db.users[publisherUid];
      if (hostUser) {
        const wallet = ensureUserWallet(hostUser);
        wallet.winningCash = (wallet.winningCash || 0) + commission;
        hostUser.wallets = wallet;
        hostUser.stats = hostUser.stats || {};
        hostUser.stats.totalWinningsCash = (hostUser.stats.totalWinningsCash || 0) + commission;

        const hostTxn = {
          id: `txn_host_${Date.now()}_${publisherUid}`,
          userId: publisherUid,
          userName: publisherName || hostUser.displayName || 'Host Admin',
          type: 'hostCommission',
          walletAffected: 'winningCash',
          amount: commission,
          currency: 'INR',
          balanceAfter: hostUser.wallet.winningCash,
          status: 'SUCCESS',
          description: `💰 25% Host Profit Commission for Match #${match.id} ("${match.title}")`,
          createdAt: new Date().toISOString()
        };
        db.transactions.unshift(hostTxn);
        match.hostCommissionPaid = true;
        match.hostCommissionAmount = commission;
        hostCommissionCredited = commission;
      }
    }
  }

  saveDB();
  broadcast('CREDENTIALS_UPDATED', { matchId: id, credentials: match.credentials, status: match.status, hostCommissionCredited });
  res.json({ success: true, credentials: match.credentials, hostCommissionCredited });
});

// 7. Declare Match Winners & Distribute Prizes
app.post('/api/matches/:id/declare', (req, res) => {
  const { id } = req.params;
  const { results } = req.body;
  const match = db.matches.find(m => m.id === id);
  if (!match) return res.status(404).json({ success: false, message: 'Match not found' });

  match.status = 'completed';
  match.completedAt = new Date().toISOString();

  let totalPrizeGiven = 0;
  const isPaid = match.matchType === 'paid' || match.entryFeeType === 'cash' || (match.prizePool && match.prizePool.isCashPrize);

  if (Array.isArray(results)) {
    results.forEach(resItem => {
      const p = match.participants.find(part => part.uid === resItem.uid);
      if (p) {
        p.kills = resItem.kills || 0;
        p.rank = resItem.rank;
        p.prizeAwarded = resItem.prizeAwarded || 0;
        p.isWinner = (resItem.rank === 1);

        const user = db.users[p.uid];
        if (user) {
          const wallet = ensureUserWallet(user);
          if (!user.stats) user.stats = {};

          user.stats.matchesWon = (user.stats.matchesWon || 0) + (p.isWinner ? 1 : 0);
          user.stats.totalKills = (user.stats.totalKills || 0) + p.kills;

          if (p.prizeAwarded > 0) {
            totalPrizeGiven += p.prizeAwarded;
            const balBefore = isPaid ? (wallet.winningCash || 0) : (wallet.rewardCoins || 0);

            if (isPaid) {
              wallet.winningCash = (wallet.winningCash || 0) + p.prizeAwarded;
              user.stats.totalWinningsCash = (user.stats.totalWinningsCash || 0) + p.prizeAwarded;
            } else {
              wallet.rewardCoins = (wallet.rewardCoins || 0) + Math.round(p.prizeAwarded);
              user.stats.totalRewardCoinsWon = (user.stats.totalRewardCoinsWon || 0) + Math.round(p.prizeAwarded);
            }
            user.wallets = wallet;

            // Record transaction (compatible with Flutter TransactionModel)
            const winTxn = {
              id: `txn_win_${Date.now()}_${(p.uid || '').substring(0, 5)}`,
              userId: p.uid,
              userName: user.displayName || p.inGameName || 'Player',
              type: isPaid ? 'matchWinningCash' : 'matchWinningRewardCoins',
              walletAffected: isPaid ? 'winningCash' : 'rewardCoins',
              amount: p.prizeAwarded,
              currency: isPaid ? 'INR' : 'REWARD_COINS',
              balanceBefore: balBefore,
              balanceAfter: isPaid ? wallet.winningCash : wallet.rewardCoins,
              status: 'SUCCESS',
              description: `🏆 Rank #${p.rank || 1} (+${isPaid ? '₹' + Math.round(p.prizeAwarded) + ' Real Cash' : Math.round(p.prizeAwarded) + ' 🎟️ Coins'}) in "${match.title}"`,
              createdAt: new Date().toISOString()
            };
            if (!db.transactions) db.transactions = [];
            db.transactions.unshift(winTxn);
          }
        }
      }
    });
  }

  db.stats.totalMatchesPlayed = (db.stats.totalMatchesPlayed || 0) + 1;
  db.stats.totalPrizesDistributed = (db.stats.totalPrizesDistributed || 0) + totalPrizeGiven;

  saveDB();
  broadcast('MATCH_COMPLETED', { matchId: id, match });

  autoRespawnCompletedMatch(match);
  res.json({ success: true, match });
});

// 8. Config & Category Banners
app.get('/api/config', (req, res) => {
  res.json({ success: true, config: db.config });
});

app.post('/api/config', (req, res) => {
  db.config = { ...db.config, ...req.body };
  saveDB();
  broadcast('CONFIG_UPDATED', db.config);
  res.json({ success: true, config: db.config });
});

// 9. Banners CRUD
app.get('/api/banners', (req, res) => {
  res.json({ success: true, banners: db.banners });
});

app.post('/api/banners', (req, res) => {
  const banner = {
    ...req.body,
    id: req.body.id || `banner_${Date.now()}`,
    createdAt: new Date().toISOString(),
    isActive: req.body.isActive !== undefined ? req.body.isActive : true
  };
  db.banners.unshift(banner);
  saveDB();
  broadcast('BANNER_ADDED', banner);
  res.json({ success: true, banner });
});

app.delete('/api/banners/:id', (req, res) => {
  const { id } = req.params;
  db.banners = db.banners.filter(b => b.id !== id);
  saveDB();
  broadcast('BANNER_DELETED', { id });
  res.json({ success: true, id });
});

// 9b. Weekly Leaderboard & Prize Distribution API
app.get('/api/leaderboard/distributions', (req, res) => {
  res.json({ success: true, distributions: db.weeklyDistributions || [] });
});

app.post('/api/leaderboard/distribute', (req, res) => {
  const record = req.body;
  if (!db.weeklyDistributions) db.weeklyDistributions = [];
  db.weeklyDistributions.unshift(record);
  saveDB();
  broadcast('WEEKLY_PRIZES_DISTRIBUTED', record);
  res.json({ success: true, record });
});

// 9c. Referral Attribution & Tracking API
app.get('/api/referrals', (req, res) => {
  res.json({ success: true, referrals: db.referrals || [] });
});

app.post('/api/referrals', (req, res) => {
  const referral = req.body;
  if (!db.referrals) db.referrals = [];
  db.referrals.unshift(referral);
  saveDB();
  broadcast('REFERRAL_REGISTERED', referral);
  res.json({ success: true, referral });
});

// Atomic Referral Application Endpoint
app.post('/api/referrals/apply', (req, res) => {
  const { referredUid, referralCode } = req.body;
  const code = (referralCode || '').trim().toUpperCase();

  const referredUser = db.users[referredUid];
  if (!referredUser) return res.status(404).json({ success: false, message: 'User not found on server' });
  if (referredUser.referredBy) return res.status(400).json({ success: false, message: 'You have already applied a referral code!' });
  if (referredUser.referralCode && referredUser.referralCode.toUpperCase() === code) {
    return res.status(400).json({ success: false, message: 'You cannot use your own referral code!' });
  }

  // Find referrer in db.users
  let referrerUser = Object.values(db.users).find(u => (u.referralCode || '').toUpperCase() === code && u.uid !== referredUid);
  if (!referrerUser) {
    return res.status(400).json({ success: false, message: 'Invalid Referral Code! Please enter a valid friend code.' });
  }

  const rewardBonusCash = 0;
  const rewardRefCoins = 5;

  // Credit referred user (5 Referral Coins, ₹0 Bonus Cash)
  const referredWallet = ensureUserWallet(referredUser);
  referredWallet.referralCoins = (referredWallet.referralCoins || 0) + rewardRefCoins;
  referredUser.wallet = referredWallet;
  referredUser.wallets = referredWallet;
  referredUser.referralCoins = referredWallet.referralCoins;
  referredUser.referral_coins = referredWallet.referralCoins;
  referredUser.referredBy = code;

  // Credit referrer (5 Referral Coins, ₹0 Bonus Cash)
  if (referrerUser) {
    const referrerWallet = ensureUserWallet(referrerUser);
    referrerWallet.referralCoins = (referrerWallet.referralCoins || 0) + rewardRefCoins;
    referrerUser.wallet = referrerWallet;
    referrerUser.wallets = referrerWallet;
    referrerUser.referralCoins = referrerWallet.referralCoins;
    referrerUser.referral_coins = referrerWallet.referralCoins;
    referrerUser.totalReferrals = (referrerUser.totalReferrals || 0) + 1;
    referrerUser.totalReferralCoins = (referrerUser.totalReferralCoins || 0) + rewardRefCoins;

    // Referrer notification
    db.notifications.unshift({
      id: `notif_ref_${Date.now()}`,
      title: '👥 New Friend Joined via your Referral!',
      body: `${referredUser.displayName || 'A friend'} used your code ${code}! 🎁 +5 Referral Coins credited to your wallet (50% usable in Free Matches).`,
      createdAt: new Date().toISOString(),
      type: 'matchResult',
      targetType: 'user',
      targetId: referrerUser.uid
    });
  }

  // Create Referral Record
  const refRecord = {
    id: `ref_${Date.now()}`,
    referrerUid: referrerUser ? referrerUser.uid : `referrer_${code}`,
    referrerName: referrerUser ? (referrerUser.displayName || referrerUser.inGameName || 'Friend') : `Inviter (${code})`,
    referrerCode: code,
    referredUid: referredUser.uid,
    referredName: referredUser.displayName || referredUser.inGameName || 'New Player',
    createdAt: new Date().toISOString(),
    bonusCashAwarded: rewardBonusCash,
    adCoinsAwarded: rewardRefCoins
  };

  if (!db.referrals) db.referrals = [];
  db.referrals.unshift(refRecord);

  saveDB();
  broadcast('REFERRAL_APPLIED', { refRecord, referrerUser, referredUser });
  broadcast('USER_UPDATED', referredUser);
  if (referrerUser) broadcast('USER_UPDATED', referrerUser);

  res.json({
    success: true,
    message: 'Referral code applied! 🎁 +5 Referral Coins credited to both wallets (50% usable in Free Matches).',
    refRecord,
    referredUser,
    referrerUser
  });
});

// 10. User Management
app.get('/api/users', (req, res) => {
  res.json({ success: true, users: Object.values(db.users || {}) });
});

app.get('/api/users/:uid', (req, res) => {
  const { uid } = req.params;
  const user = db.users[uid];
  if (!user) return res.status(404).json({ success: false, message: 'User not found' });
  res.json({ success: true, user });
});

app.post('/api/users', (req, res) => {
  const user = req.body;
  if (!user.uid) return res.status(400).json({ success: false, message: 'UID required' });

  const existing = db.users[user.uid] || Object.values(db.users).find(u => u.email && u.email.toLowerCase() === (user.email || '').toLowerCase());

  let preservedWallet = user.wallet;
  if (existing && existing.wallet) {
    const inW = user.wallet || {};
    const existingRefCoins = Number(existing.wallet.referralCoins || existing.wallets?.referralCoins || existing.referralCoins || 0);
    const incomingRefCoins = inW.referralCoins !== undefined ? Number(inW.referralCoins) : 0;
    preservedWallet = {
      adCoins: inW.adCoins !== undefined ? Number(inW.adCoins) : (existing.wallet.adCoins || 0),
      referralCoins: Math.max(existingRefCoins, incomingRefCoins),
      rewardCoins: inW.rewardCoins !== undefined ? Number(inW.rewardCoins) : (existing.wallet.rewardCoins || 0),
      depositCash: inW.depositCash !== undefined ? Number(inW.depositCash) : (existing.wallet.depositCash || 0),
      winningCash: inW.winningCash !== undefined ? Number(inW.winningCash) : (existing.wallet.winningCash || 0),
      bonusCash: inW.bonusCash !== undefined ? Number(inW.bonusCash) : (existing.wallet.bonusCash || 0),
    };
  }

  const defaultWallet = { adCoins: 5, referralCoins: 0, rewardCoins: 0, depositCash: 0, winningCash: 0, bonusCash: 0 };
  const finalWallet = preservedWallet || user.wallet || defaultWallet;
  const mergedUser = {
    ...existing,
    ...user,
    referredBy: existing?.referredBy || (user.referredBy ? user.referredBy.trim().toUpperCase() : null),
    wallet: finalWallet,
    wallets: finalWallet,
    referralCoins: finalWallet.referralCoins,
    referral_coins: finalWallet.referralCoins,
    lastSeen: new Date().toISOString()
  };

  db.users[user.uid] = mergedUser;

  // Automated Referral Attribution for signup with referral code
  try {
    const rawRefCode = (user.referredBy || '').trim().toUpperCase();
    if (rawRefCode && rawRefCode.length >= 4) {
      if (!db.referrals) db.referrals = [];
      const alreadyCredited = db.referrals.some(r => r.referredUid === user.uid);
      if (!alreadyCredited) {
        const referrerUser = Object.values(db.users).find(u => (u.referralCode || '').toUpperCase() === rawRefCode && u.uid !== user.uid);
        if (referrerUser) {
          const referrerWallet = ensureUserWallet(referrerUser);
          referrerWallet.referralCoins = (referrerWallet.referralCoins || 0) + 5;
          referrerUser.wallets = referrerWallet;
          referrerUser.totalReferrals = (referrerUser.totalReferrals || 0) + 1;
          referrerUser.totalReferralCoins = (referrerUser.totalReferralCoins || 0) + 5;

          if (!db.notifications) db.notifications = [];
          db.notifications.unshift({
            id: `notif_ref_${Date.now()}`,
            title: '👥 New Friend Joined via your Referral!',
            body: `${user.displayName || user.inGameName || 'A friend'} joined using your code ${rawRefCode}! 🎁 +5 Referral Coins credited to your wallet.`,
            createdAt: new Date().toISOString(),
            type: 'matchResult',
            targetType: 'user',
            targetId: referrerUser.uid
          });

          const refRecord = {
            id: `ref_${Date.now()}`,
            referrerUid: referrerUser.uid,
            referrerName: referrerUser.displayName || referrerUser.inGameName || 'Friend',
            referrerCode: rawRefCode,
            referredUid: user.uid,
            referredName: user.displayName || user.inGameName || 'New Player',
            createdAt: new Date().toISOString(),
            bonusCashAwarded: 0,
            adCoinsAwarded: 5
          };
          db.referrals.unshift(refRecord);
          broadcast('REFERRAL_APPLIED', { refRecord, referrerUser, referredUser: db.users[user.uid] });
        }
      }
    }
  } catch (err) {
    console.error('[REFERRAL_AUTO_SYNC_ERR]', err);
  }

  saveDB();
  res.json({ success: true, user: db.users[user.uid] });
});

app.delete('/api/users/:uid', (req, res) => {
  const { uid } = req.params;
  if (!uid) return res.status(400).json({ success: false, message: 'UID required' });
  if (db.users[uid]) {
    delete db.users[uid];
    saveDB();
    broadcast('USER_DELETED', { uid });
    return res.json({ success: true, message: 'User deleted successfully' });
  }
  res.status(404).json({ success: false, message: 'User not found' });
});

// 11. Payments & Webhooks
app.post('/api/payments/manual-deposit', (req, res) => {
  const { uid, amount, utrNumber, screenshotUrl } = req.body;
  const txn = {
    id: `txn_dep_${Date.now()}`,
    userId: uid,
    amount: parseFloat(amount),
    type: 'deposit',
    walletAffected: 'depositCash',
    title: 'Manual UPI Deposit Request',
    description: `UTR: ${utrNumber || 'N/A'}`,
    screenshotUrl,
    status: 'pending',
    createdAt: new Date().toISOString()
  };
  db.transactions.unshift(txn);
  saveDB();
  broadcast('DEPOSIT_REQUESTED', txn);
  res.json({ success: true, transaction: txn });
});

app.post('/api/payments/approve-deposit', (req, res) => {
  const { txnId } = req.body;
  const txn = db.transactions.find(t => t.id === txnId);
  if (!txn) return res.status(404).json({ success: false, message: 'Transaction not found' });

  txn.status = 'success';
  const user = db.users[txn.userId];
  if (user) {
    const wallet = ensureUserWallet(user);
    wallet.depositCash = (wallet.depositCash || 0) + txn.amount;
    user.wallets = wallet;
  }
  saveDB();
  broadcast('TRANSACTION_UPDATED', txn);
  res.json({ success: true, transaction: txn, user });
});

// Razorpay Webhook
app.post('/api/payments/webhook', (req, res) => {
  const event = req.body;
  console.log('[Webhook] Received payment event:', event?.event);

  if (event?.event === 'payment.captured' || event?.event === 'order.paid') {
    const payment = event.payload?.payment?.entity;
    const amount = (payment?.amount || 0) / 100;
    const notes = payment?.notes || {};
    const uid = notes.uid || notes.userId || notes.user_id;

    if (uid && db.users[uid]) {
      const user = db.users[uid];
      if (!user.wallet) user.wallet = { adCoins: 0, rewardCoins: 0, depositCash: 0, winningCash: 0, bonusCash: 0 };
      if (!user.wallets) user.wallets = user.wallet;

      const bonusAmt = (amount * 0.10);
      user.wallet.depositCash = (user.wallet.depositCash || 0) + amount;
      user.wallet.bonusCash = (user.wallet.bonusCash || 0) + bonusAmt;
      user.wallets.depositCash = user.wallet.depositCash;
      user.wallets.bonusCash = user.wallet.bonusCash;

      const txn = {
        id: `txn_rzp_${payment.id || Date.now()}`,
        userId: uid,
        userName: user.displayName || user.inGameName,
        amount,
        type: 'deposit',
        walletAffected: 'depositCash',
        title: 'Razorpay Instant UPI Deposit',
        description: `Payment ID: ${payment.id} (+₹${bonusAmt.toFixed(0)} Extra Bonus Cash)`,
        status: 'success',
        createdAt: new Date().toISOString()
      };
      if (!db.transactions) db.transactions = [];
      db.transactions.unshift(txn);

      if (!db.notifications) db.notifications = [];
      db.notifications.unshift({
        id: `notif_dep_${Date.now()}`,
        title: '💵 Deposit Successful!',
        body: `₹${amount} added to your Deposit Cash wallet (+₹${bonusAmt.toFixed(0)} Extra Bonus Cash)!`,
        createdAt: new Date().toISOString(),
        type: 'deposit',
        targetType: 'user',
        targetId: uid
      });

      saveDB();
      broadcast('TRANSACTION_UPDATED', txn);
      broadcast('USER_UPDATED', user);
      console.log(`[Webhook] Credited ₹${amount} (+₹${bonusAmt.toFixed(0)} bonus) to user ${uid}`);
    }
  }
  res.json({ status: 'ok' });
});

// Transactions direct endpoints
app.get('/api/transactions', (req, res) => {
  res.json({ success: true, transactions: db.transactions || [] });
});

app.post('/api/transactions', (req, res) => {
  const txn = req.body;
  if (!txn || !txn.id) return res.status(400).json({ success: false, message: 'Invalid transaction' });
  if (!db.transactions) db.transactions = [];
  const idx = db.transactions.findIndex(t => t.id === txn.id);
  if (idx !== -1) {
    db.transactions[idx] = { ...db.transactions[idx], ...txn };
  } else {
    db.transactions.unshift(txn);
  }
  saveDB();
  broadcast('TRANSACTION_UPDATED', txn);
  res.json({ success: true, transaction: txn });
});

// Voucher Claims direct endpoints
app.get('/api/voucher-claims', (req, res) => {
  res.json({ success: true, claims: db.voucherClaims || [] });
});

app.post('/api/voucher-claims', (req, res) => {
  const claim = req.body;
  if (!claim || !claim.id) return res.status(400).json({ success: false, message: 'Invalid claim' });
  if (!db.voucherClaims) db.voucherClaims = [];
  const idx = db.voucherClaims.findIndex(c => c.id === claim.id);
  if (idx !== -1) {
    db.voucherClaims[idx] = { ...db.voucherClaims[idx], ...claim };
  } else {
    db.voucherClaims.unshift(claim);
  }
  saveDB();
  broadcast('VOUCHER_CLAIMED', claim);
  res.json({ success: true, claim });
});

// Store Items management endpoints (Admin Add & Delete)
app.get('/api/store-items', (req, res) => {
  res.json({ success: true, storeItems: db.storeItems || [] });
});

app.post('/api/store-items', (req, res) => {
  const item = req.body;
  if (!item || !item.id || !item.title) {
    return res.status(400).json({ success: false, message: 'Invalid store item' });
  }
  if (!db.storeItems) db.storeItems = [];
  const idx = db.storeItems.findIndex(s => s.id === item.id);
  if (idx !== -1) {
    db.storeItems[idx] = { ...db.storeItems[idx], ...item };
  } else {
    db.storeItems.push(item);
  }
  saveDB();
  broadcast('STORE_UPDATED', db.storeItems);
  res.json({ success: true, storeItem: item, storeItems: db.storeItems });
});

app.delete('/api/store-items/:id', (req, res) => {
  const { id } = req.params;
  if (!db.storeItems) db.storeItems = [];
  const beforeLen = db.storeItems.length;
  db.storeItems = db.storeItems.filter(s => s.id !== id);
  if (db.storeItems.length === beforeLen) {
    return res.status(404).json({ success: false, message: 'Store item not found' });
  }
  saveDB();
  broadcast('STORE_UPDATED', db.storeItems);
  res.json({ success: true, deletedId: id, storeItems: db.storeItems });
});

// 12. Withdrawals
app.get('/api/withdrawals', (req, res) => {
  res.json({ success: true, withdrawals: db.withdrawals });
});

app.post('/api/withdrawals', (req, res) => {
  const withdrawal = {
    ...req.body,
    id: req.body.id || `with_${Date.now()}`,
    requestedAt: new Date().toISOString(),
    status: 'pending'
  };
  db.withdrawals.unshift(withdrawal);

  // Deduct user winning cash
  const user = db.users[withdrawal.userId];
  if (user) {
    const wallet = ensureUserWallet(user);
    wallet.winningCash = Math.max(0, (wallet.winningCash || 0) - withdrawal.amount);
    user.wallets = wallet;
  }

  saveDB();
  broadcast('WITHDRAWAL_REQUESTED', withdrawal);
  res.json({ success: true, withdrawal, user });
});

app.put('/api/withdrawals/:id', (req, res) => {
  const { id } = req.params;
  const index = db.withdrawals.findIndex(w => w.id === id);
  if (index === -1) return res.status(404).json({ success: false, message: 'Withdrawal not found' });

  const prevStatus = db.withdrawals[index].status;
  db.withdrawals[index] = { ...db.withdrawals[index], ...req.body };

  // If rejected, refund winning balance
  if (prevStatus === 'pending' && db.withdrawals[index].status === 'rejected') {
    const user = db.users[db.withdrawals[index].userId];
    if (user) {
      const wallet = ensureUserWallet(user);
      wallet.winningCash = (wallet.winningCash || 0) + db.withdrawals[index].amount;
      user.wallets = wallet;
    }
  }

  saveDB();
  broadcast('WITHDRAWAL_UPDATED', db.withdrawals[index]);
  res.json({ success: true, withdrawal: db.withdrawals[index] });
});

// 13. Notifications
app.get('/api/notifications', (req, res) => {
  res.json({ success: true, notifications: db.notifications });
});

app.post('/api/notifications', (req, res) => {
  const notif = {
    ...req.body,
    id: req.body.id || `notif_${Date.now()}`,
    createdAt: new Date().toISOString()
  };
  db.notifications.unshift(notif);
  saveDB();
  broadcast('NOTIFICATION_RECEIVED', notif);
  res.json({ success: true, notification: notif });
});

// Dynamic Personalized Notification Broadcast with User's Name & Match Details
app.post('/api/notifications/broadcast-personalized-match', (req, res) => {
  const { matchId, customTitleTemplate, customBodyTemplate, notificationType } = req.body;
  const match = (db.matches || []).find(m => m.id === matchId);
  if (!match) return res.status(404).json({ success: false, message: 'Match not found' });

  const usersList = Object.values(db.users || {});
  const now = new Date().toISOString();
  let count = 0;

  usersList.forEach(u => {
    const userName = u.displayName || u.inGameName || 'Player';
    const isRoomIdRelease = notificationType === 'room_release' || (match.credentials && match.credentials.roomId);

    let defaultTitle = `🔥 ${userName}, अभी '${match.title}' जॉइन करें!`;
    let defaultBody = `${userName}, जीतें 🪙 ${match.prizePool ? (match.prizePool.totalPool || 400) : 400} Coins! एंट्री सिर्फ 🟡 ${match.entryFee} Ad Coins। मोड: ${(match.mode || 'BR').toUpperCase()} Solo। अभी स्लॉट बुक करें!`;

    if (isRoomIdRelease && notificationType === 'room_release') {
      defaultTitle = `🔑 ${userName}, '${match.title}' की रूम ID और पासवर्ड आ गया!`;
      defaultBody = `Room ID: ${match.credentials.roomId} | Pass: ${match.credentials.roomPassword}\nजल्दी से Free Fire में रूम जॉइन करें, मैच 10 मिनट में शुरू हो रहा है!`;
    }

    const title = customTitleTemplate 
      ? customTitleTemplate.replace(/\{name\}/g, userName).replace(/\{match_title\}/g, match.title)
      : defaultTitle;
    
    const body = customBodyTemplate
      ? customBodyTemplate
          .replace(/\{name\}/g, userName)
          .replace(/\{match_title\}/g, match.title)
          .replace(/\{entry\}/g, match.entryFee)
          .replace(/\{prize\}/g, match.prizePool ? (match.prizePool.totalPool || 400) : '400')
          .replace(/\{mode\}/g, (match.mode || 'BR').toUpperCase())
          .replace(/\{room_id\}/g, match.credentials?.roomId || '')
          .replace(/\{room_pass\}/g, match.credentials?.roomPassword || '')
      : defaultBody;

    const userNotif = {
      id: `notif_${u.uid}_${Date.now()}_${count}`,
      title: title,
      body: body,
      imageUrl: match.bannerUrl,
      targetType: 'user',
      targetId: u.uid,
      matchId: match.id,
      type: isRoomIdRelease ? 'matchCredentials' : 'matchAlert',
      createdAt: now
    };

    if (!db.notifications) db.notifications = [];
    db.notifications.unshift(userNotif);
    count++;
  });

  if (db.notifications.length > 500) {
    db.notifications = db.notifications.slice(0, 500);
  }

  saveDB();
  broadcast('NOTIFICATION_RECEIVED', { type: 'PERSONALIZED_MATCH_BROADCAST', matchId, count });
  res.json({ success: true, count, message: `Dispatched personalized notification to ${count} users with their individual names!` });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString(), version: '2.2.4-VPS' });
});

// Start Server
loadDB();
server.listen(PORT, '0.0.0.0', () => {
  console.log(`=============================================`);
  console.log(`🔥 Booyah Rewards VPS Backend Running on Port ${PORT}`);
  console.log(`🌐 Public API: http://35.154.113.3:${PORT}/api/sync`);
  console.log(`⚡ WebSocket: ws://35.154.113.3:${PORT}`);
  console.log(`=============================================`);
});
