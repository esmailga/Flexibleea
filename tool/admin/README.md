# Admin tooling

Admins are ordinary Firebase Auth users with the custom claim `admin: true`.
The app routes them to the admin console after sign-in, and the security
rules (`firestore.rules`, `storage.rules`) grant them moderation rights.

```bash
cd tool/admin
npm install
# Either save a service-account key as service-account.json (git-ignored),
# or authenticate with: gcloud auth application-default login
node set-admin.mjs grant admin@example.com
node set-admin.mjs list
node set-admin.mjs revoke admin@example.com
```

The account must already exist (create it in the Firebase console under
Authentication, or sign up in the app). After granting, the user signs out
and back in.

The old `admin/adminLogin` Firestore document (plaintext credentials) is no
longer used and is blocked by the rules. Delete it from the Firebase console.

## Demo data and resets (`demo-data.mjs`)

```bash
node demo-data.mjs inventory                  # read-only: what is in the project
node demo-data.mjs backup                     # JSON export to ./backups/ (git-ignored)
node demo-data.mjs wipe --listings            # delete all listings, reviews and PDFs
node demo-data.mjs wipe --listings --profiles # ...and all non-admin member profiles
node demo-data.mjs wipe --listings --profiles --auth   # ...and their sign-in accounts
node demo-data.mjs seed                       # add the 10 demo freelancers
node demo-data.mjs unseed                     # remove only the demo freelancers
```

`wipe` always writes a backup first and asks you to type the project id
before deleting anything. Admin accounts are never deleted.

The demo freelancers live in `tool/demo/freelancers.json`. They are fictional
Saudi-market profiles with illustrated avatars (DiceBear "avataaars" by Pablo
Stanley, free for personal and commercial use), `example.com` emails and no
phone numbers, so nobody real is contacted. Every demo document carries
`isDemo: true`.
