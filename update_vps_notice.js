const fs = require('fs');
const path = require('path');

const serverFile = '/home/ubuntu/arena-backend/server.js';
const indexFile = '/home/ubuntu/arena-backend/public/index.html';

// 1. Update server.js
let serverCode = fs.readFileSync(serverFile, 'utf8');

if (!serverCode.includes('/api/admin/update-notice')) {
  const target = "app.post('/api/admin/set-prize-pool'";
  const newEndpoint = `// Admin: Update Tournament Notice Live for App
app.post('/api/admin/update-notice', (req, res) => {
  const { notice } = req.body;
  if (!db.config) db.config = {};
  db.config.notice = notice !== undefined ? String(notice).trim() : '';
  saveDB();
  console.log('[ADMIN] Tournament notice updated:', db.config.notice);
  res.json({
    success: true,
    message: 'Tournament notice updated successfully!',
    notice: db.config.notice
  });
});

app.post('/api/admin/set-prize-pool'`;
  serverCode = serverCode.replace(target, newEndpoint);
  fs.writeFileSync(serverFile, serverCode, 'utf8');
  console.log('Added /api/admin/update-notice to server.js');
} else {
  console.log('/api/admin/update-notice already present in server.js');
}

// 2. Update public/index.html
let html = fs.readFileSync(indexFile, 'utf8');

if (!html.includes('noticeInput')) {
  const noticeCardHtml = `
  <!-- 📢 TOURNAMENT NOTICE BOARD MANAGER -->
  <div class="card" style="border: 2px solid var(--gold); background: linear-gradient(180deg, #1E293B 0%, #172338 100%); box-shadow: 0 0 20px rgba(255, 185, 0, 0.18);">
    <div class="card-title">
      <span>📢 TOURNAMENT NOTICE BOARD (LIVE APP ANNOUNCEMENT)</span>
      <span class="badge-live" id="noticeLiveBadge">ACTIVE IN APP</span>
    </div>
    <p style="color: var(--text-muted); font-size: 13px; margin-bottom: 12px;">
      Aap yahan se jo bhi notice likhenge, wo sabhi users ko app ke <b>Leaderboard</b> par sabse upar glowing notice board me turant dikhega!
    </p>
    <div class="form-group">
      <label>Currently Live Notice on App:</label>
      <div id="currentNoticeDisplay" style="background: var(--bg-dark); padding: 12px 14px; border-radius: 8px; border: 1px solid var(--gold); color: #fff; font-size: 13.5px; margin-bottom: 12px; line-height: 1.4;">
        Loading active notice...
      </div>
    </div>
    <div class="form-group">
      <label>Enter New Notice / Announcement:</label>
      <textarea id="noticeInput" rows="3" placeholder="Type notice to publish to all users..." style="font-size: 13px;"></textarea>
    </div>
    <div style="display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 14px;">
      <button type="button" class="btn btn-info" style="font-size: 11px; padding: 5px 12px;" onclick="setNoticePreset('📢 Season 1 LIVE! Top 10 skill players win Google Play redeem codes on Sunday! Payouts on 25th.')">Preset: Season 1 Live 🏆</button>
      <button type="button" class="btn btn-info" style="font-size: 11px; padding: 5px 12px;" onclick="setNoticePreset('✅ All 25th Monthly Payouts & Redeem Codes have been disbursed directly to winner WhatsApp/Emails!')">Preset: Payouts Sent ✅</button>
      <button type="button" class="btn btn-info" style="font-size: 11px; padding: 5px 12px;" onclick="setNoticePreset('🔥 Mega Weekend Contest! Earn 2X Points on Fruit Slash & Knife Hit today!')">Preset: 2X Points 🔥</button>
      <button type="button" class="btn btn-info" style="font-size: 11px; padding: 5px 12px;" onclick="setNoticePreset('⚠️ Maintenance Alert: Scheduled server maintenance tonight from 12:00 AM to 1:00 AM. Scores are safe.')">Preset: Maintenance ⚠️</button>
    </div>
    <button class="btn" style="width: 100%; padding: 12px; font-size: 15px; letter-spacing: 1px;" onclick="updateNotice()">🚀 PUBLISH NOTICE TO LIVE APP NOW</button>
  </div>
`;

  html = html.replace('<!-- Weekly Prize Pool Controller Card -->', noticeCardHtml + '\n  <!-- Weekly Prize Pool Controller Card -->');

  const jsCode = `
    function setNoticePreset(msg) {
      document.getElementById('noticeInput').value = msg;
    }

    async function updateNotice() {
      const notice = document.getElementById('noticeInput').value.trim();
      if (!notice) return alert('Please enter notice text to publish.');

      try {
        const res = await fetch('/api/admin/update-notice', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ notice })
        });
        const data = await res.json();
        if (data.success) {
          alert('✅ Notice published live to app successfully!');
          document.getElementById('currentNoticeDisplay').textContent = data.notice;
          document.getElementById('noticeInput').value = '';
          fetchStats();
        } else {
          alert('Error: ' + (data.error || 'Failed to update notice'));
        }
      } catch (e) {
        alert('Server error: ' + e.message);
      }
    }
`;
  html = html.replace('async function updatePrizePool() {', jsCode + '\n    async function updatePrizePool() {');

  html = html.replace(
    "document.getElementById('currentPoolBadge').textContent = (data.config.prizePool || '₹5,000') + ' Active';",
    "document.getElementById('currentPoolBadge').textContent = (data.config.prizePool || '₹5,000') + ' Active';\n          if (document.getElementById('currentNoticeDisplay') && data.config) { document.getElementById('currentNoticeDisplay').textContent = data.config.notice || 'No notice currently set'; }"
  );

  fs.writeFileSync(indexFile, html, 'utf8');
  console.log('Added Notice Board Card and JS to public/index.html');
} else {
  console.log('noticeInput already present in index.html');
}
