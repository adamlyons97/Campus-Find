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

##  6. Features & Functionalities
*   **Authentication Hub:** Secure login restricted to university domains with automatic field validation.
*   **Report Lost/Found Items:** Advanced form entry allowing users to input specific item descriptions, select predefined categories, tag a campus location, and upload clear photo evidence.
*   **AI-Powered Smart Match:** A smart feature utilizing natural language processing to alert users if a newly reported lost item resembles an existing found item listing.
*   **Secure Claim System:** Third-party verification interface where users must describe specific private details of an item before a claim status shifts from *Pending* to *Approved*.
*   **Status Management:** Live indicators tracking items across *Active*, *Claimed*, and *Resolved* states.

---

## 7. UI Mockup
<img width="353" height="702" alt="image" src="https://github.com/user-attachments/assets/587511f4-122d-4f65-8728-d1553f16023f" />




## 8. Architecture/ Technical Design
<img width="836" height="422" alt="Screenshot 2026-06-12 162813" src="https://github.com/user-attachments/assets/555748a9-20f2-462b-8367-d34ab654848b" />

As shown in the layered diagram above, CampusFind follows a clean three-tier architecture:
1. Flutter UI Layer — All screens are stateless or stateful widgets using Navigator 2.0 for named route navigation. Each screen subscribes to a Provider ChangeNotifier and rebuilds reactively on state changes.

2. Business Logic (Provider) — Four core providers manage application state:

  a) ItemProvider — holds the items list stream from Firestore and triggers AI match checks on new submissions
  
  b) ClaimProvider — manages claim submission lifecycle and status polling
  
  c) AuthProvider — wraps Firebase Auth and enforces IIUM domain validation on login
  
  d) GeminiService — sends item description payloads to the Gemini API and returns match results

3. Services Layer — Pure Dart classes with no Flutter dependencies. 

a) FirestoreService manages all CRUD operations and real-time stream subscriptions. 

b) StorageService handles image upload via Firebase Storage. 

c) GeminiAPIService makes REST calls to generativelanguage.googleapis.com.

4. Firebase Backend — Cloud Firestore with Security Rules enforcing authentication on all reads/writes. Real-time listeners (snapshots()) power live status updates without polling. Firebase Storage is used for item photos with a maximum size restriction of 5MB per image.
State Management Justification — Provider was chosen over Riverpod and BLoC for simplicity within a 2-week scope, its direct integration with Flutter's widget tree, and team familiarity. No external state libraries beyond provider: ^6.0.0 are required.




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
