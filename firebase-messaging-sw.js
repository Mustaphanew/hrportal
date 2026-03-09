importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAvcijqJR893sCTq3jy5QppK-iyEyq81PU',
  authDomain: 'hr-portal-8317c.firebaseapp.com',
  projectId: 'hr-portal-8317c',
  storageBucket: 'hr-portal-8317c.firebasestorage.app',
  messagingSenderId: '272357624227',
  appId: '1:272357624227:web:c00e72c2128359638c3216',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const data = payload.data || {};
  const notification = payload.notification || {};

  const title =
    data.title_en ||
    data.title ||
    notification.title ||
    'Notification';

  const body =
    data.body_en ||
    data.body ||
    notification.body ||
    '';

  const image = data.image || notification.image;
  const route = data.route || '';
  const url = data.url || '';

  self.registration.showNotification(title, {
    body,
    image,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: {
      route,
      url,
    },
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const data = event.notification.data || {};
  let targetUrl = self.location.origin + '/';

  if (data.url) {
    targetUrl = data.url;
  } else if (data.route) {
    targetUrl = data.route.startsWith('http')
      ? data.route
      : new URL(
          data.route.startsWith('/') ? data.route : `/${data.route}`,
          self.location.origin,
        ).href;
  }

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url === targetUrl && 'focus' in client) {
          return client.focus();
        }
      }

      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }

      return null;
    }),
  );
});
