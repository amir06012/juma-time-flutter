import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared brand palette so screens/widgets outside main.dart (which owns the
/// app's ThemeData) can still color individual elements consistently.
class AppColors {
  static const mehndiGreen = Color(0xFF5E7A42);
  // Darker end of the mehndiGreen gradient used on the location/weather
  // card and mosque cards - kept proportional to mehndiGreen itself so the
  // two shades still read as one gradient rather than two unrelated greens.
  static const mehndiGreenDark = Color(0xFF3C5828);
  static const lightGold = Color(0xFFC9A94F);
  static const richBlack = Color(0xFF1B1B1B);
  static const creamBackground = Color(0xFFF0EDE0);
}

/// Arabic-influenced typography for branding/heading text, kept separate
/// from the app's default Poppins body font (which stays on Latin text like
/// addresses and button labels for legibility at small sizes).
class AppFonts {
  /// Amiri - a classic Naskh-style calligraphic face - for titles, mosque
  /// names, and other short display text (renders both Latin and Arabic).
  static TextStyle heading({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) =>
      GoogleFonts.amiri(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  /// Noto Naskh Arabic - for actual Arabic-script text, since Amiri's Latin
  /// glyphs are tuned for pairing with Arabic rather than for Arabic itself.
  static TextStyle arabic({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) =>
      GoogleFonts.notoNaskhArabic(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
}

class ApiKeys {
  // Replace with your real Google Places API key.
  // In Google Cloud Console, restrict this key to your Android package name
  // + SHA-1 and your iOS bundle ID, so it can't be reused if extracted from
  // the app binary.
  static const String googlePlacesApiKey = 'AIzaSyBDQoBUCc2DvVqnFZTKHAVxo4fTGEx64B8';
}

class AdminConfig {
  // Emails allowed to log in and approve/reject Jummah time submissions.
  // Must exactly match the allowlist inside your Firestore security rules
  // (see README) - this list alone does NOT enforce security, the
  // Firestore rules do. This is just used for the in-app login check.
  static const List<String> adminEmails = [
    'your-admin-email@example.com',
  ];
}
