const fs = require('fs');
const https = require('https');

const filePath = 'C:/Users/Admin/Desktop/BR_Solo_10_Coins_Tournament.jpg';
if (!fs.existsSync(filePath)) {
  console.error('File not found:', filePath);
  process.exit(1);
}

const fileData = fs.readFileSync(filePath);
const boundary = '----WebKitFormBoundary' + Date.now().toString(16);

const pre = Buffer.from(
  '--' + boundary + '\r\n' +
  'Content-Disposition: form-data; name="image"; filename="br_10coins_tournament.jpg"\r\n' +
  'Content-Type: image/jpeg\r\n\r\n'
);
const post = Buffer.from('\r\n--' + boundary + '--\r\n');
const payload = Buffer.concat([pre, fileData, post]);

const req = https.request({
  hostname: 'vps.swgayanbhumi.in',
  path: '/api/upload',
  method: 'POST',
  headers: {
    'Content-Type': 'multipart/form-data; boundary=' + boundary,
    'Content-Length': payload.length
  }
}, res => {
  let body = '';
  res.on('data', d => body += d);
  res.on('end', () => {
    console.log('Upload response:', body);
    try {
      const data = JSON.parse(body);
      const bannerUrl = (data.fileUrl || data.imageUrl || 'https://i.ibb.co/PvV4vz0X/brhomescreen.png').replace('http://', 'https://');
      console.log('Banner URL uploaded:', bannerUrl);

      // 1. Add Promo Banner to Carousel
      const bannerPayload = JSON.stringify({
        id: 'banner_mega_br_400',
        title: '🔥 MEGA BR SOLO - 400 WINCOINS PRIZE POOL',
        imageUrl: bannerUrl,
        clickUrl: '',
        isActive: true
      });
      const bReq = https.request({
        hostname: 'vps.swgayanbhumi.in',
        path: '/api/banners',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(bannerPayload)
        }
      }, bRes => {
        let bBody = '';
        bRes.on('data', d => bBody += d);
        bRes.on('end', () => console.log('Banner added on VPS:', bBody));
      });
      bReq.write(bannerPayload);
      bReq.end();

      // 2. Schedule Date: Tomorrow 12 Oct 2026, 8:00 PM IST
      const scheduledDate = new Date();
      scheduledDate.setDate(scheduledDate.getDate() + 1);
      scheduledDate.setHours(20, 0, 0, 0);

      // 3. Create the 48-slot match
      const matchObj = {
        id: 'match_br_400_' + Date.now(),
        title: '🔥 Mega BR Solo Pro (400 WinCoins)',
        gameType: 'freeFire',
        mode: 'br',
        teamType: 'solo',
        matchFormat: 'solo',
        mapType: 'bermuda',
        map: 'bermuda',
        matchType: 'free',
        entryFeeType: 'adCoins',
        entryFee: 10,
        maxSlots: 48,
        filledSlots: 0,
        status: 'upcoming',
        scheduledTime: scheduledDate.toISOString(),
        bannerUrl: bannerUrl,
        prizePool: {
          totalPool: 400,
          firstPlace: 200,
          secondPlace: 100,
          thirdPlace: 50,
          perKill: 5,
          isCashPrize: false
        },
        credentials: {
          roomId: '',
          roomPassword: ''
        },
        participants: [],
        registeredTeams: [],
        rules: [
          'Entry: 10 Ad Coins required to join.',
          'Format: Full Map Bermuda Solo (48 Players).',
          '1st Place (Booyah 🏆): 200 WinCoins',
          '2nd Place (🥈): 100 WinCoins',
          '3rd Place (🥉): 50 WinCoins',
          'Room ID & Password will be published 10 minutes before kickoff.'
        ]
      };

      const mPayload = JSON.stringify(matchObj);
      const mReq = https.request({
        hostname: 'vps.swgayanbhumi.in',
        path: '/api/matches',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(mPayload)
        }
      }, mRes => {
        let mBody = '';
        mRes.on('data', d => mBody += d);
        mRes.on('end', () => console.log('Match created successfully on VPS:', mBody));
      });
      mReq.write(mPayload);
      mReq.end();

    } catch (e) {
      console.error(e);
    }
  });
});

req.on('error', console.error);
req.write(payload);
req.end();
