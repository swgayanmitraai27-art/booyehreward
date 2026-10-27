// ==============================================================================
// 🏆 FREE FIRE INDIA TOURNAMENT ENGINE (Booyah Rewards Master Module)
// Unified Coin Economy • Team Codes • Multi-Round Groups • 100% In-App Support • World Chat
// ==============================================================================

const fs = require('fs');
const path = require('path');

module.exports = function setupFFTournamentEngine(app, db, saveDB, upload) {
  // ── 1. INITIALIZE COLLECTIONS & DEFAULT CONFIG ─────────────────────────────
  if (!db.ff_tournaments) db.ff_tournaments = [];
  if (!db.ff_groups) db.ff_groups = [];
  if (!db.ff_teams) db.ff_teams = [];
  if (!db.ff_chat) db.ff_chat = [];
  if (!db.ff_support_tickets) db.ff_support_tickets = [];
  if (!db.ff_daily_tasks) db.ff_daily_tasks = {};

  if (!db.config) db.config = {};
  if (!db.config.coinEconomy) {
    db.config.coinEconomy = {
      adCoinReward: 10,       // 1 Rewarded Ad = 10 Coins
      dailyAdLimit: 15,       // Max 15 rewarded ads per day
      welcomeBonus: 20,       // 20 Welcome Coins on signup
      referralReward: 50,     // 50 Coins to referrer (only after friend plays 1st match)
      redeemRate: 10          // 10 Coins = ₹1 (e.g. 100 Coins = ₹10 Redeem Code)
    };
  }

  if (!db.config.socialLinks) {
    db.config.socialLinks = {
      youtube: 'https://youtube.com/@booyahrewards',
      instagram: 'https://instagram.com/booyahrewards',
      telegram: 'https://t.me/booyahrewards'
    };
  }

  if (!db.config.branding) {
    db.config.branding = {
      gameName: 'FREE FIRE INDIA',
      tagline: 'India Ka Apna Battle Royale',
      subTagline: 'India Ka Apna Esports Platform'
    };
  }

  // Auto-seed Default Tournaments if none exist
  function seedDefaultTournaments() {
    if (db.ff_tournaments.length === 0) {
      console.log('[FF ENGINE] Seeding default Free Fire India Tournaments...');

      // 1. Battle Royale Solo
      db.ff_tournaments.push({
        id: 'FF-BR-SOLO-01',
        title: '🔥 Free Fire India: Bermuda Solo Cup',
        category: 'BR',
        mode: 'Battle Royale (Solo)',
        teamFormat: 'solo',
        map: 'Bermuda',
        bannerUrl: 'https://vps.swgayanbhumi.in/uploads/br_banner.png',
        entryFeeCoins: 20,
        totalSlots: 48,
        filledSlots: 0,
        status: 'OPEN', // OPEN | LIVE | ENDED
        scheduleType: 'dynamic', // dynamic | scheduled
        matchTimeText: 'Starts when 48 Slots Full',
        scheduledTime: new Date(Date.now() + 3600000).toISOString(),
        prizePool: {
          totalCoins: 400,
          firstPlace: 200,
          secondPlace: 100,
          thirdPlace: 50,
          perKill: 5
        },
        roundNumber: 1,
        isMega: false,
        groups: [
          {
            groupId: 'grp_br_01_A',
            groupName: 'Group A',
            maxSlots: 48,
            filledSlots: 0,
            roomId: '',
            roomPassword: '',
            isCredentialsPublished: false,
            publishedAt: null,
            participants: []
          }
        ],
        createdAt: new Date().toISOString()
      });

      // 2. Clash Squad 4v4
      db.ff_tournaments.push({
        id: 'FF-CS-SQUAD-01',
        title: '⚡ Free Fire India: CS 4v4 Squad Clash',
        category: 'CS',
        mode: 'Clash Squad (4v4)',
        teamFormat: 'squad',
        map: 'Bermuda',
        bannerUrl: 'https://vps.swgayanbhumi.in/uploads/cs_banner.png',
        entryFeeCoins: 15, // per player
        totalSlots: 8, // 2 squads
        filledSlots: 0,
        status: 'OPEN',
        scheduleType: 'dynamic',
        matchTimeText: 'Starts when 2 Squads Ready',
        scheduledTime: new Date(Date.now() + 5400000).toISOString(),
        prizePool: {
          totalCoins: 200,
          firstPlace: 200, // split 50 each
          secondPlace: 0,
          thirdPlace: 0,
          perKill: 0
        },
        roundNumber: 1,
        isMega: false,
        groups: [
          {
            groupId: 'grp_cs_01_A',
            groupName: 'Group A',
            maxSlots: 8,
            filledSlots: 0,
            roomId: '',
            roomPassword: '',
            isCredentialsPublished: false,
            publishedAt: null,
            participants: []
          }
        ],
        createdAt: new Date().toISOString()
      });

      // 3. Lone Wolf 1v1
      db.ff_tournaments.push({
        id: 'FF-LW-1V1-01',
        title: '🎯 Free Fire India: Lone Wolf 1v1 Battle',
        category: 'LW',
        mode: 'Lone Wolf (1v1)',
        teamFormat: 'solo',
        map: 'Iron Cage',
        bannerUrl: 'https://vps.swgayanbhumi.in/uploads/lonewolf_banner.png',
        entryFeeCoins: 10,
        totalSlots: 2,
        filledSlots: 0,
        status: 'OPEN',
        scheduleType: 'dynamic',
        matchTimeText: 'Starts when 2 Players Join',
        scheduledTime: new Date(Date.now() + 7200000).toISOString(),
        prizePool: {
          totalCoins: 25,
          firstPlace: 25,
          secondPlace: 0,
          thirdPlace: 0,
          perKill: 0
        },
        roundNumber: 1,
        isMega: false,
        groups: [
          {
            groupId: 'grp_lw_01_A',
            groupName: 'Group A',
            maxSlots: 2,
            filledSlots: 0,
            roomId: '',
            roomPassword: '',
            isCredentialsPublished: false,
            publishedAt: null,
            participants: []
          }
        ],
        createdAt: new Date().toISOString()
      });

      // 4. Mega Tournament (Multi-Round 1,000 Players)
      db.ff_tournaments.push({
        id: 'FF-MEGA-01',
        title: '🏆 Free Fire India: ₹500 Mega Launch Cup',
        category: 'MEGA',
        mode: 'Mega Tournament (Multi-Round)',
        teamFormat: 'solo',
        map: 'Bermuda',
        bannerUrl: 'https://vps.swgayanbhumi.in/uploads/br_banner.png',
        entryFeeCoins: 50,
        totalSlots: 480, // 10 groups of 48
        filledSlots: 0,
        status: 'OPEN',
        scheduleType: 'scheduled',
        matchTimeText: 'Today 8:00 PM IST',
        scheduledTime: new Date(Date.now() + 86400000).toISOString(),
        prizePool: {
          totalCoins: 5000, // ₹500
          firstPlace: 2500, // ₹250
          secondPlace: 1500, // ₹150
          thirdPlace: 1000, // ₹100
          perKill: 10
        },
        roundNumber: 1, // Round 1: Qualifiers
        isMega: true,
        groups: [
          {
            groupId: 'grp_mega_01_A',
            groupName: 'Group A (Qualifiers)',
            maxSlots: 48,
            filledSlots: 0,
            roomId: '',
            roomPassword: '',
            isCredentialsPublished: false,
            publishedAt: null,
            participants: []
          }
        ],
        createdAt: new Date().toISOString()
      });

      saveDB();
    }
  }
  seedDefaultTournaments();

  // ── 2. TOURNAMENTS LIST & DETAILS ──────────────────────────────────────────
  app.get('/api/ff/tournaments', (req, res) => {
    const { category, uid } = req.query;
    let list = db.ff_tournaments || [];
    if (category && category !== 'ALL') {
      list = list.filter(t => (t.category || '').toUpperCase() === category.toUpperCase());
    }

    // Attach user registration flag if uid provided
    const decorated = list.map(t => {
      let isUserRegistered = false;
      let userSlot = null;
      let userGroup = null;

      if (uid && t.groups) {
        for (const g of t.groups) {
          const p = (g.participants || []).find(pt => pt.uid === uid);
          if (p) {
            isUserRegistered = true;
            userSlot = p.slotNo;
            userGroup = g.groupName;
            break;
          }
        }
      }

      return {
        ...t,
        isUserRegistered,
        userSlot,
        userGroup
      };
    });

    res.json({
      success: true,
      branding: db.config.branding,
      coinEconomy: db.config.coinEconomy,
      tournaments: decorated
    });
  });

  // ── 3. REGISTER FOR TOURNAMENT (COIN ENTRY + MULTI-GROUP) ───────────────────
  app.post('/api/ff/tournaments/register', (req, res) => {
    const { tournamentId, uid, inGameName, inGameId } = req.body;
    if (!tournamentId || !uid || !inGameName) {
      return res.status(400).json({ success: false, error: 'Tournament ID, UID, and Free Fire IGN are required.' });
    }

    const tourn = (db.ff_tournaments || []).find(t => t.id === tournamentId);
    if (!tourn) return res.status(404).json({ success: false, error: 'Tournament not found.' });
    if (tourn.status === 'ENDED') return res.status(400).json({ success: false, error: 'This tournament has already ended.' });

    // Ensure user profile in DB
    if (!db.users[uid]) {
      db.users[uid] = {
        uid,
        displayName: inGameName,
        adCoins: db.config.coinEconomy.welcomeBonus || 20,
        inGameName,
        inGameId: inGameId || '',
        totalWins: 0,
        totalKills: 0,
        totalAdsWatched: 0,
        hasPlayedFirstMatch: false,
        registeredTournaments: []
      };
    }
    const user = db.users[uid];
    user.inGameName = inGameName;
    if (inGameId) user.inGameId = inGameId;

    // Check if already registered
    let alreadyReg = false;
    for (const g of tourn.groups || []) {
      if ((g.participants || []).some(p => p.uid === uid)) {
        alreadyReg = true;
        break;
      }
    }
    if (alreadyReg) {
      return res.status(400).json({ success: false, error: 'You are already registered for this tournament!' });
    }

    // Check entry coins (Dual Wallet: Bonus Ad Coins first, then Winning Coins)
    const entryFee = Number(tourn.entryCoins || tourn.entryFeeCoins || 0);
    const totalAvail = (user.adCoins || 0) + (user.winningCoins || 0);
    if (totalAvail < entryFee) {
      return res.status(400).json({
        success: false,
        error: `Insufficient Coins! You need ${entryFee} Coins to enter. Total balance: ${totalAvail} Coins (Bonus: ${user.adCoins || 0}, Winnings: ${user.winningCoins || 0}).`,
        neededCoins: entryFee,
        userCoins: totalAvail
      });
    }

    // Deduct coins (Prioritize Bonus/Ad coins so user keeps Withdrawable Winning Coins)
    if ((user.adCoins || 0) >= entryFee) {
      user.adCoins -= entryFee;
    } else {
      const rem = entryFee - (user.adCoins || 0);
      user.adCoins = 0;
      user.winningCoins = Math.max(0, (user.winningCoins || 0) - rem);
    }

    // Find open group or auto-create next group (Group A -> Group B -> Group C...)
    if (!tourn.groups || tourn.groups.length === 0) {
      tourn.groups = [{
        groupId: `grp_${tourn.id}_A`,
        groupName: 'Group A',
        maxSlots: tourn.isMega ? 48 : (tourn.totalSlots || 48),
        filledSlots: 0,
        roomId: '',
        roomPassword: '',
        isCredentialsPublished: false,
        participants: []
      }];
    }

    let targetGroup = tourn.groups.find(g => (g.filledSlots || 0) < (g.maxSlots || 48));
    if (!targetGroup) {
      // Create next group letter (B, C, D...)
      const nextLetter = String.fromCharCode(65 + tourn.groups.length);
      targetGroup = {
        groupId: `grp_${tourn.id}_${nextLetter}`,
        groupName: `Group ${nextLetter}`,
        maxSlots: 48,
        filledSlots: 0,
        roomId: '',
        roomPassword: '',
        isCredentialsPublished: false,
        participants: []
      };
      tourn.groups.push(targetGroup);
    }

    const assignedSlot = (targetGroup.filledSlots || 0) + 1;
    targetGroup.participants.push({
      uid,
      inGameName,
      inGameId: inGameId || user.inGameId || '',
      slotNo: assignedSlot,
      registeredAt: new Date().toISOString(),
      currentRoundStatus: 'Registered'
    });
    targetGroup.filledSlots = targetGroup.participants.length;
    tourn.filledSlots = (tourn.filledSlots || 0) + 1;

    // ── ⚡ AUTO-SCHEDULE COUNTDOWN ON 100% SLOTS FULL ──
    if (tourn.filledSlots >= tourn.totalSlots) {
      if (tourn.scheduleType === 'dynamic') {
        tourn.matchTimeText = 'SLOTS FULL! Match Starts in 15 Mins';
        tourn.scheduledTime = new Date(Date.now() + 15 * 60 * 1000).toISOString();
        console.log(`[FF ENGINE] ⚡ Tournament ${tourn.id} slots FULL (${tourn.filledSlots}/${tourn.totalSlots})! Set countdown to 15 mins.`);
        
        if (!db.ff_notifications) db.ff_notifications = [];
        db.ff_notifications.unshift({
          id: `notif_${Date.now()}`,
          title: `🔥 ${tourn.title} SLOTS 100% FULL!`,
          message: 'All slots have been filled! Match starts in 15 minutes. Room ID & Password will be published soon!',
          type: 'MATCH_ALERT',
          tournamentId: tourn.id,
          createdAt: new Date().toISOString()
        });
      }
    }

    // ── 🎯 ANTI-CHEAT REFERRAL UNLOCK: REWARD REFERRER ONLY AFTER 1ST MATCH PLAYED ──
    if (user.referredBy && !user.hasPlayedFirstMatch) {
      user.hasPlayedFirstMatch = true;
      const refUid = user.referredBy;
      if (db.users[refUid]) {
        const bonusCoins = db.config.coinEconomy.referralReward || 50;
        db.users[refUid].adCoins = (db.users[refUid].adCoins || 0) + bonusCoins;
        console.log(`[REFERRAL UNLOCKED] User ${uid} played 1st match! Credited ${bonusCoins} Coins to Referrer ${refUid}`);
      }
    }

    saveDB();
    console.log(`[FF REGISTER] User ${uid} (${inGameName}) registered for ${tourn.title} -> ${targetGroup.groupName} Slot #${assignedSlot}`);

    res.json({
      success: true,
      message: `Registration confirmed for ${targetGroup.groupName} Slot #${assignedSlot}!`,
      slotNo: assignedSlot,
      groupName: targetGroup.groupName,
      remainingCoins: user.adCoins
    });
  });

  // ── 4. TEAM CODE ENGINE (DUO 2v2 & SQUAD 4v4) ───────────────────────────────
  app.post('/api/ff/teams/create', (req, res) => {
    const { tournamentId, captainUid, captainInGameName, captainInGameId, teamName } = req.body;
    if (!tournamentId || !captainUid || !teamName) {
      return res.status(400).json({ success: false, error: 'Tournament ID, Captain UID, and Team Name are required.' });
    }

    const tourn = (db.ff_tournaments || []).find(t => t.id === tournamentId);
    if (!tourn) return res.status(404).json({ success: false, error: 'Tournament not found.' });

    const maxMembers = tourn.teamFormat === 'duo' ? 2 : 4;
    const entryFee = Number(tourn.entryCoins || tourn.entryFeeCoins || 0);

    const user = db.users[captainUid];
    if (!user || (user.adCoins || 0) < entryFee) {
      return res.status(400).json({ success: false, error: `Captain needs ${entryFee} Coins to create the team.` });
    }

    // Generate unique 6-digit team code (e.g. BOY-489)
    const codeNum = Math.floor(100 + Math.random() * 900);
    const teamCode = `BOY-${codeNum}`;

    user.adCoins -= entryFee;

    const newTeam = {
      teamCode,
      tournamentId,
      teamName,
      captainUid,
      maxMembers,
      members: [
        {
          uid: captainUid,
          inGameName: captainInGameName || user.displayName || 'Captain',
          inGameId: captainInGameId || user.inGameId || '',
          isCaptain: true,
          joinedAt: new Date().toISOString()
        }
      ],
      isLocked: false,
      createdAt: new Date().toISOString()
    };

    db.ff_teams.push(newTeam);
    saveDB();

    console.log(`[TEAM CREATED] Team ${teamName} created with Code: ${teamCode} by Captain ${captainUid}`);
    res.json({
      success: true,
      message: `Team "${teamName}" created! Share code "${teamCode}" with your teammates.`,
      teamCode,
      team: newTeam,
      remainingCoins: user.adCoins
    });
  });

  app.post('/api/ff/teams/join', (req, res) => {
    const { teamCode, uid, inGameName, inGameId } = req.body;
    if (!teamCode || !uid || !inGameName) {
      return res.status(400).json({ success: false, error: 'Team Code, UID, and In-Game Name are required.' });
    }

    const team = (db.ff_teams || []).find(t => (t.teamCode || '').toUpperCase() === teamCode.toUpperCase());
    if (!team) return res.status(404).json({ success: false, error: 'Invalid Team Code! Please verify with your Captain.' });

    if (team.members.some(m => m.uid === uid)) {
      return res.status(400).json({ success: false, error: 'You are already in this team!' });
    }

    if (team.members.length >= team.maxMembers) {
      return res.status(400).json({ success: false, error: 'This squad is already full!' });
    }

    const tourn = (db.ff_tournaments || []).find(t => t.id === team.tournamentId);
    const entryFee = Number(tourn ? (tourn.entryCoins || tourn.entryFeeCoins || 0) : 0);

    const user = db.users[uid];
    if (!user || (user.adCoins || 0) < entryFee) {
      return res.status(400).json({ success: false, error: `You need ${entryFee} Coins to join this squad.` });
    }

    user.adCoins -= entryFee;
    team.members.push({
      uid,
      inGameName,
      inGameId: inGameId || user.inGameId || '',
      isCaptain: false,
      joinedAt: new Date().toISOString()
    });

    // If squad is now full, register entire squad into tournament slot
    let isFullyLocked = false;
    if (team.members.length === team.maxMembers && tourn) {
      team.isLocked = true;
      isFullyLocked = true;
      const group = tourn.groups[0] || { participants: [], maxSlots: 8 };
      team.members.forEach(m => {
        const slotNo = (group.participants.length || 0) + 1;
        group.participants.push({
          uid: m.uid,
          inGameName: m.inGameName,
          inGameId: m.inGameId,
          slotNo,
          teamCode: team.teamCode,
          teamName: team.teamName,
          registeredAt: new Date().toISOString()
        });
      });
      group.filledSlots = group.participants.length;
      tourn.filledSlots = (tourn.filledSlots || 0) + team.members.length;
      console.log(`[TEAM COMPLETE] Squad ${team.teamName} locked into tournament ${tourn.id}!`);
    }

    saveDB();
    res.json({
      success: true,
      message: isFullyLocked ? `All teammates joined! Squad "${team.teamName}" is locked into the tournament!` : `Joined "${team.teamName}"! Waiting for ${team.maxMembers - team.members.length} more player(s).`,
      team,
      isFullyLocked,
      remainingCoins: user.adCoins
    });
  });

  // ── 5. ROOM CREDENTIALS REVEAL (INTERSTITIAL BARRIER & 15-MIN RULE) ─────────
  app.get('/api/ff/room-credentials/:tournamentId/:groupId', (req, res) => {
    const { tournamentId, groupId } = req.params;
    const { uid } = req.query;

    const tourn = (db.ff_tournaments || []).find(t => t.id === tournamentId);
    if (!tourn) return res.status(404).json({ success: false, error: 'Tournament not found' });

    const group = (tourn.groups || []).find(g => g.groupId === groupId);
    if (!group) return res.status(404).json({ success: false, error: 'Group not found' });

    // Verify requesting player is registered in this group
    if (uid) {
      const isRegistered = (group.participants || []).some(p => p.uid === uid);
      if (!isRegistered) {
        return res.status(403).json({ success: false, error: 'Access denied: You are not registered for this group!' });
      }
    }

    if (!group.isCredentialsPublished || !group.roomId) {
      return res.json({
        success: true,
        isPublished: false,
        message: 'Room ID & Password will be published 15 minutes before match kickoff!'
      });
    }

    res.json({
      success: true,
      isPublished: true,
      roomId: group.roomId,
      roomPassword: group.roomPassword,
      matchTime: tourn.matchTimeText || tourn.scheduledTime,
      instructions: 'Open Free Fire -> Custom -> Search Room ID -> Enter Password -> Join your assigned slot!'
    });
  });

  // ── 6. WATCH AD TO EARN COINS (DYNAMIC ADMIN RATE) ─────────────────────────
  app.post('/api/ff/watch-ad-coin', (req, res) => {
    const { uid } = req.body;
    if (!uid) return res.status(400).json({ success: false, error: 'UID required.' });

    if (!db.users[uid]) {
      db.users[uid] = { uid, displayName: 'Player', adCoins: 0, totalAdsWatched: 0 };
    }
    const user = db.users[uid];
    const coinReward = Number(db.config.coinEconomy.adCoinReward || 10);

    user.adCoins = (user.adCoins || 0) + coinReward;
    user.totalAdsWatched = (user.totalAdsWatched || 0) + 1;

    saveDB();
    console.log(`[WATCH AD REWARD] User ${uid} watched ad. Rewarded +${coinReward} Coins. Total: ${user.adCoins}`);

    res.json({
      success: true,
      coinsEarned: coinReward,
      totalCoins: user.adCoins,
      message: `You earned ${coinReward} Free Fire Coins!`
    });
  });

  // ── 7. DAILY CHECK-IN STREAK (DAY 1 - 7 REWARDS) ───────────────────────────
  app.post('/api/ff/daily-checkin', (req, res) => {
    const { uid } = req.body;
    if (!uid) return res.status(400).json({ success: false, error: 'UID required.' });

    if (!db.users[uid]) db.users[uid] = { uid, displayName: 'Player', adCoins: 0 };
    const user = db.users[uid];

    const todayStr = new Date().toLocaleDateString('en-IN');
    if (user.lastCheckInDate === todayStr) {
      return res.status(400).json({
        success: false,
        error: 'Already claimed today! Come back tomorrow for the next streak reward.'
      });
    }

    let streak = (user.streakDays || 0) + 1;
    if (streak > 7) streak = 1;

    // Day 1: 5, Day 2: 10, Day 3: 15, Day 4: 20, Day 5: 25, Day 6: 30, Day 7: 50
    const rewardsMap = { 1: 5, 2: 10, 3: 15, 4: 20, 5: 25, 6: 30, 7: 50 };
    const coinsWon = rewardsMap[streak] || 10;

    user.streakDays = streak;
    user.lastCheckInDate = todayStr;
    user.adCoins = (user.adCoins || 0) + coinsWon;

    saveDB();
    console.log(`[DAILY CHECK-IN] User ${uid} completed Day ${streak} streak: +${coinsWon} Coins.`);

    res.json({
      success: true,
      dayNumber: streak,
      coinsAwarded: coinsWon,
      totalCoins: user.adCoins,
      isJackpot: streak === 7,
      message: streak === 7 ? '🎉 JACKPOT! 50 Coins awarded for 7-Day Streak!' : `Day ${streak} claimed! +${coinsWon} Coins added.`
    });
  });

  // ── 8. LIVE WORLD CHAT (PINNED ANNOUNCEMENT + BAN / DELETE MODERATION) ──
  app.get('/api/ff/chat', (req, res) => {
    res.json({
      success: true,
      messages: (db.ff_chat || []).slice(-150),
      pinned: db.pinnedChatNotice || { text: '🔥 Booyah Rewards में आपका स्वागत है! फेयर प्ले रखें और रूम आईडी टाइम पर चेक करें।', enabled: true }
    });
  });

  app.get('/api/ff/chat/pinned', (req, res) => {
    res.json({
      success: true,
      pinned: db.pinnedChatNotice || { text: '', enabled: false }
    });
  });

  app.post('/api/admin/ff/chat/pinned', (req, res) => {
    const { text, enabled } = req.body;
    db.pinnedChatNotice = {
      text: (text || '').trim(),
      enabled: enabled !== false,
      updatedAt: new Date().toISOString()
    };
    saveDB();
    res.json({ success: true, message: 'वर्ल्ड चैट पिन नोटिस अपडेट हो गया!', pinned: db.pinnedChatNotice });
  });

  app.post('/api/admin/ff/chat/delete', (req, res) => {
    const { msgId } = req.body;
    if (!msgId) return res.status(400).json({ success: false, error: 'Message ID required' });
    if (!db.ff_chat) db.ff_chat = [];
    db.ff_chat = db.ff_chat.filter(m => m.id !== msgId);
    saveDB();
    res.json({ success: true, message: 'मैसेज डिलीट कर दिया गया!' });
  });

  app.post('/api/admin/ff/chat/ban-user', (req, res) => {
    const { uid } = req.body;
    if (!uid) return res.status(400).json({ success: false, error: 'User ID required' });
    if (!db.bannedChatUsers) db.bannedChatUsers = [];
    if (!db.bannedChatUsers.includes(uid)) {
      db.bannedChatUsers.push(uid);
      saveDB();
    }
    res.json({ success: true, message: `User ${uid} को चैट से बैन कर दिया गया!` });
  });

  app.post('/api/admin/ff/chat/unban-user', (req, res) => {
    const { uid } = req.body;
    if (!uid) return res.status(400).json({ success: false, error: 'User ID required' });
    if (!db.bannedChatUsers) db.bannedChatUsers = [];
    db.bannedChatUsers = db.bannedChatUsers.filter(u => u !== uid);
    saveDB();
    res.json({ success: true, message: `User ${uid} को अनबैन कर दिया गया!` });
  });

  const lastChatTime = {};
  app.post('/api/ff/chat/send', (req, res) => {
    const { uid, senderName, text } = req.body;
    if (!uid || !text || !text.trim()) {
      return res.status(400).json({ success: false, error: 'Message text required.' });
    }

    // Check if user is banned by admin
    if (db.bannedChatUsers && db.bannedChatUsers.includes(uid)) {
      return res.status(403).json({ success: false, error: '🚫 आपको एडमिन द्वारा वर्ल्ड चैट से बैन किया गया है।' });
    }

    // 5-second anti-spam rate limit
    const now = Date.now();
    if (lastChatTime[uid] && (now - lastChatTime[uid] < 5000)) {
      return res.status(429).json({ success: false, error: 'कृपया अगला मैसेज भेजने से पहले 5 सेकंड रुकें!' });
    }
    lastChatTime[uid] = now;

    // Clean profanity
    const cleanText = text.replace(/(madarchod|bhenchod|chutiya|gandu|randi)/gi, '***');

    const chatMsg = {
      id: `msg_${Date.now()}_${Math.random().toString(36).substring(7)}`,
      uid,
      senderName: senderName || 'Gamer',
      text: cleanText.trim(),
      timestamp: new Date().toISOString()
    };

    if (!db.ff_chat) db.ff_chat = [];
    db.ff_chat.push(chatMsg);
    if (db.ff_chat.length > 200) db.ff_chat = db.ff_chat.slice(-200);

    saveDB();
    res.json({ success: true, message: chatMsg });
  });

  // ── 9. 100% IN-APP CUSTOMER SUPPORT DESK ───────────────────────────────────
  app.post('/api/support/ticket', (req, res) => {
    const { uid, userName, category, subject, message } = req.body;
    if (!uid || !message) {
      return res.status(400).json({ success: false, error: 'UID and message are required.' });
    }

    if (!db.ff_support_tickets) db.ff_support_tickets = [];

    const ticketId = `TCK-${Date.now().toString().slice(-6)}`;
    const newTicket = {
      ticketId,
      uid,
      userName: userName || 'Player',
      category: category || 'General Help',
      subject: subject || 'Support Request',
      status: 'OPEN', // OPEN | REPLIED | RESOLVED
      messages: [
        {
          sender: 'user',
          text: message.trim(),
          time: new Date().toISOString()
        }
      ],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    db.ff_support_tickets.unshift(newTicket);
    saveDB();

    console.log(`[SUPPORT TICKET] New ticket ${ticketId} from ${userName} (${uid})`);
    res.json({
      success: true,
      message: 'Support ticket submitted successfully! Admin will reply here shortly.',
      ticket: newTicket
    });
  });

  app.get('/api/support/user/:uid', (req, res) => {
    const { uid } = req.params;
    const tickets = (db.ff_support_tickets || []).filter(t => t.uid === uid);
    res.json({ success: true, tickets });
  });

  // ── 10. ADMIN CONTROLS: CREATE TOURNAMENT, PUBLISH ROOM, AUTO-PAYOUT ────────
  app.post('/api/admin/ff/create-tournament', (req, res) => {
    const {
      title,
      category,
      mode,
      teamFormat,
      map,
      bannerUrl,
      entryFeeCoins,
      totalSlots,
      matchTimeText,
      scheduledTime,
      firstPlace,
      secondPlace,
      thirdPlace,
      perKill,
      isMega
    } = req.body;

    if (!title || !mode) {
      return res.status(400).json({ success: false, error: 'Title and Mode are required.' });
    }

    const tId = `FF-${(category || 'BR').toUpperCase()}-${Date.now().toString().slice(-6)}`;
    const slots = Number(totalSlots) || (mode.includes('Squad') ? 8 : (mode.includes('1v1') ? 2 : 48));

    const newTourn = {
      id: tId,
      title,
      category: category || 'BR',
      mode,
      teamFormat: teamFormat || (mode.includes('Squad') ? 'squad' : (mode.includes('Duo') ? 'duo' : 'solo')),
      map: map || 'Bermuda',
      bannerUrl: bannerUrl || 'https://vps.swgayanbhumi.in/uploads/br_banner.png',
      entryFeeCoins: Number(entryFeeCoins) || 20,
      totalSlots: slots,
      filledSlots: 0,
      status: 'OPEN',
      scheduleType: scheduledTime ? 'scheduled' : 'dynamic',
      matchTimeText: matchTimeText || 'Starts when Slots Full',
      scheduledTime: scheduledTime || new Date(Date.now() + 3600000).toISOString(),
      prizePool: {
        totalCoins: (Number(firstPlace) || 0) + (Number(secondPlace) || 0) + (Number(thirdPlace) || 0),
        firstPlace: Number(firstPlace) || 200,
        secondPlace: Number(secondPlace) || 100,
        thirdPlace: Number(thirdPlace) || 50,
        perKill: Number(perKill) || 0
      },
      roundNumber: 1,
      isMega: !!isMega,
      groups: [
        {
          groupId: `grp_${tId}_A`,
          groupName: 'Group A',
          maxSlots: isMega ? 48 : slots,
          filledSlots: 0,
          roomId: '',
          roomPassword: '',
          isCredentialsPublished: false,
          publishedAt: null,
          participants: []
        }
      ],
      createdAt: new Date().toISOString()
    };

    if (!db.ff_tournaments) db.ff_tournaments = [];
    db.ff_tournaments.unshift(newTourn);
    saveDB();

    console.log(`[ADMIN CREATED TOURNAMENT] ${newTourn.title} (ID: ${tId})`);
    res.json({ success: true, tournament: newTourn });
  });

  // ── ⏰ ADMIN: UPDATE MATCH TIME & SCHEDULE MODE (FIXED OR DYNAMIC) ────────
  app.post('/api/admin/ff/update-time', (req, res) => {
    const { tournamentId, scheduleType, matchTimeText, scheduledTime } = req.body;
    if (!tournamentId) return res.status(400).json({ success: false, error: 'Tournament ID is required.' });

    const tourn = (db.ff_tournaments || []).find(t => t.id === tournamentId);
    if (!tourn) return res.status(404).json({ success: false, error: 'Tournament not found.' });

    tourn.scheduleType = scheduleType || 'scheduled';
    tourn.matchTimeText = matchTimeText || 'Live Soon';
    if (scheduledTime) tourn.scheduledTime = scheduledTime;

    saveDB();
    console.log(`[ADMIN UPDATED TIME] ${tourn.title} -> Type: ${tourn.scheduleType}, Text: ${tourn.matchTimeText}, Scheduled: ${tourn.scheduledTime}`);

    res.json({
      success: true,
      message: `Match time updated successfully to "${tourn.matchTimeText}"!`,
      tournament: tourn
    });
  });

  // ── 📲 FCM TOKEN REGISTRATION & PUSH NOTIFICATIONS ─────────────────────────
  app.post('/api/user/fcm-token', (req, res) => {
    const { uid, token } = req.body;
    if (!uid || !token) return res.status(400).json({ success: false, error: 'UID and token required' });
    if (!db.fcm_tokens) db.fcm_tokens = {};
    db.fcm_tokens[uid] = { token, updatedAt: new Date().toISOString() };
    saveDB();
    res.json({ success: true, message: 'FCM Token registered' });
  });

  app.get('/api/notifications', (req, res) => {
    res.json({
      success: true,
      notifications: db.ff_notifications || []
    });
  });

  app.post('/api/admin/broadcast-notification', (req, res) => {
    const { title, message, type, tournamentId } = req.body;
    if (!title || !message) return res.status(400).json({ success: false, error: 'Title and message required.' });

    if (!db.ff_notifications) db.ff_notifications = [];
    const newNotif = {
      id: `notif_${Date.now()}`,
      title,
      message,
      type: type || 'ADMIN_BROADCAST',
      tournamentId: tournamentId || null,
      createdAt: new Date().toISOString()
    };
    db.ff_notifications.unshift(newNotif);
    if (db.ff_notifications.length > 50) db.ff_notifications = db.ff_notifications.slice(0, 50);

    saveDB();
    console.log(`[ADMIN BROADCAST] ${title} - ${message}`);

    const recipientCount = Object.keys(db.fcm_tokens || {}).length;
    res.json({
      success: true,
      message: `Push notification broadcasted successfully to ${recipientCount} registered devices!`,
      notification: newNotif,
      recipients: recipientCount
    });
  });

  // Admin: Publish Room ID & Password
  app.post('/api/admin/ff/publish-room', (req, res) => {
    const { tournamentId, groupId, roomId, roomPassword } = req.body;
    if (!tournamentId || !roomId || !roomPassword) {
      return res.status(400).json({ success: false, error: 'Tournament ID, Room ID, and Password required.' });
    }

    const tourn = (db.ff_tournaments || []).find(t => t.id === tournamentId);
    if (!tourn) return res.status(404).json({ success: false, error: 'Tournament not found' });

    let group = (tourn.groups || []).find(g => g.groupId === groupId);
    if (!group && tourn.groups && tourn.groups.length > 0) {
      group = tourn.groups[0];
    }

    if (!group) return res.status(404).json({ success: false, error: 'Group not found' });

    group.roomId = String(roomId).trim();
    group.roomPassword = String(roomPassword).trim();
    group.isCredentialsPublished = true;
    group.publishedAt = new Date().toISOString();
    tourn.status = 'LIVE';

    saveDB();
    console.log(`[ADMIN PUBLISHED ROOM] ${tourn.title} [${group.groupName}] -> Room: ${roomId}, Pass: ${roomPassword}`);

    res.json({
      success: true,
      message: `Room credentials published successfully for ${group.groupName}! All ${group.participants.length} players can now unlock in app.`
    });
  });

  // Admin: Spectator Winner Declaration & Automatic Prize Split
  app.post('/api/admin/ff/declare-winners', (req, res) => {
    const { tournamentId, groupId, winnerType, winnerUid, winningTeamCode, killsData } = req.body;
    // killsData = [{ uid: 'user_1', kills: 4 }, { uid: 'user_2', kills: 2 }]

    const tourn = (db.ff_tournaments || []).find(t => t.id === tournamentId);
    if (!tourn) return res.status(404).json({ success: false, error: 'Tournament not found' });

    const group = (tourn.groups || []).find(g => g.groupId === groupId) || (tourn.groups ? tourn.groups[0] : null);
    const prize = tourn.prizePool || { firstPlace: 200, perKill: 5 };

    let winnersCredited = [];

    // ── CASE A: SOLO / 1v1 WINNER ──
    if (winnerType === 'player' && winnerUid) {
      if (db.users[winnerUid]) {
        const u = db.users[winnerUid];
        u.winningCoins = (u.winningCoins || 0) + (prize.firstPlace || 200);
        u.totalWins = (u.totalWins || 0) + 1;
        winnersCredited.push({ uid: winnerUid, name: u.displayName, amount: prize.firstPlace });
      }
    }

    // ── CASE B: SQUAD / DUO TEAM WINNER (AUTOMATIC 100% EQUAL PRIZE SPLIT) ──
    else if (winnerType === 'team' && winningTeamCode) {
      const team = (db.ff_teams || []).find(t => t.teamCode === winningTeamCode);
      if (team && team.members && team.members.length > 0) {
        const splitAmount = Math.floor((prize.firstPlace || 200) / team.members.length);
        team.members.forEach(m => {
          if (db.users[m.uid]) {
            const u = db.users[m.uid];
            u.winningCoins = (u.winningCoins || 0) + splitAmount;
            u.totalWins = (u.totalWins || 0) + 1;
            winnersCredited.push({ uid: m.uid, name: u.displayName, amount: splitAmount });
          }
        });
        console.log(`[TEAM PRIZE SPLIT] Team ${team.teamName} won ${prize.firstPlace} Winning Coins. Split ${splitAmount} Coins each across ${team.members.length} members!`);
      }
    }

    // ── CASE C: PER-KILL REWARDS ──
    if (Array.isArray(killsData) && prize.perKill > 0) {
      killsData.forEach(k => {
        if (k.uid && k.kills > 0 && db.users[k.uid]) {
          const killReward = k.kills * prize.perKill;
          const u = db.users[k.uid];
          u.winningCoins = (u.winningCoins || 0) + killReward;
          u.totalKills = (u.totalKills || 0) + k.kills;
        }
      });
    }

    tourn.status = 'ENDED';
    saveDB();

    res.json({
      success: true,
      message: `Winners declared! All prizes credited automatically to players' wallets.`,
      winnersCredited
    });
  });

  // Admin: Support Desk - View Tickets & Reply
  app.get('/api/admin/support/tickets', (req, res) => {
    res.json({
      success: true,
      tickets: db.ff_support_tickets || []
    });
  });

  app.post('/api/admin/support/reply', (req, res) => {
    const { ticketId, replyText } = req.body;
    if (!ticketId || !replyText) {
      return res.status(400).json({ success: false, error: 'Ticket ID and reply text required.' });
    }

    const ticket = (db.ff_support_tickets || []).find(t => t.ticketId === ticketId);
    if (!ticket) return res.status(404).json({ success: false, error: 'Ticket not found.' });

    ticket.messages.push({
      sender: 'admin',
      text: replyText.trim(),
      time: new Date().toISOString()
    });
    ticket.status = 'REPLIED';
    ticket.updatedAt = new Date().toISOString();

    saveDB();
    console.log(`[SUPPORT REPLY] Admin replied to ticket ${ticketId}`);

    res.json({
      success: true,
      message: 'Reply sent to user! User will see this in their app instantly.',
      ticket
    });
  });

  // Admin: Update Coin Economy & Social URLs
  app.post('/api/admin/config/economy-social', (req, res) => {
    const { coinEconomy, socialLinks, branding } = req.body;
    if (coinEconomy) db.config.coinEconomy = { ...db.config.coinEconomy, ...coinEconomy };
    if (socialLinks) db.config.socialLinks = { ...db.config.socialLinks, ...socialLinks };
    if (branding) db.config.branding = { ...db.config.branding, ...branding };

    saveDB();
    res.json({
      success: true,
      message: 'Configuration updated successfully!',
      config: {
        coinEconomy: db.config.coinEconomy,
        socialLinks: db.config.socialLinks,
        branding: db.config.branding
      }
    });
  });

  console.log('⚡ [FF ENGINE] Free Fire India Tournament Engine Hooked & Active!');
};
