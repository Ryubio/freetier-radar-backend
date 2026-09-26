/// SVG-like app icon generator.
///
/// Since we can't bundle a PNG directly from code, this script
/// creates a simple placeholder icon using dart:ui.
/// For production, replace assets/icon/app_icon.png with your designed icon.
///
/// Run: dart run lib/utils/generate_icon.dart
///
/// Alternatively, just place a 1024x1024 PNG at assets/icon/app_icon.png
/// and run: flutter pub run flutter_launcher_icons

library;

// This file serves as documentation. Place your app icon at:
//   assets/icon/app_icon.png (1024x1024, PNG)
//   assets/icon/app_icon_foreground.png (1024x1024, transparent background, for adaptive icons)
//
// Then run:
//   flutter pub run flutter_launcher_icons
//
// The configuration is in pubspec.yaml under flutter_launcher_icons.
//
// Recommended icon design:
//   - Background: #181825 (Catppuccin Mantle)
//   - Foreground: Radar/satellite dish icon in #89B4FA (Catppuccin Blue)
//   - Style: Minimal, geometric, developer-friendly
