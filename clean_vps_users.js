const fs = require('fs');
const file = '/home/ubuntu/booyah-backend/data/db.json';

try {
  const db = JSON.parse(fs.readFileSync(file, 'utf8'));
  const admins = {};
  
  if (db.users['VaIWQoaTJKSxEC39rCVXKZYmpa22']) {
    admins['VaIWQoaTJKSxEC39rCVXKZYmpa22'] = {
      ...db.users['VaIWQoaTJKSxEC39rCVXKZYmpa22'],
      role: 'admin'
    };
  } else {
    admins['VaIWQoaTJKSxEC39rCVXKZYmpa22'] = {
      uid: 'VaIWQoaTJKSxEC39rCVXKZYmpa22',
      displayName: 'ADITYA',
      email: 'swgayanbhumi@swgayanbhumi.in',
      role: 'admin',
      wallet: { adCoins: 0, rewardCoins: 0, depositCash: 0, winningCash: 0, bonusCash: 0 }
    };
  }

  if (db.users['IejDwJjjrnQZl6Fey430YFgtIiI3']) {
    admins['IejDwJjjrnQZl6Fey430YFgtIiI3'] = {
      ...db.users['IejDwJjjrnQZl6Fey430YFgtIiI3'],
      role: 'admin'
    };
  }

  db.users = admins;
  db.referrals = [];
  db.transactions = [];
  
  fs.writeFileSync(file, JSON.stringify(db, null, 2), 'utf8');
  console.log('VPS DB cleaned successfully. Users:', Object.keys(db.users));
} catch (e) {
  console.error(e);
}
