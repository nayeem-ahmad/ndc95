const admin = require('firebase-admin');
const serviceAccount = require('./functions/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function updateRole() {
  try {
    // Query for user with email nayeem.ahmad@gmail.com
    const usersRef = db.collection('users');
    const snapshot = await usersRef.where('email', '==', 'nayeem.ahmad@gmail.com').get();
    
    if (snapshot.empty) {
      console.log('No user found with email nayeem.ahmad@gmail.com');
      return;
    }
    
    // Update the role for all matching users
    const batch = db.batch();
    snapshot.forEach(doc => {
      console.log(`Updating user ${doc.id} - ${doc.data().email}`);
      batch.update(doc.ref, { role: 'superadmin' });
    });
    
    await batch.commit();
    console.log('✅ Successfully updated role to superadmin');
  } catch (error) {
    console.error('Error updating role:', error);
  }
  process.exit();
}

updateRole();
