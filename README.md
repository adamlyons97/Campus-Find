# CampusFind 📍

**Shariah-Compliant Intelligent Lost & Found Mobile System for University Campuses.**

A Flutter app that centralizes campus lost-and-found reporting, uses Google
Gemini to match lost items against found listings, and enforces a transparent,
*Luqatah*-aligned claim-verification flow. Built for IIUM.

> This is the implementation. The full project specification (objectives, data
> model, flowchart, group members) lives in the spec `README.md` supplied with
> the assignment. See **`SETUP.md`** to get it running.

---

## Tech stack

| Concern | Choice |
|--------|--------|
| UI | Flutter (Material 3) |
| State management | **Riverpod** (`flutter_riverpod`) — chosen in spec §8.1 |
| Navigation | `go_router` with an auth redirect guard |
| Auth | Firebase Auth (email/password, university-domain restricted) |
| Database | Cloud Firestore (real-time streams) |
| File storage | Firebase Storage (item photos) |
| AI | `google_generative_ai` (Gemini 1.5 Flash) |

---

## Architecture

Strict **layered architecture** with a clean separation of concerns
(spec §8.2):

```
Presentation (Views + Widgets)
        │  consumes state / dispatches intent
        ▼
State / Notifier (Riverpod providers, AsyncNotifiers)
        │  calls repositories
        ▼
Data (Repositories → Services → Models)
```

UI never talks to Firebase directly — it goes through providers, which call
repositories, which wrap the Firebase/Gemini services.

## Project structure

```
lib/
├── main.dart                  # ProviderScope + Firebase init + MaterialApp.router
├── app_router.dart            # go_router config + auth redirect
├── firebase_options.dart      # PLACEHOLDER — replaced by `flutterfire configure`
│
├── core/
│   ├── theme.dart             # Masjid-green Material 3 theme
│   └── constants/             # app_strings.dart, firestore_paths.dart
│
├── data/
│   ├── models/                # user / item / category / claim models
│   ├── services/              # firebase_service.dart, gemini_ai_service.dart
│   └── repositories/          # auth / item / claim repositories
│
└── features/                  # feature-first modules
    ├── auth/                  # login, register, validators
    ├── home/                  # dashboard feed, filters, my items
    ├── create_post/           # report lost/found form + image picker
    ├── search/                # Gemini free-text smart search
    ├── claims/                # submit claim, verifier dashboard, my claims
    └── item_detail/           # item view + "claim it" entry point

test/
└── validators_test.dart       # pure-Dart unit tests (no Firebase)

firestore.rules                # role-based security rules
```

---

## Feature → code map

| Feature (spec §6) | Where |
|---|---|
| 1. Authentication Hub (domain-restricted) | `features/auth/`, `data/repositories/auth_repository.dart` |
| 2. Report Lost/Found | `features/create_post/` |
| 3. AI Smart Match | `data/services/gemini_ai_service.dart`, triggered in `create_post_provider.dart` |
| 4. Secure Claim System | `features/claims/`, `data/repositories/claim_repository.dart` |
| 5. Status Management (active/claimed/resolved) | `data/models/item_model.dart`, claim approval batch in `claim_repository.dart` |

---

## Shariah alignment

- **Amanah (trust):** found items are held as a trust; finder hand-off notes and
  verifier approval are required before release.
- **Luqatah (lost property):** finders and claimants see guidance notices
  (`core/constants/app_strings.dart`); items move `active → claimed → resolved`
  only after a verifier (`security`/`admin`) approves a claim, never automatically.

---

## Notes

- The Gemini key is injected at build time (`--dart-define=GEMINI_API_KEY=...`),
  never committed. AI features degrade gracefully if it is absent.
- `firebase_options.dart` ships as a placeholder so the project compiles before
  you connect a backend; `flutterfire configure` replaces it.

See **`SETUP.md`** for full setup, run, and deploy steps.
