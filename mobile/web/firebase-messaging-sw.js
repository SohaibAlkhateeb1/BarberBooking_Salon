importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyD4cpdjsvyDbuGymXUreJtM6xZ5RpbpaU8',
  authDomain: 'barber-booking-c5fd6.firebaseapp.com',
  projectId: 'barber-booking-c5fd6',
  storageBucket: 'barber-booking-c5fd6.firebasestorage.app',
  messagingSenderId: '886432509232',
  appId: '1:886432509232:web:FIXME_WEB_APP_ID',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'BarberBooking';
  const body = payload.notification?.body || '';
  const data = payload.data || {};

  self.registration.showNotification(title, {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: data,
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = event.notification.data?.url || '/';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      return clients.openWindow(url);
    })
  );
});
