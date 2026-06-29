function getFirebaseClientConfig() {
  return {
    apiKey: process.env.FIREBASE_API_KEY || 'AIzaSyBpfEezr2jddRgUs9_5_vMtg1jHeynqAVs',
    authDomain: process.env.FIREBASE_AUTH_DOMAIN || 'foodg-travel.firebaseapp.com',
    projectId: process.env.FIREBASE_PROJECT_ID || 'foodg-travel',
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET || 'foodg-travel.appspot.com',
    messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID || '272763763632',
    appId: process.env.FIREBASE_APP_ID || '1:272763763632:web:8338bc7ce331035b7af475',
  };
}

module.exports = { getFirebaseClientConfig };
