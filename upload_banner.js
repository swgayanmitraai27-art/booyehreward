const fs = require('fs');
const https = require('https');
const path = require('path');

const filePath = 'C:/Users/Admin/Desktop/App_Update_PlayStore_Banner.jpg';
if (!fs.existsSync(filePath)) {
  console.error('File not found:', filePath);
  process.exit(1);
}

const fileData = fs.readFileSync(filePath);
const boundary = '----WebKitFormBoundary' + Date.now().toString(16);

const pre = Buffer.from(
  '--' + boundary + '\r\n' +
  'Content-Disposition: form-data; name="image"; filename="update_banner.jpg"\r\n' +
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
    console.log('Upload response status:', res.statusCode);
    console.log('Upload response body:', body);
    try {
      const data = JSON.parse(body);
      if (data.success && data.imageUrl) {
        const newBanner = {
          id: 'banner_playstore_update_' + Date.now(),
          title: '⚡ NEW VERSION LIVE ON PLAY STORE',
          imageUrl: data.imageUrl,
          clickUrl: 'https://play.google.com/store/apps/details?id=com.swgayanbhumi.app',
          isActive: true
        };
        const bPayload = JSON.stringify(newBanner);
        const bReq = https.request({
          hostname: 'vps.swgayanbhumi.in',
          path: '/api/banners',
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(bPayload)
          }
        }, bRes => {
          let bBody = '';
          bRes.on('data', d => bBody += d);
          bRes.on('end', () => {
            console.log('Banner added successfully:', bBody);
          });
        });
        bReq.write(bPayload);
        bReq.end();
      }
    } catch (e) {
      console.error(e);
    }
  });
});

req.on('error', console.error);
req.write(payload);
req.end();
