# CampusFind

CampusFind is a Flutter mobile app for campus lost-and-found management. It lets students report lost/found items, search and filter reports, submit claims, approve/reject claims, mark items as claimed, and save a local profile.

## Database choice

The current implementation uses SQLite through `sqflite`. This is the best free option for a student mobile app MVP because it:

- costs nothing,
- works offline on the device,
- does not require billing, accounts, or server setup,
- is easy to demo on Android/iOS.

If the app later needs real-time multi-user sync, use Supabase or Firebase Firestore as the next step.

## Features

- Dashboard with lost/found/claimed counts
- Search and filter item reports
- Add lost/found item reports
- View item details
- Submit item claims
- Approve/reject claims
- Mark item status as lost, found, or claimed
- Edit local profile
- SQLite-backed persistence

## Run

Install dependencies after cloning or after dependency changes:

```sh
flutter pub get
```

Run the app:

```sh
flutter run
```

Run tests:

```sh
flutter test
```
