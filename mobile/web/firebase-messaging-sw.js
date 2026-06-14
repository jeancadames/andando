importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCwx1iAdA9HR7OtOeais-o7k4C4OLRMe0A',
  authDomain: 'andando-staging.firebaseapp.com',
  projectId: 'andando-staging',
  storageBucket: 'andando-staging.firebasestorage.app',
  messagingSenderId: '588961643605',
  appId: '1:588961643605:web:06f0a9aa0068ac18bae8dc',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Mensaje recibido en background:', payload);

  const notificationTitle = payload.notification?.title || 'AndanDO';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});