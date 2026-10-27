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

// ── 0. USER AUTHENTICATION APIS (SIGNUP, LOGIN, PROFILE) ──
app.post('/api/auth/signup', (req, res) => {
  const { name, phoneNumber, email, password, inGameName, inGameId, referralCode } = req.body;
  if (!name || !phoneNumber || !email || !password) {
    return res.status(400).json({ success: false, message: 'नाम, मोबाइल, ईमेल और पासवर्ड अनिवार्य हैं!' });
  }

  const cleanEmail = email.trim().toLowerCase();
  const cleanPhone = phoneNumber.trim();

  for (const uid in db.users) {
    const existing = db.users[uid];
    if (existing.email && existing.email.toLowerCase() === cleanEmail) {
      return res.status(400).json({ success: false, message: 'यह ईमेल आईडी पहले से पंजीकृत है!' });
    }
    if (existing.phoneNumber && existing.phoneNumber === cleanPhone) {
      return res.status(400).json({ success: false, message: 'यह फ़ोन नंबर पहले से पंजीकृत है!' });
    }
  }

  const deviceId = `usr_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
  const rCode = (100000 + (Date.now() % 900000)).toString();

  let welcomeCoins = 0;
  let referrerUid = null;

  if (referralCode && referralCode.trim().length > 0) {
    const cleanRef = referralCode.trim();
    for (const uid in db.users) {
      if (db.users[uid].referralCode === cleanRef) {
        referrerUid = uid;
        welcomeCoins = (db.config.coinEconomy && db.config.coinEconomy.referredUserBonus) || 10;
        console.log(`[REFERRAL SIGNUP] User entered referral code ${cleanRef}. Awarded +${welcomeCoins} bonus coins to new user. Referrer ${uid} will receive reward after 5 tournament matches.`);
        break;
      }
    }
  }

  db.users[deviceId] = {
    uid: deviceId,
    displayName: name.trim(),
    name: name.trim(),
    phoneNumber: cleanPhone,
    email: cleanEmail,
    password: password.trim(),
    inGameName: inGameName ? inGameName.trim() : name.trim(),
    inGameId: inGameId ? inGameId.trim() : '',
    adCoins: welcomeCoins,
    winningCoins: 0,
    totalWins: 0,
    totalKills: 0,
    totalAdsWatched: 0,
    tournamentsPlayed: 0,
    referralRewardClaimed: false,
    referralCode: rCode,
    referredBy: referrerUid ? referralCode.trim() : '',
    createdAt: new Date().toISOString(),
    lastActive: new Date().toISOString()
  };

  saveDB();
  console.log(`[AUTH] New user registered: ${name} (${cleanEmail}, Phone: ${cleanPhone})`);

  res.json({
    success: true,
    message: 'खाता सफलतापूर्वक बन गया!',
    user: db.users[deviceId]
  });
});

// ── 👥 REFERRAL TRACKING API (TRANSPARENCY & 5-MATCH STATUS) ──
app.get('/api/referral/my-referrals', (req, res) => {
  const uid = req.query.uid || req.query.deviceId;
  if (!uid || !db.users[uid]) {
    return res.status(404).json({ success: false, error: 'User not found' });
  }

  const user = db.users[uid];
  const myRefCode = user.referralCode;
  const targetMatches = (db.config.coinEconomy && db.config.coinEconomy.referralMatchesTarget) || 5;
  const rewardCoins = (db.config.coinEconomy && db.config.coinEconomy.referralReward) || 50;

  const referrals = [];
  let totalCoinsEarned = 0;
  let pendingFriends = 0;
  let unlockedFriends = 0;

  for (const otherUid in db.users) {
    if (otherUid === uid) continue;
    const other = db.users[otherUid];
    if (other.referredBy && (other.referredBy === myRefCode || other.referredBy === uid)) {
      const matches = Number(other.tournamentsPlayed || 0);
      const isUnlocked = matches >= targetMatches || other.referralRewardClaimed === true;
      const rem = Math.max(0, targetMatches - matches);

      if (isUnlocked) {
        totalCoinsEarned += rewardCoins;
        unlockedFriends++;
      } else {
        pendingFriends++;
      }

      referrals.push({
        uid: other.uid,
        name: other.displayName || other.name || `Player_${other.uid.slice(-4)}`,
        inGameName: other.inGameName || '',
        matchesPlayed: matches,
        targetMatches: targetMatches,
        remainingMatches: rem,
        isUnlocked: isUnlocked,
        status: isUnlocked ? 'UNLOCKED' : 'PENDING',
        statusText: isUnlocked
          ? `✅ +${rewardCoins} कॉइन्स मिल चुके हैं!`
          : `⏳ ${matches}/${targetMatches} मैच खेले (${rem} मैच बाकी)`,
        joinedAt: other.createdAt || ''
      });
    }
  }

  res.json({
    success: true,
    myReferralCode: myRefCode,
    targetMatches,
    rewardPerReferral: rewardCoins,
    totalCoinsEarned,
    pendingFriends,
    unlockedFriends,
    referrals
  });
});

app.post('/api/auth/login', (req, res) => {
  const { identifier, password } = req.body;
  if (!identifier || !password) {
    return res.status(400).json({ success: false, message: 'ईमेल/फ़ोन और पासवर्ड दर्ज करें!' });
  }

  const cleanIdent = identifier.trim().toLowerCase();
  const cleanPass = password.trim();

  let foundUser = null;
  for (const uid in db.users) {
    const u = db.users[uid];
    if (
      (u.email && u.email.toLowerCase() === cleanIdent) ||
      (u.phoneNumber && u.phoneNumber === cleanIdent) ||
      (u.uid === cleanIdent)
    ) {
      if (u.password === cleanPass) {
        foundUser = u;
        break;
      } else {
        return res.status(400).json({ success: false, message: 'गलत पासवर्ड! कृपया दोबारा जांचें।' });
      }
    }
  }

  if (!foundUser) {
    return res.status(404).json({ success: false, message: 'खाता नहीं मिला! कृपया साइन-अप करें।' });
  }

  foundUser.lastActive = new Date().toISOString();
  saveDB();

  res.json({
    success: true,
    message: 'लॉगिन सफल!',
    user: foundUser
  });
});

app.post('/api/auth/update-ff-profile', (req, res) => {
  const { uid, inGameName, inGameId } = req.body;
  if (!uid || !db.users[uid]) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }

  const u = db.users[uid];
  if (inGameName) u.inGameName = inGameName.trim();
  if (inGameId) u.inGameId = inGameId.trim();
  saveDB();

  res.json({ success: true, message: 'फ्री फायर प्रोफाइल अपडेट हो गया!', user: u });
});

// ── 1. USER WALLET & PROFILE SYNC (ATOMIC & PERSISTENT) ──
app.post('/api/tournament/sync-user', (req, res) => {
  const { deviceId, displayName, coinsToAdd, referralCode, inGameName, inGameId } = req.body;
  if (!deviceId) return res.status(400).json({ error: 'Device ID required' });

  if (!db.users[deviceId]) {
    const rCode = (100000 + (Date.now() % 900000)).toString();
    let initialCoins = 0;
    let validReferrer = null;

    if (referralCode && referralCode.trim().length > 0) {
      const cleanRef = referralCode.trim();
      for (const uid in db.users) {
        if (db.users[uid].referralCode === cleanRef && uid !== deviceId) {
          validReferrer = uid;
          const userBonus = (db.config.coinEconomy && db.config.coinEconomy.referredUserBonus) || 10;
          initialCoins = userBonus; // New user gets bonus ONLY with valid referral code
          console.log(`[REFERRAL SYNC] User ${deviceId} used referral ${cleanRef}. Awarded +${userBonus} coins to user. Referrer ${uid} will receive reward after 5 tournament matches.`);
          break;
        }
      }
    }

    db.users[deviceId] = {
      uid: deviceId,
      displayName: displayName || `Player_${deviceId.slice(-4)}`,
      inGameName: inGameName || displayName || `Player_${deviceId.slice(-4)}`,
      inGameId: inGameId || '',
      adCoins: initialCoins,
      winningCoins: 0,
      totalWins: 0,
      totalKills: 0,
      totalAdsWatched: 0,
      tournamentsPlayed: 0,
      referralRewardClaimed: false,
      hasPlayedFirstMatch: false,
      referralCode: rCode,
      referredBy: validReferrer ? referralCode.trim() : '',
      createdAt: new Date().toISOString(),
      lastActive: new Date().toISOString()
    };
  } else {
    const u = db.users[deviceId];
    u.winningCoins = u.winningCoins || 0;
    if (displayName) u.displayName = displayName;
    if (inGameName) u.inGameName = inGameName;
    if (inGameId) u.inGameId = inGameId;
    if (referralCode && !u.referredBy && referralCode.trim() !== u.referralCode) {
      const cleanRef = referralCode.trim();
      for (const uid in db.users) {
        if (db.users[uid].referralCode === cleanRef && uid !== deviceId) {
          u.referredBy = cleanRef;
          const userBonus = (db.config.coinEconomy && db.config.coinEconomy.referredUserBonus) || 10;
          u.adCoins = (u.adCoins || 0) + userBonus;
          u.tournamentsPlayed = u.tournamentsPlayed || 0;
          u.referralRewardClaimed = false;
          console.log(`[EXISTING USER REFERRAL] User ${deviceId} linked referral ${cleanRef}. Awarded +${userBonus} coins to user. Referrer ${uid} will receive reward after 5 tournament matches.`);
          break;
        }
      }
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

// ── 4. ESPORTS LEADERBOARD WITH SMART PRO-BOT SHIELD & DYNAMIC PRIZE POOL ──
const PRO_BOT_POOLS = [
  [
    { uid: 'pro_ff_901', name: '⚡ ʀᴀsᴛᴀʀ_𝟿𝟿', inGameId: '2948102941', inGameName: 'RASTAR_99', totalWins: 64, totalKills: 480 },
    { uid: 'pro_ff_902', name: '亗 ᴋɪʟʟᴇʀ 亗', inGameId: '1827401928', inGameName: 'KILLER_PRO', totalWins: 52, totalKills: 395 },
    { uid: 'pro_ff_903', name: '★ 𝕬𝖞𝖚𝖘𝖍_𝕱𝕱 ★', inGameId: '3019283741', inGameName: 'AYUSH_OP', totalWins: 45, totalKills: 330 }
  ],
  [
    { uid: 'pro_ff_904', name: '࿐☠️ ɴɪɴᴊᴀ ☠️࿐', inGameId: '4120938471', inGameName: 'NINJA_GOD', totalWins: 68, totalKills: 510 },
    { uid: 'pro_ff_905', name: '༺LeGenD༻', inGameId: '2819047192', inGameName: 'LEGEND_FF', totalWins: 55, totalKills: 410 },
    { uid: 'pro_ff_906', name: '亗 BADBOY_07 亗', inGameId: '5192837412', inGameName: 'BADBOY_07', totalWins: 47, totalKills: 345 }
  ],
  [
    { uid: 'pro_ff_907', name: '⚡ 𝙰𝙼𝙰𝙽_𝙵𝙵 ⚡', inGameId: '1948204918', inGameName: 'AMAN_PRO', totalWins: 62, totalKills: 460 },
    { uid: 'pro_ff_908', name: '亗 𝚁𝙾𝙷𝙸𝚃 亗', inGameId: '3829104712', inGameName: 'ROHIT_FF', totalWins: 50, totalKills: 380 },
    { uid: 'pro_ff_909', name: '★ 𝚅𝙸𝙺𝚁𝙰𝙼 ★', inGameId: '4910283741', inGameName: 'VIKRAM_GOD', totalWins: 43, totalKills: 320 }
  ],
  [
    { uid: 'pro_ff_910', name: '꧁༒☬TUK_TUK☬༒꧂', inGameId: '3829174028', inGameName: 'TUK_TUK_BOY', totalWins: 65, totalKills: 490 },
    { uid: 'pro_ff_911', name: '⚡ VIPER_007 ⚡', inGameId: '2938102948', inGameName: 'VIPER_HEADSHOT', totalWins: 53, totalKills: 405 },
    { uid: 'pro_ff_912', name: '亗 DARK_HORSE 亗', inGameId: '1928374619', inGameName: 'DARK_HORSE', totalWins: 46, totalKills: 335 }
  ]
];

function getWeekSeedNumber() {
  const d = new Date();
  const dUtc = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
  const dayNum = dUtc.getUTCDay() || 7;
  dUtc.setUTCDate(dUtc.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(dUtc.getUTCFullYear(), 0, 1));
  const weekNo = Math.ceil((((dUtc - yearStart) / 86400000) + 1) / 7);
  return dUtc.getUTCFullYear() * 100 + weekNo;
}

app.get(['/api/leaderboard', '/api/tournament/leaderboard'], (req, res) => {
  const prizePool = db.config.weeklyPrizePool || 1000;
  const r1Percent = (db.config.prizeDistribution && db.config.prizeDistribution.rank1Percent) || 50;
  const r2Percent = (db.config.prizeDistribution && db.config.prizeDistribution.rank2Percent) || 30;
  const r3Percent = (db.config.prizeDistribution && db.config.prizeDistribution.rank3Percent) || 20;

  const rank1Prize = Math.round(prizePool * (r1Percent / 100));
  const rank2Prize = Math.round(prizePool * (r2Percent / 100));
  const rank3Prize = Math.round(prizePool * (r3Percent / 100));

  // Filter real users
  const realUsers = Object.values(db.users || {}).filter(u => u && !u.uid.startsWith('pro_ff_') && !u.uid.startsWith('bot_'));
  
  // Compute weekly score for real users if not set
  realUsers.forEach(u => {
    if (!u.weeklyScore) {
      u.weeklyScore = ((u.totalWins || 0) * 100) + ((u.totalKills || 0) * 10) + ((u.adCoins || 0) * 2) + ((u.winningCoins || 0) * 10);
    }
  });

  realUsers.sort((a, b) => (b.weeklyScore || 0) - (a.weeklyScore || 0));

  // Determine top real score
  const maxRealScore = realUsers.length > 0 ? (realUsers[0].weeklyScore || 0) : 0;

  // Pick top 3 pro bots for this week
  const weekSeed = getWeekSeedNumber();
  const poolIndex = Math.abs(weekSeed) % PRO_BOT_POOLS.length;
  const activeBots = PRO_BOT_POOLS[poolIndex];

  // Dynamic bot scores: always stay comfortably ahead of real player
  const botScores = [
    Math.max(maxRealScore + 1850, 14200),
    Math.max(maxRealScore + 1120, 11450),
    Math.max(maxRealScore + 540, 8950)
  ];

  const top3List = [
    {
      rank: 1,
      uid: activeBots[0].uid,
      name: activeBots[0].name,
      inGameId: activeBots[0].inGameId,
      inGameName: activeBots[0].inGameName,
      totalWins: activeBots[0].totalWins,
      totalKills: activeBots[0].totalKills,
      winningCoins: 0,
      weeklyScore: botScores[0],
      prize: `₹${rank1Prize.toLocaleString('en-IN')}`,
      avatar: 'assets/imgasest/booyah_hero_logo.png'
    },
    {
      rank: 2,
      uid: activeBots[1].uid,
      name: activeBots[1].name,
      inGameId: activeBots[1].inGameId,
      inGameName: activeBots[1].inGameName,
      totalWins: activeBots[1].totalWins,
      totalKills: activeBots[1].totalKills,
      winningCoins: 0,
      weeklyScore: botScores[1],
      prize: `₹${rank2Prize.toLocaleString('en-IN')}`,
      avatar: 'assets/imgasest/booyah_hero_logo.png'
    },
    {
      rank: 3,
      uid: activeBots[2].uid,
      name: activeBots[2].name,
      inGameId: activeBots[2].inGameId,
      inGameName: activeBots[2].inGameName,
      totalWins: activeBots[2].totalWins,
      totalKills: activeBots[2].totalKills,
      winningCoins: 0,
      weeklyScore: botScores[2],
      prize: `₹${rank3Prize.toLocaleString('en-IN')}`,
      avatar: 'assets/imgasest/booyah_hero_logo.png'
    }
  ];

  // Add real players starting from Rank 4
  const realLeaderboard = realUsers.slice(0, 97).map((u, idx) => ({
    rank: idx + 4,
    uid: u.uid,
    name: u.inGameName || u.displayName || u.name || `Player_${idx + 4}`,
    inGameId: u.inGameId || '',
    totalWins: u.totalWins || 0,
    totalKills: u.totalKills || 0,
    winningCoins: u.winningCoins || 0,
    weeklyScore: u.weeklyScore || 0,
    prize: (idx + 4 <= 10) ? '₹25 एंट्री बोनस' : '10 एंट्री कॉइन्स',
    avatar: 'assets/imgasest/booyah_hero_logo.png'
  }));

  const fullLeaderboard = [...top3List, ...realLeaderboard];

  res.json({
    success: true,
    prizePool: `₹${prizePool.toLocaleString('en-IN')}`,
    prizePoolAmount: prizePool,
    season: db.config.season || 2,
    prizes: {
      rank1: `₹${rank1Prize.toLocaleString('en-IN')}`,
      rank2: `₹${rank2Prize.toLocaleString('en-IN')}`,
      rank3: `₹${rank3Prize.toLocaleString('en-IN')}`
    },
    leaderboard: fullLeaderboard
  });
});

// Admin Prize Pool Setter
app.post('/api/admin/set-prize-pool', (req, res) => {
  const { prizePool, rank1Percent, rank2Percent, rank3Percent } = req.body;
  if (prizePool !== undefined) {
    db.config.weeklyPrizePool = parseInt(prizePool, 10) || 1000;
  }
  if (!db.config.prizeDistribution) db.config.prizeDistribution = {};
  if (rank1Percent !== undefined) db.config.prizeDistribution.rank1Percent = parseInt(rank1Percent, 10) || 50;
  if (rank2Percent !== undefined) db.config.prizeDistribution.rank2Percent = parseInt(rank2Percent, 10) || 30;
  if (rank3Percent !== undefined) db.config.prizeDistribution.rank3Percent = parseInt(rank3Percent, 10) || 20;
  saveDB();
  res.json({
    success: true,
    weeklyPrizePool: db.config.weeklyPrizePool,
    prizeDistribution: db.config.prizeDistribution,
    message: 'वीकली प्राइज़ पूल सफलतापूर्वक अपडेट हो गया!'
  });
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
    weeklyPrizePool: db.config.weeklyPrizePool || 1000,
    prizeDistribution: db.config.prizeDistribution || { rank1Percent: 50, rank2Percent: 30, rank3Percent: 20 },
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
    u.weeklyScore = (u.weeklyScore || 0) + scoreNum + (earned * 5);
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
