// Inspect, back up, wipe and seed Flexibleea data with the Admin SDK.
//
//   node demo-data.mjs inventory              read-only summary of what exists
//   node demo-data.mjs backup                 export Users + listings + reviews to ./backups/
//   node demo-data.mjs wipe --listings        delete every listing (+ reviews, PDFs)
//   node demo-data.mjs wipe --listings --profiles [--auth]
//                                             ...and member profiles (+ photos, sign-in accounts)
//   node demo-data.mjs seed                   create the demo freelancers in ../demo/
//   node demo-data.mjs unseed                 remove only the demo freelancers
//
// `wipe` always writes a backup first and asks you to type the project id.
// Admin accounts (custom claim admin: true) are never deleted.
// Credentials: same as set-admin.mjs (service-account.json or ADC).
import { randomUUID } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { createInterface } from 'node:readline/promises';
import { applicationDefault, cert, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

const PROJECT_ID = 'flexibleea-5b117';
const BUCKET = 'flexibleea-5b117.appspot.com';
const LISTINGS = 'Freelancer Expertise';
const USERS = 'Users';
const here = (p) => new URL(p, import.meta.url);
const keyPath = here('./service-account.json');

initializeApp({
  projectId: PROJECT_ID,
  storageBucket: BUCKET,
  credential: existsSync(keyPath)
    ? cert(JSON.parse(readFileSync(keyPath, 'utf8')))
    : applicationDefault(),
});

const db = getFirestore();
const auth = getAuth();
const bucket = getStorage().bucket();
const [command, ...flags] = process.argv.slice(2);
const has = (flag) => flags.includes(flag);

// ------------------------------------------------------------------ helpers

function serialise(value) {
  if (value instanceof Timestamp) return { __timestamp: value.toDate().toISOString() };
  if (Array.isArray(value)) return value.map(serialise);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, serialise(v)]));
  }
  return value;
}

async function adminUids() {
  const uids = new Set();
  let pageToken;
  do {
    const page = await auth.listUsers(1000, pageToken);
    for (const u of page.users) if (u.customClaims?.admin === true) uids.add(u.uid);
    pageToken = page.pageToken;
  } while (pageToken);
  return uids;
}

async function deleteDocs(refs) {
  for (let i = 0; i < refs.length; i += 400) {
    const batch = db.batch();
    refs.slice(i, i + 400).forEach((ref) => batch.delete(ref));
    await batch.commit();
  }
}

async function deleteFile(path) {
  try {
    await bucket.file(path).delete();
  } catch (e) {
    if (e.code !== 404) throw e;
  }
}

async function confirm(message) {
  const rl = createInterface({ input: process.stdin, output: process.stdout });
  const answer = await rl.question(`${message}\nType the project id (${PROJECT_ID}) to continue: `);
  rl.close();
  return answer.trim() === PROJECT_ID;
}

// ----------------------------------------------------------------- commands

async function inventory() {
  const [users, listings] = await Promise.all([db.collection(USERS).get(), db.collection(LISTINGS).get()]);
  let authCount = 0;
  let pageToken;
  do {
    const page = await auth.listUsers(1000, pageToken);
    authCount += page.users.length;
    pageToken = page.pageToken;
  } while (pageToken);
  const admins = await adminUids();

  console.log(`\nProject ${PROJECT_ID}`);
  console.log(`  Auth accounts: ${authCount} (${admins.size} admin)`);
  console.log(`  ${USERS}: ${users.size}`);
  for (const d of users.docs) {
    console.log(`    - ${d.id}  ${d.get('name') ?? ''} <${d.get('email') ?? ''}>${d.get('isDemo') ? '  [demo]' : ''}`);
  }
  console.log(`  ${LISTINGS}: ${listings.size}`);
  for (const d of listings.docs) {
    const reviews = await d.ref.collection('reviews').count().get();
    const legacy = Array.isArray(d.get('reviews')) ? d.get('reviews').length : 0;
    console.log(`    - ${d.id}  "${d.get('expertise') ?? ''}" by ${d.get('name') ?? d.get('uploadedBy')}` +
      `  (${reviews.data().count} reviews, ${legacy} legacy)${d.get('isDemo') ? '  [demo]' : ''}`);
  }
  const legacyAdmin = await db.doc('admin/adminLogin').get();
  if (legacyAdmin.exists) console.log('\n  ! admin/adminLogin (plaintext credentials) still exists. Delete it.');
}

async function backup() {
  const out = { project: PROJECT_ID, exportedAt: new Date().toISOString(), users: {}, listings: {} };
  for (const d of (await db.collection(USERS).get()).docs) out.users[d.id] = serialise(d.data());
  for (const d of (await db.collection(LISTINGS).get()).docs) {
    const reviews = {};
    for (const r of (await d.ref.collection('reviews').get()).docs) reviews[r.id] = serialise(r.data());
    out.listings[d.id] = { ...serialise(d.data()), __reviews: reviews };
  }
  mkdirSync(here('./backups/'), { recursive: true });
  const file = here(`./backups/backup-${out.exportedAt.replace(/[:.]/g, '-')}.json`);
  writeFileSync(file, JSON.stringify(out, null, 2));
  console.log(`Backed up ${Object.keys(out.users).length} profiles and ${Object.keys(out.listings).length} listings to ${file.pathname}`);
  return file;
}

async function wipe() {
  const listingsToo = has('--listings');
  const profiles = has('--profiles');
  const accounts = has('--auth');
  if (!listingsToo && !profiles) {
    console.error('Nothing to wipe: pass --listings and/or --profiles [--auth].');
    process.exit(64);
  }
  await backup();
  const scope = [listingsToo && 'all listings + reviews + PDFs', profiles && 'all non-admin profiles + photos',
    accounts && 'their sign-in accounts'].filter(Boolean).join(', ');
  if (!has('--yes') && !(await confirm(`About to permanently delete: ${scope}.`))) {
    console.log('Aborted. Nothing was deleted.');
    return;
  }

  if (listingsToo) {
    const listings = await db.collection(LISTINGS).get();
    for (const d of listings.docs) {
      const reviews = await d.ref.collection('reviews').get();
      await deleteDocs([...reviews.docs.map((r) => r.ref), d.ref]);
      const owner = d.get('uploadedBy');
      if (d.get('qualificationUrl') && owner) await deleteFile(`qualifications/${owner}/${d.id}.pdf`);
    }
    console.log(`Deleted ${listings.size} listings.`);
  }

  if (profiles) {
    const admins = await adminUids();
    const users = (await db.collection(USERS).get()).docs.filter((d) => !admins.has(d.id));
    await deleteDocs(users.map((d) => d.ref));
    for (const d of users) await deleteFile(`userImages/${d.id}.jpg`);
    console.log(`Deleted ${users.length} profiles (kept ${admins.size} admin).`);

    if (accounts) {
      const uids = users.map((d) => d.id).filter((uid) => !uid.startsWith('demo-'));
      for (let i = 0; i < uids.length; i += 1000) {
        const res = await auth.deleteUsers(uids.slice(i, i + 1000));
        console.log(`Deleted ${res.successCount} sign-in accounts (${res.failureCount} not found).`);
      }
    }
  }
}

async function uploadAvatar(id) {
  const local = here(`../demo/avatars/${id}.jpg`);
  const path = `userImages/${id}.jpg`;
  const token = randomUUID();
  await bucket.file(path).save(readFileSync(local), {
    contentType: 'image/jpeg',
    metadata: { metadata: { firebaseStorageDownloadTokens: token } },
  });
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

function atDayOffset(days) {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() + days);
  return d;
}

const fmtDate = (d) => d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });

async function seed() {
  const data = JSON.parse(readFileSync(here('../demo/freelancers.json'), 'utf8'));
  const people = Object.fromEntries(data.freelancers.map((f) => [f.id, f]));
  const images = {};

  for (const [i, f] of data.freelancers.entries()) {
    images[f.id] = await uploadAvatar(f.id);
    const joined = Timestamp.fromDate(atDayOffset(-(400 - i * 30)));
    const profile = {
      id: f.id,
      name: f.name,
      email: `${f.id.replace('demo-', '')}@example.com`,
      phoneNumber: '',
      userImage: images[f.id],
      city: f.city,
      isDemo: true,
      createdAt: joined,
    };
    const from = atDayOffset(f.startDay);
    const to = atDayOffset(f.startDay + f.lengthDays);
    const listingId = `${f.id}-listing`;
    const listing = {
      freelancerId: listingId,
      uploadedBy: f.id,
      name: f.name,
      userImage: images[f.id],
      email: profile.email,
      phoneNumber: '',
      category: f.category,
      expertise: f.title,
      description: f.description,
      availableFrom: Timestamp.fromDate(from),
      availableTo: Timestamp.fromDate(to),
      startTime: f.startTime,
      endTime: f.endTime,
      availableDate: `${fmtDate(from)} – ${fmtDate(to)}`,
      availableTime: `${f.startTime} – ${f.endTime}`,
      hourlyRate: f.hourlyRate,
      hourlyPayRate: `SAR ${f.hourlyRate}/hr`,
      qualificationUrl: '',
      recruitment: true,
      numberRequests: f.requests,
      isDemo: true,
      createdAt: Timestamp.fromDate(atDayOffset(-(20 - i * 2))),
      updatedAt: FieldValue.serverTimestamp(),
    };
    const batch = db.batch();
    batch.set(db.collection(USERS).doc(f.id), profile);
    batch.set(db.collection(LISTINGS).doc(listingId), listing);
    await batch.commit();
    console.log(`  + ${f.name} — ${f.title}`);
  }

  const batch = db.batch();
  for (const [i, r] of data.reviews.entries()) {
    const author = people[r.author];
    batch.set(db.collection(LISTINGS).doc(`${r.listing}-listing`).collection('reviews').doc(r.author), {
      authorId: r.author,
      authorName: author.name,
      authorImage: images[r.author],
      body: r.body,
      rating: r.rating,
      createdAt: Timestamp.fromDate(atDayOffset(-(i + 1))),
    });
  }
  await batch.commit();
  console.log(`Seeded ${data.freelancers.length} freelancers and ${data.reviews.length} reviews.`);
}

async function unseed() {
  const listings = await db.collection(LISTINGS).where('isDemo', '==', true).get();
  for (const d of listings.docs) {
    const reviews = await d.ref.collection('reviews').get();
    await deleteDocs([...reviews.docs.map((r) => r.ref), d.ref]);
  }
  const users = await db.collection(USERS).where('isDemo', '==', true).get();
  await deleteDocs(users.docs.map((d) => d.ref));
  for (const d of users.docs) await deleteFile(`userImages/${d.id}.jpg`);
  console.log(`Removed ${listings.size} demo listings and ${users.size} demo profiles.`);
}

const commands = { inventory, backup, wipe, seed, unseed };
if (!commands[command]) {
  console.error('Usage: node demo-data.mjs inventory | backup | wipe --listings [--profiles] [--auth] | seed | unseed');
  process.exit(64);
}
try {
  await commands[command]();
} catch (error) {
  console.error(error.message ?? error);
  process.exit(1);
}
