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

## 🗂️ 9. Data Model
<img width="785" height="341" alt="image" src="https://github.com/user-attachments/assets/8d99b661-e21b-432d-aa81-aedfe9fc5ab9" />

Instead of a traditional relational SQL structure, **CampusFind** utilizes **Cloud Firestore**, a flexible, scalable NoSQL document database. 

Our data model prioritizes:

* **Read Efficiency:** Optimized for fast data retrieval and seamless feed rendering within Flutter's `ListView.builder` widgets.
* **Real-time Synchronization:** Leverages Firestore streams to instantly synchronize and update item claim statuses across clients without requiring manual page refreshes.
* **AI Readiness:** Preserves key descriptive text and metadata fields in a structured format, enabling seamless analysis and embedding generation by the `google_generative_ai` package.

### 9.1 Overview Diagram (Hierarchical Structure)
```
/ (Database Root)
│
├── [cite: users] (Collection)
│     └── (Document: uid - link to Firebase Auth)
│
├── [cite: items] (Universal collection for both LOST and FOUND entries)
│     └── (Document: auto-generated itemId)
│
├── [cite: itemCategories] (Predefined list for filtering [cite: 2])
│     └── (Document: auto-generated categoryId)
│
└── [cite: claims] (Manages the relationship between a claimant, an item, and a finder [cite: 2])
      └── (Document: auto-generated claimId)
```

### 9.2 Collection Schemas & Field Definitions
### 7. Database Schema (Cloud Firestore)

#### A. users Collection
This collection stores supplementary profile details. The Document ID matches the unique ID (`uid`) generated by Firebase Authentication.

* **Path:** `/users/{uid}`
* **Schema:**
```json
{
  "name": "String (Full name)",
  "email": "String (Validated @ university domain)",
  "role": "String ('student', 'staff', 'security', 'admin')",
  "joinedAt": "Timestamp",
  "mahallah_faculty": "String (Optional for local context)",
  "totalItemsReported": "Int (Statistic for CLO 3 tracking)",
  "totalItemsReunited": "Int (Statistic)"
}
```

#### B. items Collection
Lost and Found items are merged into a single collection to streamline universal search optimization and the Gemini AI matching engine.

* **Path:** `/items/{autoItemId}`
* **Schema:**
```json
{
  "title": "String (e.g., 'Blue Wallet')",
  "description": "String (Detailed description required for Gemini AI analysis)",
  "type": "String ('lost' or 'found')",
  "status": "String ('active', 'claimed', 'resolved')", // Essential for Shariah process flow
  "categoryId": "String (Ref to itemCategories document)",
  "categoryName": "String (Denormalized for efficient display)",
  "imageUrl": "String (Download URL from Firebase Storage)",
  "locationSeen": {
    "name": "String (e.g., 'HS Cafe')",
    "specificDetails": "String (e.g., 'Third table from entrance')"
  },
  "reportedAt": "Timestamp",
  "reporterId": "String (Ref to users.uid)",
  "reporterName": "String (Denormalized for efficient display)",
  "isSoftDeleted": "Boolean (For data integrity)",
  "finderClaimRequestNotes": "String (If type is found, finder specifies handoff details)"
}
```

#### C. itemCategories Collection
A simple lookup table to support advanced system filtering.

* **Path:** `/itemCategories/{autoCategoryId}`
* **Schema:**
```json
{
  "name": "String (e.g., 'Documents', 'Electronics', 'Keys', 'Cash')",
  "iconPath": "String (Local asset path or icon name)"
}
```

#### D. claims Collection
This collection governs the verification process of reuniting people with their belongings, facilitating role-based security access.

* **Path:** `/claims/{autoClaimId}`
* **Schema:**
```json
{
  "itemId": "String (Ref to items.itemId)",
  "claimantId": "String (Ref to users.uid)",
  "reporterId": "String (Ref to users.uid - owner of the Found post)",
  "proofOfOwnership": "String (Claimant's natural language description matching the item)",
  "claimedAt": "Timestamp",
  "updatedAt": "Timestamp",
  "status": "String ('pending', 'approved', 'rejected')", // Controlled by Admins/Security
  "finderNotes": "String (Additional context provided by the item finder during verification)"
}
```

## 10. Flowchart/ Sequence Diagram






## 📚 11. References
*   Flutter Official Documentation: https://docs.flutter.dev
*   Firebase Core & Firestore Documentation: https://firebase.google.com/docs
*   Google AI Dart SDK (Gemini): https://pub.dev/packages/google_generative_ai
*   Provider State Management: https://pub.dev/packages/provider
*   Go_Router Navigation Asset: https://pub.dev/packages/go_router
