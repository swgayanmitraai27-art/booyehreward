const fs = require('fs');
const path = require('path');

const serverFile = '/home/ubuntu/booyah-backend/server.js';
let content = fs.readFileSync(serverFile, 'utf8');

// Replace upload URL generation to always return clean https://vps.swgayanbhumi.in/uploads/...
content = content.replace(
  /const fileUrl = [`'"].*[`'"];/g,
  "const fileUrl = 'https://vps.swgayanbhumi.in/uploads/' + req.file.filename;"
);

content = content.replace(
  /url: [`'"].*\/uploads\/.*[`'"]/g,
  "url: 'https://vps.swgayanbhumi.in/uploads/' + f"
);

// Add Free Matches if not present
const freeMatches = [
  {
    id: 'match_free_br_01',
    title: '🆓 Free Fire BR Solo (Ad Coins)',
    bannerUrl: 'https://i.ibb.co/PvV4vz0X/brhomescreen.png',
    gameType: 'freeFire',
    matchType: 'free',
    mode: 'br',
    teamType: 'solo',
    map: 'bermuda',
    entryFee: 5,
    prizePool: 50,
    firstPrize: 25,
    secondPrize: 15,
    thirdPrize: 10,
    fourthPrize: 0,
    fifthPrize: 0,
    perKill: 2,
    maxSlots: 48,
    filledSlots: 12,
    status: 'upcoming',
    scheduleTime: new Date(Date.now() + 3600000).toISOString(),
    participants: [],
    registeredTeams: [],
    isFull: false
  },
  {
    id: 'match_free_cs_01',
    title: '🆓 Free Fire CS 4v4 Squad (Ad Coins)',
    bannerUrl: 'https://i.ibb.co/S4qX9RW5/cshomescreen.png',
    gameType: 'freeFire',
    matchType: 'free',
    mode: 'cs',
    teamType: 'squad',
    map: 'bermuda',
    entryFee: 2,
    prizePool: 20,
    firstPrize: 20,
    secondPrize: 0,
    thirdPrize: 0,
    fourthPrize: 0,
    fifthPrize: 0,
    perKill: 0,
    maxSlots: 8,
    filledSlots: 4,
    status: 'upcoming',
    scheduleTime: new Date(Date.now() + 7200000).toISOString(),
    participants: [],
    registeredTeams: [],
    isFull: false
  },
  {
    id: 'match_free_lw_01',
    title: '🆓 Lone Wolf 1v1 Battle (Ad Coins)',
    bannerUrl: 'https://i.ibb.co/9ktcjYSX/lonewolfhomescreen.png',
    gameType: 'freeFire',
    matchType: 'free',
    mode: 'loneWolf',
    teamType: 'solo',
    map: 'ironCage',
    entryFee: 2,
    prizePool: 10,
    firstPrize: 10,
    secondPrize: 0,
    thirdPrize: 0,
    fourthPrize: 0,
    fifthPrize: 0,
    perKill: 0,
    maxSlots: 2,
    filledSlots: 1,
    status: 'upcoming',
    scheduleTime: new Date(Date.now() + 5400000).toISOString(),
    participants: [],
    registeredTeams: [],
    isFull: false
  }
];

fs.writeFileSync(serverFile, content, 'utf8');
console.log('Server updated successfully');
