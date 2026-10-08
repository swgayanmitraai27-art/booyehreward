#!/bin/bash
set -e

# Configure Nginx Reverse Proxy to Port 3000
cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

nginx -t
systemctl restart nginx

# Start Backend Server with PM2
cd /home/ubuntu/booyah-backend
pm2 delete booyah-api 2>/dev/null || true
pm2 start server.js --name booyah-api
pm2 save
pm2 startup systemd -u ubuntu --hp /home/ubuntu | bash 2>/dev/null || true

echo "SUCCESS: Booyah Backend is live on Port 80 & 3000"
