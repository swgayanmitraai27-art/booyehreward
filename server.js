const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');
const multer = require('multer');

const app = express();
const PORT = process.env.PORT || 3000;

const DATA_DIR = path.join(__dirname, 'data');
const DB_FILE = path.join(DATA_DIR, 'db.json');
const UPLOAD_DIR = path.join(__dirname, 'uploads');
const ADMIN_DIR = path.join(__dirname, 'public');

if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });
if (!fs.existsSync(ADMIN_DIR)) fs.mkdirSync(ADMIN_DIR, { recursive: true });

app.use(cors());
app.use(bodyParser.json({ limit: '15mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '15mb' }));
app.use('/uploads', express.static(UPLOAD_DIR));
app.use('/admin', express.static(ADMIN_DIR));
app.use('/app', express.static(path.join(ADMIN_DIR, 'app')));

// --- MULTER STORAGE ---
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOAD_DIR),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.png';
    cb(null, `banner_${Date.now()}_${Math.random().toString(36).substring(7)}${ext}`);
  }
});
const upload = multer({ storage, limits: { fileSize: 15 * 1024 * 1024 } });

// --- INITIAL DATABASE STATE ---
let db = {
  users: {},
  ff_tournaments: [],
  ff_groups: [],
  ff_teams: [],
  ff_chat: [],
  ff_support_tickets: [],
  redeemRequests: [],
  config: {
    season: 1,
    coinEconomy: {
      adCoinReward: 10,
      dailyAdLimit: 15,
      welcomeBonus: 20,
      referralReward: 50,
      redeemRate: 10
    },
    socialLinks: {
      youtube: 'https://youtube.com/@booyahrewards',
      instagram: 'https://instagram.com/booyahrewards',
      telegram: 'https://t.me/booyahrewards'
    },
    branding: {
      gameName: 'FREE FIRE INDIA',
      tagline: 'India Ka Apna Battle Royale',
      subTagline: 'India Ka Apna Esports Platform'
    },
    appSettings: {
      popupBanner: {
        enabled: false,
        imageUrl: '',
        title: '🔥 Free Fire India Esports Tournaments!',
        actionUrl: '',
        dismissible: true
      },
      howToPlayVideo: {
        enabled: true,
        youtubeUrl: 'https://youtube.com/watch?v=dQw4w9WgXcQ',
        title: 'How to Play & Win Free Fire Tournaments',
        description: 'Complete guide on slot registration, team codes, and room ID credentials!'
      },
      miniGameConfig: {
        dailyLimit: 50,
        scorePerCoin: 50,
        maxCoinsPerGame: 3,
        enabled: true
      }
    }
  }
};

function loadDB() {
  if (fs.existsSync(DB_FILE)) {
    try {
      const parsed = JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
      db = { ...db, ...parsed };
      if (!db.users) db.users = {};
      if (!db.ff_tournaments) db.ff_tournaments = [];
      if (!db.ff_groups) db.ff_groups = [];
      if (!db.ff_teams) db.ff_teams = [];
      if (!db.ff_chat) db.ff_chat = [];
      if (!db.ff_support_tickets) db.ff_support_tickets = [];
      if (!db.redeemRequests) db.redeemRequests = [];
      if (!db.config) db.config = {};
      if (!db.config.coinEconomy) {
        db.config.coinEconomy = {
          adCoinReward: 10,
          dailyAdLimit: 15,
          welcomeBonus: 20,
          referralReward: 50,
          redeemRate: 10
        };
      }
      if (!db.config.branding) {
        db.config.branding = {
          gameName: 'FREE FIRE INDIA',
          tagline: 'India Ka Apna Battle Royale',
          subTagline: 'India Ka Apna Esports Platform'
        };
      }
      const realCount = Object.keys(db.users).filter(id => !id.startsWith('bot_')).length;
      console.log(`[DB] Free Fire India Database Loaded. Real Players: ${realCount}`);
    } catch (e) {
      console.error('[DB] Load error, keeping current memory state:', e);
    }
  } else {
    saveDB();
  }
}

function saveDB() {
  try {
    fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2), 'utf8');
  } catch (e) {
    console.error('[DB] Save error:', e);
  }
}

// ── 1. USER WALLET & PROFILE SYNC (ATOMIC & PERSISTENT) ──
app.post('/api/tournament/sync-user', (req, res) => {
  const { deviceId, displayName, coinsToAdd, referralCode, inGameName, inGameId } = req.body;
  if (!deviceId) return res.status(400).json({ error: 'Device ID required' });

  if (!db.users[deviceId]) {
    const rCode = (100000 + (Date.now() % 900000)).toString();
    db.users[deviceId] = {
      uid: deviceId,
      displayName: displayName || `Player_${deviceId.slice(-4)}`,
      inGameName: inGameName || displayName || `Player_${deviceId.slice(-4)}`,
      inGameId: inGameId || '',
      adCoins: (db.config.coinEconomy && db.config.coinEconomy.welcomeBonus) || 20,
      winningCoins: 0,
      totalWins: 0,
      totalKills: 0,
      totalAdsWatched: 0,
      hasPlayedFirstMatch: false,
      referralCode: rCode,
      referredBy: referralCode || '',
      createdAt: new Date().toISOString(),
      lastActive: new Date().toISOString()
    };
  } else {
    const u = db.users[deviceId];
    u.winningCoins = u.winningCoins || 0;
    if (displayName) u.displayName = displayName;
    if (inGameName) u.inGameName = inGameName;
    if (inGameId) u.inGameId = inGameId;
    if (referralCode && !u.referredBy && referralCode !== u.referralCode) {
      u.referredBy = referralCode;
    }
    if (coinsToAdd && Number(coinsToAdd) > 0) {
      u.adCoins = (u.adCoins || 0) + Number(coinsToAdd);
    }
    u.lastActive = new Date().toISOString();
  }

  saveDB();
  res.json({
    success: true,
    user: db.users[deviceId],
    coinEconomy: db.config.coinEconomy,
    branding: db.config.branding
  });
});

// ── 2. REDEEM STORE & WITHDRAWAL ENGINE ──
const DEFAULT_PACKAGES = [
  { id: 'play_10', amount: 10, points: 100, title: '₹10 Google Play Code', badge: 'FAST' },
  { id: 'play_50', amount: 50, points: 500, title: '₹50 Google Play Code', badge: 'POPULAR' },
  { id: 'play_100', amount: 100, points: 1000, title: '₹100 Google Play Code', badge: 'VIP' },
  { id: 'upi_50', amount: 50, points: 500, title: '₹50 Direct UPI Cash', badge: 'DIRECT CASH' },
  { id: 'upi_100', amount: 100, points: 1000, title: '₹100 Direct UPI Cash', badge: 'INSTANT UPI' }
];

app.get('/api/redeem/packages', (req, res) => {
  res.json({ success: true, packages: DEFAULT_PACKAGES });
});

app.post('/api/redeem/submit', (req, res) => {
  const { deviceId, packageId, userEmail, userPhone, upiId } = req.body;
  if (!deviceId || !packageId) {
    return res.status(400).json({ success: false, error: 'Device ID and Package required' });
  }

  const pkg = DEFAULT_PACKAGES.find(p => p.id === packageId) || DEFAULT_PACKAGES[0];
  const u = db.users[deviceId];
  if (!u) return res.status(404).json({ success: false, error: 'User not found' });

  if ((u.winningCoins || 0) < pkg.points) {
    return res.status(400).json({
      success: false,
      error: `Only Winning Coins can be redeemed for Play Codes / UPI Cash! You need ${pkg.points} Winning Coins. Your Winning Coins: ${u.winningCoins || 0}. (Win Free Fire tournaments to earn redeemable coins!)`
    });
  }

  // Deduct winning coins atomically
  u.winningCoins -= pkg.points;

  const reqItem = {
    id: `REQ-${Date.now().toString().slice(-6)}`,
    uid: deviceId,
    displayName: u.inGameName || u.displayName || 'Gamer',
    amount: pkg.amount,
    pointsCost: pkg.points,
    email: userEmail || '',
    phone: userPhone || '',
    upiId: upiId || '',
    packageTitle: pkg.title,
    status: 'PENDING', // PENDING | DELIVERED | REJECTED
    redeemCode: '',
    adminNotes: '',
    createdAt: new Date().toISOString(),
    deliveredAt: null
  };

  if (!db.redeemRequests) db.redeemRequests = [];
  db.redeemRequests.unshift(reqItem);
  saveDB();

  console.log(`[REDEEM SUBMITTED] User ${deviceId} requested ${pkg.title}. Remaining Coins: ${u.adCoins}`);
  res.json({
    success: true,
    message: `Request for ${pkg.title} submitted! Code / UPI payout delivered within 24 hours.`,
    remainingCoins: u.adCoins,
    request: reqItem
  });
});

app.get('/api/redeem/my-requests/:deviceId', (req, res) => {
  const { deviceId } = req.params;
  const list = (db.redeemRequests || []).filter(r => r.uid === deviceId);
  res.json({ success: true, requests: list });
});

app.get('/api/redeem/live-feed', (req, res) => {
  const list = (db.redeemRequests || []).filter(r => r.status === 'DELIVERED').slice(0, 10);
  res.json({ success: true, feed: list });
});

// ── 3. ADMIN CUSTOM BANNER UPLOAD ──
app.post('/api/admin/upload-banner', upload.single('banner'), (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, error: 'No banner image file uploaded' });
  const host = req.get('host') || 'vps.swgayanbhumi.in';
  const protocol = req.protocol === 'https' || req.headers['x-forwarded-proto'] === 'https' ? 'https' : 'http';
  const bannerUrl = `${protocol}://${host}/uploads/${req.file.filename}`;
  console.log(`[ADMIN BANNER UPLOAD] Saved ${req.file.filename} -> ${bannerUrl}`);
  res.json({ success: true, bannerUrl, filename: req.file.filename });
});

// ── 4. ESPORTS LEADERBOARD ──
app.get('/api/leaderboard', (req, res) => {
  const usersList = Object.values(db.users || {});
  usersList.sort((a, b) => {
    if ((b.totalWins || 0) !== (a.totalWins || 0)) {
      return (b.totalWins || 0) - (a.totalWins || 0);
    }
    if ((b.winningCoins || 0) !== (a.winningCoins || 0)) {
      return (b.winningCoins || 0) - (a.winningCoins || 0);
    }
    return (b.totalKills || 0) - (a.totalKills || 0);
  });

  const leaderboard = usersList.slice(0, 100).map((u, idx) => ({
    rank: idx + 1,
    uid: u.uid,
    name: u.inGameName || u.displayName || `Gamer_${idx + 1}`,
    inGameId: u.inGameId || '',
    totalWins: u.totalWins || 0,
    totalKills: u.totalKills || 0,
    winningCoins: u.winningCoins || 0,
    weeklyScore: (u.totalWins || 0) * 100 + (u.totalKills || 0) * 10,
    avatar: 'assets/imgasest/booyah_hero_logo.png'
  }));

  res.json({ success: true, leaderboard });
});

// ── 3. HOOK FREE FIRE INDIA TOURNAMENTS ENGINE ──
try {
  const setupFFTournamentEngine = require('./ff_tournament_engine');
  setupFFTournamentEngine(app, db, saveDB, upload);
} catch (err) {
  console.error('[FF ENGINE HOOK ERROR]:', err);
}

// ── APP CONFIG & MANAGEMENT (POPUP BANNER & VIDEO TUTORIAL) ──
app.get('/api/app-config', (req, res) => {
  res.json({
    success: true,
    appSettings: db.config.appSettings,
    coinEconomy: db.config.coinEconomy,
    socialLinks: db.config.socialLinks,
    branding: db.config.branding
  });
});

app.post('/api/admin/config/app-settings', (req, res) => {
  const { popupBanner, howToPlayVideo, miniGameConfig } = req.body;
  if (!db.config.appSettings) db.config.appSettings = {};
  if (popupBanner) db.config.appSettings.popupBanner = popupBanner;
  if (howToPlayVideo) db.config.appSettings.howToPlayVideo = howToPlayVideo;
  if (miniGameConfig) db.config.appSettings.miniGameConfig = miniGameConfig;
  saveDB();
  console.log('[ADMIN APP SETTINGS] Updated popup banner, video tutorial, and minigame config');
  res.json({ success: true, message: 'App management settings updated successfully!', appSettings: db.config.appSettings });
});

// ── MINI-GAME ARCADE ZONE APIS ──
// Anti-Cheat & 60-Second Full Screen Ad Cooldown Policy:
// User earns unlimited times per day (No Daily Limit).
// Hard Cap: Max 3 Coins per single game session, no matter how pro the player is!
// 50 Score = 1 Coin, 100 Score = 2 Coins, 150+ Score = Max 3 Coins.
app.post('/api/minigame/claim-reward', (req, res) => {
  const { deviceId, gameId, score, doubleReward } = req.body;
  if (!deviceId || !db.users[deviceId]) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }

  const u = db.users[deviceId];
  const mgConfig = (db.config.appSettings && db.config.appSettings.miniGameConfig) || {
    cooldownSeconds: 60,
    scorePerCoin: 50,
    maxCoinsPerGame: 3,
    enabled: true
  };

  if (mgConfig.enabled === false) {
    return res.json({ success: false, message: 'मिनी-गेम्स अभी एडमिन द्वारा बंद हैं।', coinsEarned: 0 });
  }

  const now = Date.now();
  const lastClaim = u.lastMiniGameClaimTime || 0;
  const cooldownDuration = (mgConfig.cooldownSeconds || 60) * 1000; // 60,000 ms

  // 🛡️ ANTI-CHEAT CHECK 1: 60-Second Cooldown between Full-Screen Ad / Coin Claims
  if (now - lastClaim < cooldownDuration) {
    const remainingSeconds = Math.ceil((cooldownDuration - (now - lastClaim)) / 1000);
    return res.json({
      success: false,
      cooldownActive: true,
      remainingSeconds,
      message: `⏳ एंटी-चीट कूलडाउन: कृपया ${remainingSeconds} सेकंड प्रतीक्षा करें!`,
      coinsEarned: 0
    });
  }

  // Calculate coins from score: 50 Score = 1 Coin
  const scoreNum = Math.max(0, parseInt(score, 10) || 0);
  const scorePerCoin = mgConfig.scorePerCoin || 50;
  let earned = Math.floor(scoreNum / scorePerCoin);

  // 🛡️ HARD CAP: Maximum 3 Coins per Game Session (Kitna bhi Pro player ho, max 3 coins!)
  const maxCap = mgConfig.maxCoinsPerGame || 3;
  if (earned > maxCap) {
    earned = maxCap;
  }

  // Rewarded Video 2X Multiplier (if user watched video ad)
  if (doubleReward === true && earned > 0) {
    earned = earned * 2;
  }

  // Update User & Timestamp
  u.lastMiniGameClaimTime = now;
  if (earned > 0) {
    u.adCoins = (u.adCoins || 0) + earned;
    u.totalMiniGameSessions = (u.totalMiniGameSessions || 0) + 1;
    u.miniGameCoinsToday = (u.miniGameCoinsToday || 0) + earned;
    saveDB();
  }

  return res.json({
    success: true,
    coinsEarned: earned,
    totalCoins: u.adCoins,
    winningCoins: u.winningCoins || 0,
    miniGameCoinsToday: u.miniGameCoinsToday,
    cooldownSeconds: mgConfig.cooldownSeconds || 60,
    message: earned > 0 ? `You Earned ${earned} Coins!` : 'और बेहतर स्कोर बनाएं (कम से कम 50 अंक)!'
  });
});

app.get('/api/minigame/status/:deviceId', (req, res) => {
  const { deviceId } = req.params;
  const u = db.users[deviceId];
  const mgConfig = (db.config.appSettings && db.config.appSettings.miniGameConfig) || {
    cooldownSeconds: 60,
    scorePerCoin: 50,
    maxCoinsPerGame: 3,
    enabled: true
  };

  const now = Date.now();
  const lastClaim = (u && u.lastMiniGameClaimTime) || 0;
  const cooldownDuration = (mgConfig.cooldownSeconds || 60) * 1000;
  const elapsed = now - lastClaim;
  const remainingSeconds = elapsed < cooldownDuration ? Math.ceil((cooldownDuration - elapsed) / 1000) : 0;

  res.json({
    success: true,
    cooldownSeconds: mgConfig.cooldownSeconds || 60,
    remainingSeconds,
    canClaimNow: remainingSeconds === 0,
    scorePerCoin: mgConfig.scorePerCoin || 50,
    maxCoinsPerGame: mgConfig.maxCoinsPerGame || 3,
    totalSessions: (u && u.totalMiniGameSessions) || 0,
    miniGameCoinsToday: (u && u.miniGameCoinsToday) || 0,
    enabled: mgConfig.enabled !== false
  });
});

// ── 4. ADMIN PANEL SECURITY & STATS ──
app.use('/api/admin', (req, res, next) => {
  const ua = (req.headers['user-agent'] || '').toLowerCase();
  const referer = req.headers['referer'] || '';
  const adminSource = req.headers['x-admin-source'] || '';

  if (ua.includes('dart')) {
    return res.status(403).json({ success: false, error: 'Unauthorized.' });
  }
  if (req.method === 'GET' && req.path === '/stats') {
    return next();
  }
  if (adminSource !== 'vps-web-dashboard' && !referer.includes('/admin')) {
    return res.status(403).json({ success: false, error: 'Unauthorized.' });
  }
  next();
});

function getISTDateStr(dateInput) {
  if (!dateInput) return null;
  const d = new Date(dateInput);
  if (isNaN(d.getTime())) return null;
  const istDate = new Date(d.getTime() + 19800000);
  return istDate.toISOString().slice(0, 10);
}

app.get('/api/admin/stats', (req, res) => {
  const allUsers = Object.values(db.users || {});
  const now = new Date();
  const nowMs = now.getTime();
  const todayStr = getISTDateStr(now);
  const yesterdayStr = getISTDateStr(new Date(nowMs - 86400000));

  let liveActive = 0;
  let dauToday = 0;
  let dauYesterday = 0;
  let mau = 0;

  allUsers.forEach(u => {
    if (u && u.lastActive) {
      const diffMs = nowMs - new Date(u.lastActive).getTime();
      const diffMins = diffMs / 60000;
      const diffDays = diffMs / 86400000;

      if (diffMins <= 15) liveActive++;
      if (diffDays <= 30) mau++;

      const uDate = getISTDateStr(u.lastActive);
      if (uDate === todayStr) dauToday++;
      else if (uDate === yesterdayStr) dauYesterday++;
    }
  });

  const tourns = db.ff_tournaments || [];
  const totalMatches = tourns.length;
  const liveMatches = tourns.filter(t => t.status === 'LIVE').length;
  const openMatches = tourns.filter(t => t.status === 'OPEN').length;
  const totalSlotsJoined = tourns.reduce((sum, t) => sum + (Number(t.filledSlots) || 0), 0);
  const totalPrizeCoinsPool = tourns.reduce((sum, t) => sum + ((t.prizePool && Number(t.prizePool.totalCoins)) || 0), 0);

  let newPlayersToday = 0;
  allUsers.forEach(u => {
    if (u && u.createdAt && getISTDateStr(u.createdAt) === todayStr) {
      newPlayersToday++;
    }
  });

  const redeemList = db.redeemRequests || [];
  const pendingCount = redeemList.filter(r => r.status === 'PENDING').length;
  const deliveredCount = redeemList.filter(r => r.status === 'DELIVERED').length;
  const totalDeliveredVal = redeemList
    .filter(r => r.status === 'DELIVERED')
    .reduce((sum, r) => sum + (Number(r.amount) || 0), 0);

  res.json({
    success: true,
    realUsersCount: allUsers.length,
    newPlayersToday: newPlayersToday,
    liveActiveCount: liveActive,
    dauTodayCount: dauToday,
    dauYesterdayCount: dauYesterday,
    mauCount: mau,
    totalMatches: totalMatches,
    liveMatches: liveMatches,
    openMatches: openMatches,
    totalSlotsJoined: totalSlotsJoined,
    totalPrizeCoinsPool: totalPrizeCoinsPool,
    pendingRedeemCount: pendingCount,
    deliveredRedeemCount: deliveredCount,
    totalDeliveredVal: `₹${totalDeliveredVal}`,
    tournamentsCount: totalMatches,
    supportTicketsCount: (db.ff_support_tickets || []).filter(t => t.status === 'OPEN').length,
    usersList: allUsers.slice(-100).reverse()
  });
});

// Admin: Get and fulfill redeem requests
app.get('/api/admin/redeem-requests', (req, res) => {
  res.json({
    success: true,
    requests: db.redeemRequests || []
  });
});

app.post('/api/admin/redeem-action', (req, res) => {
  const { requestId, action, code, reason } = req.body;
  if (!requestId || !action) return res.status(400).json({ error: 'Request ID and action required' });

  const reqItem = (db.redeemRequests || []).find(r => r.id === requestId);
  if (!reqItem) return res.status(404).json({ error: 'Request not found' });

  if (action === 'APPROVE') {
    reqItem.status = 'DELIVERED';
    reqItem.redeemCode = code || 'PAID_VIA_UPI';
    reqItem.deliveredAt = new Date().toISOString();
    reqItem.adminNotes = 'Redeem code delivered successfully!';
  } else if (action === 'REFUND') {
    reqItem.status = 'REJECTED';
    reqItem.adminNotes = reason || 'Rejected by Admin';
    if (db.users[reqItem.uid]) {
      db.users[reqItem.uid].adCoins = (db.users[reqItem.uid].adCoins || 0) + reqItem.pointsCost;
    }
  }

  saveDB();
  res.json({ success: true, message: `Request updated to ${reqItem.status}!`, request: reqItem });
});

// ── 5. START SERVER ──
loadDB();
app.listen(PORT, '0.0.0.0', () => {
  console.log(`===============================================`);
  console.log(`🔥 Free Fire India Esports Backend Running on Port ${PORT}`);
  console.log(`🌐 Master Admin Panel: https://vps.swgayanbhumi.in/admin`);
  console.log(`===============================================`);
});
