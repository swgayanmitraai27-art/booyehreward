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
    isRealCashModeEnabled: true,
    brBannerUrl: 'https://i.ibb.co/PvV4vz0X/brhomescreen.png',
    csBannerUrl: 'https://i.ibb.co/S4qX9RW5/cshomescreen.png',
    lwBannerUrl: 'https://i.ibb.co/9ktcjYSX/lonewolfhomescreen.png',
    appVersion: '2.2.4',
    minWithdrawalAmount: 30,
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
  stats: {
    totalAdsWatched: 0,
    totalMatchesPlayed: 0,
    totalPrizesDistributed: 0
  }
};

// --- PERSISTENCE HELPERS ---
function loadDB() {
  try {
    if (fs.existsSync(DB_FILE)) {
      const data = fs.readFileSync(DB_FILE, 'utf8');
      const parsed = JSON.parse(data);
      db = { ...db, ...parsed };
      console.log(`[DB] Loaded successfully. Matches: ${db.matches.length}, Users: ${Object.keys(db.users).length}`);
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
  const { uid } = req.query;
  const user = uid && db.users[uid] ? db.users[uid] : null;
  const activeBanners = db.banners.filter(b => b.isActive);

  res.json({
    success: true,
    matches: db.matches,
    banners: activeBanners,
    modes: db.tournamentModes || [],
    config: db.config,
    notifications: db.notifications.slice(0, 30),
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
  saveDB();
  broadcast('MATCH_CREATED', match);
  res.json({ success: true, match });
});

app.put('/api/matches/:id', (req, res) => {
  const { id } = req.params;
  const index = db.matches.findIndex(m => m.id === id);
  if (index === -1) return res.status(404).json({ success: false, message: 'Match not found' });

  const prevStatus = db.matches[index].status;
  db.matches[index] = { ...db.matches[index], ...req.body };
  saveDB();
  broadcast('MATCH_UPDATED', db.matches[index]);

  if (prevStatus !== 'completed' && db.matches[index].status === 'completed') {
    autoRespawnCompletedMatch(db.matches[index]);
  }

  res.json({ success: true, match: db.matches[index] });
});

app.delete('/api/matches/:id', (req, res) => {
  const { id } = req.params;
  db.matches = db.matches.filter(m => m.id !== id);
  saveDB();
  broadcast('MATCH_DELETED', { id });
  res.json({ success: true, id });
});

// 5. Join Match Slot
app.post('/api/matches/:id/join', (req, res) => {
  const { id } = req.params;
  const { uid, inGameName, inGameUid, slotNumber, paidWith, amountPaid, teamName } = req.body;

  const match = db.matches.find(m => m.id === id);
  if (!match) return res.status(404).json({ success: false, message: 'Match not found' });

  if (match.participants.some(p => p.slotNumber === slotNumber)) {
    return res.status(400).json({ success: false, message: `Slot #${slotNumber} already taken!` });
  }

  if (match.participants.some(p => p.uid === uid)) {
    return res.status(400).json({ success: false, message: 'You have already joined this match!' });
  }

  const participant = {
    uid,
    inGameName,
    inGameUid,
    slotNumber,
    paidWith: paidWith || 'DEPOSIT_CASH',
    amountPaid: amountPaid || match.entryFee,
    joinedAt: new Date().toISOString(),
    kills: 0,
    teamName
  };

  match.participants.push(participant);
  match.filledSlots = match.participants.length;
  if (match.filledSlots >= match.maxSlots && match.status === 'upcoming') {
    match.status = 'roomFilling';
  }

  const user = db.users[uid];
  if (user) {
    if (paidWith === 'AD_COINS') {
      user.wallets.adCoins = Math.max(0, (user.wallets.adCoins || 0) - amountPaid);
    } else {
      let remaining = amountPaid;
      if (user.wallets.bonusCash >= remaining) {
        user.wallets.bonusCash -= remaining;
        remaining = 0;
      } else {
        remaining -= user.wallets.bonusCash;
        user.wallets.bonusCash = 0;
        if (user.wallets.depositCash >= remaining) {
          user.wallets.depositCash -= remaining;
          remaining = 0;
        } else {
          remaining -= user.wallets.depositCash;
          user.wallets.depositCash = 0;
          user.wallets.winningCash = Math.max(0, user.wallets.winningCash - remaining);
        }
      }
    }
    user.stats.matchesPlayed = (user.stats.matchesPlayed || 0) + 1;
  }

  saveDB();
  broadcast('MATCH_JOINED', { matchId: id, participant, filledSlots: match.filledSlots, status: match.status });
  res.json({ success: true, match, user });
});

// 6. Update Credentials (Room ID & Password)
app.post('/api/matches/:id/credentials', (req, res) => {
  const { id } = req.params;
  const { roomId, roomPassword, isRevealed } = req.body;
  const match = db.matches.find(m => m.id === id);
  if (!match) return res.status(404).json({ success: false, message: 'Match not found' });

  match.credentials = {
    roomId: roomId !== undefined ? roomId : match.credentials.roomId,
    roomPassword: roomPassword !== undefined ? roomPassword : match.credentials.roomPassword,
    isRevealed: isRevealed !== undefined ? isRevealed : true
  };

  if (match.credentials.roomId && match.status === 'upcoming') {
    match.status = 'roomFilling';
  }

  saveDB();
  broadcast('CREDENTIALS_UPDATED', { matchId: id, credentials: match.credentials, status: match.status });
  res.json({ success: true, credentials: match.credentials });
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
  if (Array.isArray(results)) {
    results.forEach(resItem => {
      const p = match.participants.find(part => part.uid === resItem.uid);
      if (p) {
        p.kills = resItem.kills || 0;
        p.rank = resItem.rank;
        p.prizeAwarded = resItem.prizeAwarded || 0;
        p.isWinner = (resItem.rank === 1);

        if (p.prizeAwarded > 0) {
          totalPrizeGiven += p.prizeAwarded;
          const user = db.users[p.uid];
          if (user) {
            user.wallets.winningCash = (user.wallets.winningCash || 0) + p.prizeAwarded;
            user.stats.matchesWon = (user.stats.matchesWon || 0) + (p.isWinner ? 1 : 0);
            user.stats.totalKills = (user.stats.totalKills || 0) + p.kills;
            user.stats.totalWinningsCash = (user.stats.totalWinningsCash || 0) + p.prizeAwarded;
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

// 10. User Management
app.get('/api/users/:uid', (req, res) => {
  const { uid } = req.params;
  const user = db.users[uid];
  if (!user) return res.status(404).json({ success: false, message: 'User not found' });
  res.json({ success: true, user });
});

app.post('/api/users', (req, res) => {
  const user = req.body;
  if (!user.uid) return res.status(400).json({ success: false, message: 'UID required' });

  db.users[user.uid] = {
    ...db.users[user.uid],
    ...user,
    lastSeen: new Date().toISOString()
  };
  saveDB();
  res.json({ success: true, user: db.users[user.uid] });
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
    user.wallets.depositCash = (user.wallets.depositCash || 0) + txn.amount;
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
    const uid = notes.uid || notes.userId;

    if (uid && db.users[uid]) {
      db.users[uid].wallets.depositCash = (db.users[uid].wallets.depositCash || 0) + amount;
      const txn = {
        id: `txn_rzp_${payment.id}`,
        userId: uid,
        amount,
        type: 'deposit',
        walletAffected: 'depositCash',
        title: 'Razorpay Instant UPI Deposit',
        description: `Payment ID: ${payment.id}`,
        status: 'success',
        createdAt: new Date().toISOString()
      };
      db.transactions.unshift(txn);
      saveDB();
      broadcast('TRANSACTION_UPDATED', txn);
      console.log(`[Webhook] Credited ₹${amount} to user ${uid}`);
    }
  }
  res.json({ status: 'ok' });
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
    user.wallets.winningCash = Math.max(0, (user.wallets.winningCash || 0) - withdrawal.amount);
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
      user.wallets.winningCash = (user.wallets.winningCash || 0) + db.withdrawals[index].amount;
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
