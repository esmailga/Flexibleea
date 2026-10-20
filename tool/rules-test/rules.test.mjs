// Security rules tests. Run with `npm test` (starts the emulators).
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  increment,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';
import { deleteObject, ref, uploadBytes } from 'firebase/storage';

const LISTINGS = 'Freelancer Expertise';
const withStorage = Boolean(process.env.FIREBASE_STORAGE_EMULATOR_HOST);
let env;

const profile = (uid) => ({
  id: uid,
  name: `User ${uid}`,
  email: `${uid}@example.com`,
  phoneNumber: '+60123456789',
  userImage: '',
});

const listing = (owner, id) => ({
  freelancerId: id,
  uploadedBy: owner,
  category: 'Marketing',
  expertise: 'SEO audits',
  description: 'Technical SEO for small businesses.',
  recruitment: true,
  numberRequests: 0,
  name: `User ${owner}`,
  userImage: '',
  email: `${owner}@example.com`,
  phoneNumber: '+60123456789',
});

const review = (author, body = 'Great to work with!', rating = 5) => ({
  authorId: author,
  authorName: `User ${author}`,
  authorImage: '',
  body,
  rating,
  createdAt: serverTimestamp(),
});

const db = (uid, claims) =>
  uid ? env.authenticatedContext(uid, claims).firestore() : env.unauthenticatedContext().firestore();
const storage = (uid, claims) => env.authenticatedContext(uid, claims).storage();
const admin = () => db('boss', { admin: true });

async function seed(fn) {
  await env.withSecurityRulesDisabled(async (ctx) => fn(ctx.firestore()));
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-flexibleea',
    firestore: { rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8') },
    ...(withStorage && {
      storage: { rules: readFileSync(new URL('../../storage.rules', import.meta.url), 'utf8') },
    }),
  });
});

after(async () => env?.cleanup());

beforeEach(async () => {
  await env.clearFirestore();
  await seed(async (f) => {
    await setDoc(doc(f, 'Users/alice'), profile('alice'));
    await setDoc(doc(f, 'Users/bob'), profile('bob'));
    await setDoc(doc(f, LISTINGS, 'L1'), listing('alice', 'L1'));
    await setDoc(doc(f, 'admin/adminLogin'), { adminEmail: 'x', adminPassword: 'y' });
  });
});

describe('access', () => {
  test('signed-out visitors cannot read anything', async () => {
    await assertFails(getDoc(doc(db(), 'Users/alice')));
    await assertFails(getDoc(doc(db(), LISTINGS, 'L1')));
  });

  test('the legacy admin credentials document is unreadable', async () => {
    await assertFails(getDoc(doc(db('alice'), 'admin/adminLogin')));
    await assertFails(getDoc(doc(admin(), 'admin/adminLogin')));
  });

  test('signed-in members can read profiles and listings', async () => {
    await assertSucceeds(getDoc(doc(db('bob'), 'Users/alice')));
    await assertSucceeds(getDoc(doc(db('bob'), LISTINGS, 'L1')));
  });
});

describe('Users', () => {
  test('members create only their own profile', async () => {
    await assertSucceeds(setDoc(doc(db('carol'), 'Users/carol'), { ...profile('carol'), createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(db('carol'), 'Users/dave'), profile('dave')));
    await assertFails(setDoc(doc(db('carol'), 'Users/carol2'), profile('carol')));
  });

  test('profiles are validated', async () => {
    await assertFails(setDoc(doc(db('carol'), 'Users/carol'), { ...profile('carol'), name: '' }));
    await assertFails(setDoc(doc(db('carol'), 'Users/carol'), { id: 'carol', name: 'Carol' }));
  });

  test('members cannot edit or delete other profiles', async () => {
    await assertSucceeds(updateDoc(doc(db('alice'), 'Users/alice'), { name: 'Alice Tan' }));
    await assertFails(updateDoc(doc(db('bob'), 'Users/alice'), { name: 'Hacked' }));
    await assertFails(deleteDoc(doc(db('bob'), 'Users/alice')));
  });

  test('admins can rename and delete any profile', async () => {
    await assertSucceeds(updateDoc(doc(admin(), 'Users/alice'), { name: 'Renamed' }));
    await assertSucceeds(deleteDoc(doc(admin(), 'Users/bob')));
  });
});

describe('Listings', () => {
  test('members publish listings only as themselves', async () => {
    const mine = { ...listing('bob', 'L2'), createdAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(db('bob'), LISTINGS, 'L2'), mine));
    await assertFails(setDoc(doc(db('bob'), LISTINGS, 'L3'), listing('alice', 'L3')));
  });

  test('new listings cannot fake their id or request count', async () => {
    await assertFails(setDoc(doc(db('bob'), LISTINGS, 'L4'), listing('bob', 'other-id')));
    await assertFails(setDoc(doc(db('bob'), LISTINGS, 'L5'), { ...listing('bob', 'L5'), numberRequests: 50 }));
  });

  test('owners edit their listing but cannot reassign it or inflate requests', async () => {
    const own = db('alice');
    await assertSucceeds(updateDoc(doc(own, LISTINGS, 'L1'), { recruitment: false, expertise: 'Local SEO' }));
    await assertFails(updateDoc(doc(own, LISTINGS, 'L1'), { uploadedBy: 'bob' }));
    await assertFails(updateDoc(doc(own, LISTINGS, 'L1'), { numberRequests: 99 }));
  });

  test('other members may only add exactly one request', async () => {
    const other = db('bob');
    await assertSucceeds(updateDoc(doc(other, LISTINGS, 'L1'), { numberRequests: increment(1) }));
    await assertFails(updateDoc(doc(other, LISTINGS, 'L1'), { numberRequests: increment(5) }));
    await assertFails(updateDoc(doc(other, LISTINGS, 'L1'), { recruitment: false }));
    await assertFails(updateDoc(doc(other, LISTINGS, 'L1'), { numberRequests: increment(1), expertise: 'x' }));
  });

  test('only the owner or an admin can delete a listing', async () => {
    await assertFails(deleteDoc(doc(db('bob'), LISTINGS, 'L1')));
    await assertSucceeds(deleteDoc(doc(db('alice'), LISTINGS, 'L1')));
    await seed((f) => setDoc(doc(f, LISTINGS, 'L1'), listing('alice', 'L1')));
    await assertSucceeds(deleteDoc(doc(admin(), LISTINGS, 'L1')));
  });

  test('the old admin "delete" bug path (random doc id) is not a thing anymore', async () => {
    // Deleting a non-existent doc as a member must be refused, not silently succeed.
    await assertFails(deleteDoc(doc(db('bob'), LISTINGS, 'does-not-exist')));
  });
});

describe('Reviews', () => {
  const reviewDoc = (f, reviewer) => doc(f, LISTINGS, 'L1', 'reviews', reviewer);

  test('members review under their own uid only', async () => {
    await assertSucceeds(setDoc(reviewDoc(db('bob'), 'bob'), review('bob')));
    await assertFails(setDoc(reviewDoc(db('bob'), 'carol'), review('carol')));
  });

  test('owners cannot review their own listing', async () => {
    await assertFails(setDoc(reviewDoc(db('alice'), 'alice'), review('alice')));
  });

  test('reviews are validated', async () => {
    await assertFails(setDoc(reviewDoc(db('bob'), 'bob'), review('bob', 'short')));
    await assertFails(setDoc(reviewDoc(db('bob'), 'bob'), review('bob', 'Long enough text', 6)));
    await assertFails(setDoc(reviewDoc(db('bob'), 'bob'), review('bob', 'Long enough text', 0)));
  });

  test('authors, listing owners and admins can delete reviews', async () => {
    await seed((f) => setDoc(reviewDoc(f, 'bob'), review('bob')));
    await assertFails(deleteDoc(reviewDoc(db('carol'), 'bob')));
    await assertSucceeds(deleteDoc(reviewDoc(db('alice'), 'bob')));
    await seed((f) => setDoc(reviewDoc(f, 'bob'), review('bob')));
    await assertSucceeds(deleteDoc(reviewDoc(admin(), 'bob')));
    await seed((f) => setDoc(reviewDoc(f, 'bob'), review('bob')));
    await assertSucceeds(deleteDoc(reviewDoc(db('bob'), 'bob')));
  });

  test('owners can delete a listing together with its reviews in one batch', async () => {
    await seed((f) => setDoc(reviewDoc(f, 'bob'), review('bob')));
    const f = db('alice');
    const batch = writeBatch(f);
    batch.delete(reviewDoc(f, 'bob'));
    batch.delete(doc(f, LISTINGS, 'L1'));
    await assertSucceeds(batch.commit());
  });
});

describe('Storage', { skip: !withStorage && 'storage emulator not running' }, () => {
  const jpeg = new Uint8Array([0xff, 0xd8, 0xff]);
  const pdf = new TextEncoder().encode('%PDF-1.4');

  test('members upload only their own profile photo, as an image', async () => {
    await assertSucceeds(uploadBytes(ref(storage('alice'), 'userImages/alice.jpg'), jpeg, { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(storage('alice'), 'userImages/bob.jpg'), jpeg, { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(storage('alice'), 'userImages/alice.jpg'), pdf, { contentType: 'application/pdf' }));
  });

  test('qualification PDFs are owner-only', async () => {
    await assertSucceeds(uploadBytes(ref(storage('alice'), 'qualifications/alice/L1.pdf'), pdf, { contentType: 'application/pdf' }));
    await assertFails(uploadBytes(ref(storage('bob'), 'qualifications/alice/L1.pdf'), pdf, { contentType: 'application/pdf' }));
    await assertFails(uploadBytes(ref(storage('alice'), 'qualifications/alice/x.pdf'), jpeg, { contentType: 'image/jpeg' }));
  });

  test('the legacy shared pdfs/ path is closed', async () => {
    await assertFails(uploadBytes(ref(storage('alice'), 'pdfs/some-file.pdf'), pdf, { contentType: 'application/pdf' }));
  });

  test('admins can remove profile photos', async () => {
    await assertSucceeds(uploadBytes(ref(storage('bob'), 'userImages/bob.jpg'), jpeg, { contentType: 'image/jpeg' }));
    await assertFails(deleteObject(ref(storage('alice'), 'userImages/bob.jpg')));
    await assertSucceeds(deleteObject(ref(storage('boss', { admin: true }), 'userImages/bob.jpg')));
  });
});
