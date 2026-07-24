# 💊 MediMind — Medicine Reminder App

A cross-platform Flutter application to help users schedule, track, and manage their daily medications with smart notifications, history tracking, and cloud sync.

---

## 📋 Project Overview

**MediMind** is a Medicine Reminder App built with Flutter and Firebase. It allows users to:

- Schedule medicine reminders with exact-time local notifications
- Track daily medication adherence with a color-coded status system
- View their full medicine history filtered by Today, Weekly, or Monthly
- Manage their profile including a profile picture
- Repeat medications on a Daily, Weekly, or Monthly schedule
- Sync all data securely with Firebase Firestore in real-time

---

## ✨ Features

| Feature | Description |
|---|---|
| 🔔 Smart Notifications | Alarm-priority local notifications with vibration at exact scheduled time |
| 🔁 Repeat Scheduling | One Time, Daily, Weekly, or Monthly reminder repeats |
| ✉️ Email Verification | Firebase email verification required before login |
| 📜 Medicine History | Filter history by Today, Weekly, Monthly with Taken/Missed/Skipped status |
| 👤 Profile Picture | Upload photo from gallery; stored in Firebase Storage |
| 🌙 Dark Mode | Full dark theme support |
| 👴 Elderly Mode | Larger text and high-contrast display |
| 🔥 Firebase Sync | Real-time Firestore sync with offline sandbox fallback |
| 📱 Cross-Platform | Runs on Android, iOS, and Flutter Web |

---

## 🛠️ Technologies Used

| Technology | Version | Purpose |
|---|---|---|
| Flutter | ≥3.11 | Cross-platform UI framework |
| Dart | ^3.11.5 | Programming language |
| Firebase Auth | ^6.5.3 | Authentication & email verification |
| Cloud Firestore | ^6.6.0 | Real-time cloud database |
| Firebase Storage | ^12.3.0 | Profile photo storage |
| flutter_local_notifications | ^22.0.1 | Local alarm notifications |
| timezone | ^0.9.4 | Timezone-aware scheduling |
| image_picker | ^1.1.2 | Gallery image selection |
| provider | ^6.1.5 | State management |
| shared_preferences | ^2.5.5 | Local settings persistence |
| intl | ^0.20.2 | Date/time formatting |

---

## 🔥 Firebase Setup

### 1. Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add Project** → name it `medicine-reminder-app` → click Continue

### 2. Enable Firebase Services
- **Authentication** → Sign-in method → Enable **Email/Password**
- **Firestore Database** → Create database → Start in **production mode** → choose region
- **Storage** → Get started → choose region

### 3. Configure Storage Security Rules
In Firebase Console → Storage → Rules, paste:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_photos/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 4. Configure Firestore Security Rules
In Firebase Console → Firestore → Rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /medicines/{medicineId} {
      allow read, write: if request.auth != null &&
        request.resource.data.userId == request.auth.uid;
      allow read, delete: if request.auth != null &&
        resource.data.userId == request.auth.uid;
    }
  }
}
```

### 5. Add Platform Apps
- **Android**: Register with package name `com.example.medicine_reminder_app` → download `google-services.json` → place in `android/app/`
- **Web**: Register web app → copy Firebase config → it's already in `lib/firebase_options.dart`

---

## 📦 Installation

### Prerequisites
- Flutter SDK ≥ 3.11
- Android Studio or VS Code with Flutter extension
- Firebase CLI (for hosting): `npm install -g firebase-tools`

### Clone & Install
```bash
git clone https://github.com/Shahab-Ibrar/Medicine-Reminder-App.git
cd Medicine-Reminder-App
flutter pub get
```

---

## ▶️ Running the Project

### Android
```bash
flutter run
```

### Flutter Web (local)
```bash
flutter run -d chrome
```

### Build for Production Web
```bash
flutter build web --release
```

---

## 🚀 Firebase Hosting Deployment

```bash
firebase login
firebase init hosting          # select build/web as public directory, configure as SPA
flutter build web --release
firebase deploy --only hosting
```

---

## 📁 Folder Structure

```
lib/
├── firebase_options.dart          # Auto-generated Firebase config
├── main.dart                      # App entry point
├── models/
│   ├── medicine.dart              # Medicine model (+ repeatType, Skipped status)
│   └── user_profile.dart          # UserProfile model (+ photoUrl)
├── providers/
│   ├── auth_provider.dart         # Auth state + email verification + photo upload
│   ├── medicine_provider.dart     # CRUD + repeat scheduling + markAsSkipped
│   └── theme_provider.dart        # Dark mode & elderly mode
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart          # Email verification dialog
│   ├── register_screen.dart       # Sends verification email on register
│   ├── forgot_password_screen.dart
│   ├── home_dashboard.dart        # Photo-aware drawer header
│   ├── dashboard_tab.dart         # Miss / Skip / Take buttons
│   ├── medicine_list_screen.dart
│   ├── add_edit_medicine_screen.dart  # Repeat schedule dropdown
│   ├── medicine_details_screen.dart
│   ├── history_screen.dart        # Today/Weekly/Monthly filters
│   └── profile_screen.dart        # Profile photo picker
└── services/
    ├── auth_service.dart           # Abstract interface
    ├── firebase_auth_service.dart  # Firebase implementation
    ├── mock_auth_service.dart      # Sandbox implementation
    ├── database_service.dart       # Abstract interface
    ├── firestore_service.dart      # Firestore implementation
    ├── mock_database_service.dart  # In-memory implementation
    ├── notification_service.dart   # Local notifications (platform guarded)
    └── service_locator.dart        # Service registry
```

---

## 📸 Screenshots

> _Add screenshots here after first build_

| Screen | Screenshot |
|---|---|
| Login | `screenshots/login.png` |
| Dashboard | `screenshots/dashboard.png` |
| Add Medicine | `screenshots/add_medicine.png` |
| History | `screenshots/history.png` |
| Profile | `screenshots/profile.png` |

---

## 🔗 GitHub Repository

**Repository**: [https://github.com/Shahab-Ibrar/Medicine-Reminder-App](https://github.com/Shahab-Ibrar/Medicine-Reminder-App)

---

## 🚀 Future Improvements

- [ ] Google Sign-In support
- [ ] Push notifications via Firebase Cloud Messaging (FCM)
- [ ] Medicine barcode/QR code scanner
- [ ] Caregiver mode (share reminders with family)
- [ ] Export history as PDF/CSV report
- [ ] Medication interaction warnings
- [ ] Wearable device integration (Wear OS / Apple Watch)
- [ ] Multi-language support (Urdu, Arabic, etc.)

---

## 👥 Team

| Name | Roll Number |
|---|---|
| Shahab Ibrar | FA23-BCS-103 |
| Shahid Zaman | FA23-BCS-104 |
| Musa Wisal | FA23-BCS-082 |

**Course**: Mobile Application Development  
**Instructor**: Sir. Jawad Khan  
**Institution**: COMSATS University Islamabad, Abbottabad Campus

---

## 📄 License

This project is developed for academic purposes as part of the Mobile Application Development course.
