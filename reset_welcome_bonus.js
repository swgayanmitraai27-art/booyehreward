const fs = require('fs');
const path = '/home/ubuntu/arena-backend/data/db.json';

try {
  const raw = fs.readFileSync(path, 'utf8');
  const db = JSON.parse(raw);

  if (db.config && db.config.coinEconomy) {
    db.config.coinEconomy.welcomeBonus = 0;
  }

  for (const uid in db.users) {
    const u = db.users[uid];
    u.adCoins = 0;
    u.winningCoins = 0;
    console.log(`Reset user ${uid}: adCoins = 0, winningCoins = 0`);
  }

  fs.writeFileSync(path, JSON.stringify(db, null, 2), 'utf8');
  console.log('Successfully updated db.json: welcomeBonus=0 and all user wallets set to 0!');
} catch (e) {
  console.error('Error updating db.json:', e);
  process.exit(1);
}
