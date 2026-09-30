importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// Initialize Firebase in Service Worker
firebase.initializeApp({
  apiKey: "AIzaSyCLTHMklWsgiydXuF3QssaR9XtHtHLjd_8",
  authDomain: "sw-gyanmitra-finall2-426-dcc41.firebaseapp.com",
  projectId: "sw-gyanmitra-finall2-426-dcc41",
  storageBucket: "sw-gyanmitra-finall2-426-dcc41.firebasestorage.app",
  messagingSenderId: "841226454678",
  appId: "1:841226454678:web:4d42dfa3dddb5714f2e4b7"
});

const messaging = firebase.messaging();

// Background message handler
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification?.title || payload.data?.title || 'Booyah Rewards Alert';
  const notificationOptions = {
    body: payload.notification?.body || payload.data?.body || 'Match updates and tournament lobby alerts.',
    icon: payload.notification?.image || 'https://booyehreward.vercel.app/booyah_logo.png',
    badge: 'https://booyehreward.vercel.app/booyah_logo.png',
    vibrate: [200, 100, 200],
    data: payload.data || {}
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Service Worker Notification Click
self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (var i = 0; i < clientList.length; i++) {
        var client = clientList[i];
        if (client.url && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
