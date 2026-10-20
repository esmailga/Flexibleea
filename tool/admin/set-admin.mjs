// Grants, revokes or lists the `admin` custom claim used by the app and the
// Firestore/Storage security rules.
//
//   node set-admin.mjs grant  someone@example.com
//   node set-admin.mjs revoke someone@example.com
//   node set-admin.mjs list
//
// Credentials: put a service-account key at ./service-account.json
// (Firebase console > Project settings > Service accounts > Generate key),
// or run `gcloud auth application-default login` first.
import { existsSync, readFileSync } from 'node:fs';
import { applicationDefault, cert, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const PROJECT_ID = 'flexibleea-5b117';
const keyPath = new URL('./service-account.json', import.meta.url);

initializeApp({
  projectId: PROJECT_ID,
  credential: existsSync(keyPath)
    ? cert(JSON.parse(readFileSync(keyPath, 'utf8')))
    : applicationDefault(),
});

const auth = getAuth();
const [command, email] = process.argv.slice(2);

async function setAdmin(address, isAdmin) {
  const user = await auth.getUserByEmail(address);
  const claims = { ...(user.customClaims ?? {}) };
  if (isAdmin) claims.admin = true;
  else delete claims.admin;
  await auth.setCustomUserClaims(user.uid, claims);
  console.log(`${isAdmin ? 'Granted' : 'Revoked'} admin for ${address} (${user.uid}).`);
  console.log('They must sign out and back in for the change to apply.');
}

async function listAdmins() {
  let pageToken;
  let count = 0;
  do {
    const page = await auth.listUsers(1000, pageToken);
    for (const user of page.users) {
      if (user.customClaims?.admin === true) {
        console.log(`${user.email ?? '(no email)'}\t${user.uid}`);
        count++;
      }
    }
    pageToken = page.pageToken;
  } while (pageToken);
  console.log(`${count} admin(s).`);
}

try {
  if (command === 'grant' && email) await setAdmin(email, true);
  else if (command === 'revoke' && email) await setAdmin(email, false);
  else if (command === 'list') await listAdmins();
  else {
    console.error('Usage: node set-admin.mjs grant|revoke <email> | list');
    process.exit(64);
  }
} catch (error) {
  console.error(error.message ?? error);
  process.exit(1);
}
