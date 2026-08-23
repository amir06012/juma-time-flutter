# Mosque Finder (Flutter - Android + iOS)

Shows the 20-30 nearest mosques within 1 km, the 5 daily namaz times
(auto-calculated for your location), and lets users submit Jummah times that
go live only after admin approval. Includes a Qibla-direction compass tab.

## How each requirement is implemented

| Requirement | Implementation |
|---|---|
| 20-30 nearby mosques, 1 km radius | Google Places API "Nearby Search", `type=mosque`, `radius=1000` |
| 5 daily namaz times | Free Aladhan API, calculated from device location (no user input) |
| User adds Jummah time 1 & 2 | Bottom sheet form -> Firestore "pending" fields |
| Shown to all users viewing that mosque | Firestore `snapshots()` stream - live updates for everyone |
| Prompt to add if missing / show if present | `JummahInfo.hasApprovedTimes` / `hasPending` drives the UI state |
| Verification before going live | Submitted times sit in `pending*` fields; only an **admin** approval (via the in-app Admin screen) copies them into the live `jummahTime1/2` fields that everyone sees |
| Accurate distance to mosque | `Geolocator.distanceBetween` (great-circle distance) |
| Directions via Google Maps | `url_launcher` opens native Google Maps navigation |
| Bottom tabs: Mosques / Qibla | `BottomNavigationBar` in `home_screen.dart` |
| Qibla direction with fancy marker | Device compass (`flutter_compass`) + calculated bearing to the Kaaba, custom rotating marker that turns green when aligned |

**Point 10 from your message got cut off** - let me know what it was and I'll add it.

## 1. Generate the Flutter project shell

I've given you the `lib/` folder and `pubspec.yaml` - the actual app code.
The Android/iOS native wrapper folders are best generated fresh by Flutter's
own tooling (they're large, version-specific, and easy to get subtly wrong
by hand). So:

```bash
flutter create --org com.example --project-name mosque_finder mosque_finder_app
```

Then **replace** the generated `pubspec.yaml` and `lib/` folder with the ones
from this package (copy `lib/` and `pubspec.yaml` into the new project,
overwriting what `flutter create` made).

```bash
cd mosque_finder_app
flutter pub get
```

## 2. Firebase setup

1. Go to https://console.firebase.google.com -> **Add project**.
2. Install the FlutterFire CLI (one-time):
   ```bash
   dart pub global activate flutterfire_cli
   ```
3. From inside your project folder, run:
   ```bash
   flutterfire configure
   ```
   This walks you through selecting your Firebase project and automatically
   registers both Android and iOS apps, generating `firebase_options.dart`
   and the native config files (`google-services.json` / `GoogleService-Info.plist`).
4. Update `lib/main.dart`'s `Firebase.initializeApp()` call to pass
   `options: DefaultFirebaseOptions.currentPlatform` (flutterfire configure
   will tell you to do this and generates the import for you).

## 3. Enable Firestore + Authentication

1. Firebase Console -> **Build -> Firestore Database -> Create database**
   (test mode initially, then apply the security rules below).
2. Firebase Console -> **Build -> Authentication -> Sign-in method**:
   - Enable **Anonymous** (used for regular users submitting times)
   - Enable **Email/Password** (used only for your admin login)
3. Still in Authentication, go to the **Users** tab and manually add one
   user with your own email + a password - this is your admin account.
4. Update `lib/utils/constants.dart`:
   ```dart
   static const List<String> adminEmails = ['your-real-admin-email@example.com'];
   ```
   Use the **same** email you just created in step 3.

## 4. Firestore security rules

Paste this into Firebase Console -> Firestore Database -> Rules, replacing
the email with your real admin email (must match step 3 exactly):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /mosques/{mosqueId} {
      allow read: if true;

      // Admin account can approve/reject/edit anything.
      allow write: if request.auth != null &&
        request.auth.token.email == 'your-real-admin-email@example.com';

      // Any signed-in user (including anonymous) can create a mosque doc
      // or submit pending times, but can NEVER write the live
      // jummahTime1 / jummahTime2 / approvedAt fields directly.
      allow create: if request.auth != null;
      allow update: if request.auth != null &&
        !request.resource.data.diff(resource.data).affectedKeys()
          .hasAny(['jummahTime1', 'jummahTime2', 'approvedAt']);
    }
  }
}
```

This is what actually enforces your "needs admin approval" requirement -
the in-app check is just for UX, these rules are what stop a malicious
user from writing directly to the live fields.

## 5. Google Places API key

1. Go to https://console.cloud.google.com, select/create the **same**
   project Firebase created for you.
2. **APIs & Services -> Library** -> enable **Places API**.
3. **Billing** -> attach a billing account (Places API needs it; Google
   gives a recurring monthly free credit, but nearby-search calls do cost
   beyond that at scale).
4. **APIs & Services -> Credentials -> Create credentials -> API key.**
5. Click into the new key -> **Application restrictions**:
   - For now, leave unrestricted while testing, OR set up separate
     Android (package name + SHA-1) and iOS (bundle ID) restricted keys
     for production - **do not ship an unrestricted key to production**,
     since it can be extracted from the app binary and abused.
6. Paste the key into `lib/utils/constants.dart`:
   ```dart
   static const String googlePlacesApiKey = 'YOUR_REAL_KEY_HERE';
   ```

## 6. Platform permissions

**Android** - edit `android/app/src/main/AndroidManifest.xml`, add above `<application>`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**iOS** - edit `ios/Runner/Info.plist`, add inside the outer `<dict>`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to find nearby mosques and the Qibla direction.</string>
```

## 7. Run it

```bash
flutter run
```

Pick an Android emulator (with Google Play services) or a real device.
For iOS you'll need a Mac with Xcode installed - `flutter run` from the Mac,
or `open ios/Runner.xcworkspace` to run via Xcode directly.

## Using the app

- **Mosques tab**: grants location permission on first launch, shows the 5
  namaz times, then lists nearby mosques with distance + Jummah status.
- Tap **Add time** on any mosque with no Jummah time yet -> submits for
  admin review.
- Tap **Directions** on any mosque -> opens Google Maps navigation.
- **Qibla tab**: shows a compass that rotates a Kaaba-icon marker to always
  point toward Mecca; turns green when your phone is correctly aligned.
- The small grey admin icon (bottom-right, floating) -> sign in with your
  admin email/password -> see all pending submissions -> Approve/Reject.

## Known limitations / next steps worth considering

- Prayer-time calculation `method` in `prayer_times_service.dart` defaults
  to method 1 (Karachi/South-Asia convention) - check this matches what
  your users expect regionally, Aladhan supports many other authorities.
- The admin entry point (floating grey icon) is intentionally unglamorous
  for an MVP - consider moving it to a proper settings menu, or gating the
  whole app behind a splash screen check instead.
- No pagination/caching layer yet if a user opens the app offline - Places
  API and Aladhan API both need connectivity on each load.
- Consider adding push notifications (Firebase Cloud Messaging) ~15
  minutes before Jummah time for mosques a user has "favorited" - a
  natural next feature once this base is working.
