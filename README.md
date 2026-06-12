# 📌 CampusFind: Shariah-Compliant Lost & Found Mobile App

---

 ## 1. Group Members & Roles

1. | LUEBAESA MUHAMMADLUTFI | 2210835 | 
2. | MUHAMMAD AMMAR RAZIQ BIN ABDUL RAZAK | 2311619 | 
3. | CHE MUHAMMAD HAKIMI BIN CHE ARSHAD | 2311665 |
4. | AHMAD ADAM DANIAL BIN AB RAHMAN | 2319525 |

---

##  2. Project Title
**CampusFind** – Shariah-Compliant Intelligent Lost & Found Mobile System for University Campuses.

---

##  3. Introduction
*   **Problem Statement:** University students frequently misplace valuable belongings such as matric cards, keys, laptops, and wallets. Current recovery methods rely heavily on fragmented, unorganized WhatsApp groups or social media statuses, which move quickly down the feed, leading to low recovery rates and visual clutter.
*   **Motivation:** To centralize campus recovery efforts into a singular mobile hub that leverages real-time data streaming and artificial intelligence to bridge the gap between finders and owners.
*   **Relevance:** It actively fosters a campus community built on integrity and the Islamic principle of *Amanah* (trustworthiness), helping students recover vital items rapidly to reduce stress and operational disruptions.

---

##  4. Objectives
1. To design and implement a secure mobile app using Flutter that centralizes lost and found reporting.
2. To integrate Google Gemini API to dynamically match descriptions of lost items against found listings.
3. To uphold Shariah-compliant guidelines regarding *Luqatah* (lost property handling) through transparent status tracking.
4. To implement real-time synchronization of claim statuses utilizing Cloud Firestore streams.

---

##  5. Target Users
*   **Primary Users:** University students and academic staff members who actively lose or discover items.
*   **Secondary Users:** Campus Security Officers and Mahallah Administrators acting as safe depository authorities.

---

## 6. Features & Functionalities

1. **Authentication Hub:**
Secure login restricted to university domains with automatic field validation.
2. **Report Lost/Found Items:**
Advanced form entry allowing users to input specific item descriptions, select predefined categories, tag a campus location, and upload clear photo evidence.
3. **AI-Powered Smart Match:**
A smart feature utilizing natural language processing to alert users if a newly reported lost item resembles an existing found item listing.
4. **Secure Claim System:**
Third-party verification interface where users must describe specific private details of an item before a claim status shifts from *Pending* to *Approved*.
5. **Status Management:**
Live indicators tracking items across *Active*, *Claimed*, and *Resolved* states.

---

## 7. UI Mockup

<img width="350" height="699" alt="image" src="https://github.com/user-attachments/assets/b128d1e7-3bb0-4640-be94-fc90b2190bc0" />
<img width="353" height="702" alt="image" src="https://github.com/user-attachments/assets/587511f4-122d-4f65-8728-d1553f16023f" />
<img width="346" height="699" alt="image" src="https://github.com/user-attachments/assets/2355f586-1daa-4ce6-a66b-e38e14d6e6ff" />
<img width="357" height="701" alt="image" src="https://github.com/user-attachments/assets/66515f54-ce29-412c-bf57-fbb1fdb52a99" />

---

## 🏗️ 8. Architecture / Technical Design

The 'CampusFind' mobile application follows a strict **Layered Architecture** pattern, utilizing a clean separation of concerns. This approach ensures modularity, testability, and efficient real-time state updates.

### 8.1 Chosen State Management: **Riverpod**
We have selected the **Riverpod** package for state management. While the project approach covers Provider, Riverpod is the modern successor by the same author, addressing some of Provider's fundamental limitations (like global scope, type safety, and handling asynchronous data effortlessly).

### 8.2 Architectural Layers & Data Flow
```code
       [1. PRESENTATION LAYER (UI)]
          |--- Views (Screens)
          |--- Reusable Widgets (Components)
          ^
          | (Consumes State, Dispatches Intent)
          v
       [2. STATE/NOTIFIER LAYER (BUSINESS LOGIC)]
          |--- StateNotifiers (View Models)
          |--- Providers (AsyncNotifierProvider, StateProvider)
          ^
          | (Calls Services, Updates State)
          v
       [3. DATA LAYER (INFRASTRUCTURE)]
          |--- Repositories (AuthRepository, ItemRepository)
          |--- Services (FirebaseService, GeminiAIService)
          |--- Models (Data Transfer Objects)
```

### 8.3 Feature-Based Folder Structure (Implementation Roadmap)

```
lib/
├── main.dart (App entry point with ProviderScope)
├── app_router.dart (go_router configuration)
│
├── core/                  # Shared utilities
│   ├── theme.dart         # Shariah-compliant styles
│   └── constants/         # Asset paths, Shariah strings
│
├── data/                  # Core Models and Services
│   ├── models/            # ItemModel.dart, UserModel.dart
│   ├── repositories/      # auth_repository.dart, item_repository.dart
│   └── services/          # gemini_ai_service.dart
│
└── features/              # Feature-specific modules
    ├── auth/
    │   ├── providers/     # auth_provider.dart
    │   ├── views/         # login_screen.dart
    │   └── widgets/       # auth_validator_field.dart
    ├── home/
    │   ├── providers/     # item_list_provider.dart
    │   └── views/         # home_dashboard.dart
    ├── create_post/
    │   ├── views/         # create_item_form.dart
    │   └── widgets/       # image_picker_widget.dart
    ├── search/
    │   ├── providers/     # gemini_search_provider.dart
    │   └── views/         # ai_search_screen.dart
    └── claims/
        ├── providers/     # claim_status_provider.dart
        └── views/         # claim_submission_screen.dart
```

## 9. Data Model
<img width="785" height="341" alt="image" src="https://github.com/user-attachments/assets/8d99b661-e21b-432d-aa81-aedfe9fc5ab9" />

The Firestore collection-document model is shown in the diagram above. Key design decisions:

users/ — Stores authenticated profile data. The role field differentiates between student, staff, and security, unlocking different UI flows and Firestore Security Rules.

items/ — Central collection. The type field is either lost or found. status progresses through active → claimed → resolved. A GeoPoint field stores the tagged campus location for future map-view filtering.

claims/ — Separate from items to maintain audit history. proofText stores the claimant's private description for manual or AI-assisted verification. Status progresses pending → approved → rejected.

items/{itemId}/aiMatches/ (subcollection) — Written by the backend/Gemini call when a new item is submitted. Each document records a matchedItemId, a confidence score (0.0–1.0), and a status of notified or dismissed.

Security Rules — All write operations require request.auth != null. Updates to claims status are restricted to documents where verifiedBy == request.auth.uid or where the user has a security or staff role.


## 10. Flowchart/ Sequence Diagram






## 📚 11. References
*   Flutter Official Documentation: https://docs.flutter.dev
*   Firebase Core & Firestore Documentation: https://firebase.google.com/docs
*   Google AI Dart SDK (Gemini): https://pub.dev/packages/google_generative_ai
*   Provider State Management: https://pub.dev/packages/provider
*   Go_Router Navigation Asset: https://pub.dev/packages/go_router
