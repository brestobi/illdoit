importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBosm04uU23ot8NO97StCsSZDvFL_iNIKI",
  appId: "1:797655594738:web:dbc3f944f236622b1dc26b",
  messagingSenderId: "797655594738",
  projectId: "illdoit-app",
  authDomain: "illdoit-app.firebaseapp.com",
  storageBucket: "illdoit-app.firebasestorage.app",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log(
    "[firebase-messaging-sw.js] Received background message ",
    payload
  );
  // Customize notification here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png",
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
