/**
 * Firestore Seed Script
 * 
 * This script populates Firestore with initial seed data for the Easy Mode app.
 * 
 * Usage:
 *   1. Set up Firebase Admin SDK credentials
 *   2. Run: node seed_firestore.js
 * 
 * Prerequisites:
 *   - Node.js 18+
 *   - Firebase Admin SDK
 *   - Service account key file (serviceAccountKey.json)
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin
// Option 1: Use service account key file
// const serviceAccount = require('./serviceAccountKey.json');
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount)
// });

// Option 2: Use default credentials (for Cloud Functions or local emulator)
admin.initializeApp();

const db = admin.firestore();

// Load seed data
const seedDataPath = path.join(__dirname, 'seed_data.json');
const seedData = JSON.parse(fs.readFileSync(seedDataPath, 'utf8'));

async function seedCollection(collectionName, documents) {
  console.log(`Seeding ${collectionName}...`);
  const batch = db.batch();
  
  for (const doc of documents) {
    const docRef = db.collection(collectionName).doc(doc.id);
    batch.set(docRef, doc);
  }
  
  await batch.commit();
  console.log(`  ✓ Seeded ${documents.length} documents to ${collectionName}`);
}

async function seedFirestore() {
  console.log('Starting Firestore seed...\n');
  
  try {
    // Seed scripts
    await seedCollection('scripts', seedData.scripts);
    
    // Seed tasks
    await seedCollection('tasks', seedData.tasks);
    
    // Seed rituals
    await seedCollection('rituals', seedData.rituals);
    
    // Seed badges
    await seedCollection('badges', seedData.badges);
    
    console.log('\n✓ Firestore seed complete!');
  } catch (error) {
    console.error('\n✗ Error seeding Firestore:', error);
    process.exit(1);
  }
}

async function clearCollection(collectionName) {
  console.log(`Clearing ${collectionName}...`);
  const snapshot = await db.collection(collectionName).get();
  
  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.delete(doc.ref);
  });
  
  await batch.commit();
  console.log(`  ✓ Cleared ${snapshot.size} documents from ${collectionName}`);
}

async function clearAndSeed() {
  console.log('Clearing existing data...\n');
  
  await clearCollection('scripts');
  await clearCollection('tasks');
  await clearCollection('rituals');
  await clearCollection('badges');
  
  console.log('');
  await seedFirestore();
}

// Check command line args
const args = process.argv.slice(2);
if (args.includes('--clear')) {
  clearAndSeed();
} else {
  seedFirestore();
}
