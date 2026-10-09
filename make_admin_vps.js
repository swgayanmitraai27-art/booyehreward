const fs = require('fs');
const file = '/home/ubuntu/booyah-backend/data/db.json';

try {
  const db = JSON.parse(fs.readFileSync(file, 'utf8'));
  const uid = 'stywvieND2f2PfbpMG2MvAC2Ook2';
  
  if (db.users[uid]) {
    db.users[uid].role = 'admin';
  } else {
    db.users[uid] = {
      uid: uid,
      displayName: 'Aditya Admin',
      email: 'swgayanbhumi@swgayanbhumi.in',
      role: 'admin',
      wallet: { adCoins: 100, rewardCoins: 100, depositCash: 500, winningCash: 500, bonusCash: 500 }
    };
  }
  
  fs.writeFileSync(file, JSON.stringify(db, null, 2), 'utf8');
  console.log('VPS Admin updated for UID:', uid, db.users[uid]);
} catch (e) {
  console.error(e);
}
