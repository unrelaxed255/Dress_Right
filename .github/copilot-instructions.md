## Quick orientation for AI coding agents

This Flutter app (DressRight) is a mobile app for uniform inspection/SRR reminders. Keep guidance short and specific to this repo so contributors can be productive immediately.

- Project root: uses Flutter (see `pubspec.yaml`). Key entry: `lib/main.dart`.
- State management: simple Provider usage. Theme state lives in `lib/providers/theme_provider.dart` (uses `shared_preferences`).
- Theme system: centralized in `lib/theme/app_theme.dart` with color maps `_lightColors`/`_darkColors` and Material 3 settings.
- Notifications: `lib/services/notification_service.dart` implements a singleton wrapper around `flutter_local_notifications` and timezone handling. Initialize it before `runApp()` (see `main.dart`).
- Screens: `lib/screens/` contains UI; `splash_screen.dart` drives startup flow and transition to `home_screen.dart`. `settings_screen.dart` contains many app workflows (AFI download, schedule reminder, inspector info) and examples of shared_preferences, http, path_provider, and syncfusion PDF viewer usage.

Developer workflows and commands
- Standard Flutter commands apply. From the repo root use:
  - flutter pub get
  - flutter run (or run from IDE)
  - flutter test (unit/widget tests live in `test/`)
- Special notes: the app uses `flutter_native_splash`. The native splash is removed in `main.dart` after `runApp()`; don’t remove the `FlutterNativeSplash.remove()` call unless adjusting startup flow.

Project-specific conventions & patterns
- Singletons for platform services: `NotificationService` is a manual singleton (private constructor + factory). Prefer this pattern for platform wrappers.
- Preferences: feature flags and small state are stored via `SharedPreferences` (keys like `isDarkMode`, `insp_name`, etc.). Search `shared_preferences` usages to find persisted keys.
- Navigation: mostly Navigator.push/replace with MaterialPageRoute; a global `navigatorKey` exists in `lib/main.dart` and can be used for deep linking or background navigation from notifications.
- Assets: images under `assets/images/` are referenced directly (e.g., `assets/images/dress_right_text.png`). pubspec lists the folder—add assets there and then to `assets/images/`.
- Theming: use `AppTheme.buildTheme(isDark: true/false)` where possible. `ThemeProvider` toggles `themeMode` by persisting `isDarkMode`.

Integration points and external dependencies
- Notifications: `flutter_local_notifications` + `timezone`. Scheduling uses `zonedSchedule` with `tz` local location `America/New_York` set in `notification_service.dart`. If you change timezone behavior, update that file.
- PDF viewing & downloads: `syncfusion_flutter_pdfviewer` + `http` + `path_provider`. Downloads are saved to app documents directory (see `settings_screen.dart`).
- Native splash: `flutter_native_splash` configured in `pubspec.yaml`.

Files to inspect for context/examples
- `lib/main.dart` — app entry, provider wiring, notification init, navigatorKey
- `lib/services/notification_service.dart` — service singleton and scheduling API
- `lib/providers/theme_provider.dart` — persisted theme flag and ChangeNotifier pattern
- `lib/theme/app_theme.dart` — color system & ThemeData construction (light/dark maps)
- `lib/screens/settings_screen.dart` — real-world examples of HTTP download, file IO, local persistence, notifications, and custom dialogs
- `lib/screens/splash_screen.dart`, `lib/screens/home_screen.dart` — startup and UI patterns

When editing or adding code
- Preserve existing state keys (search for `isDarkMode`, `insp_*`, `srr_reminder_`) to avoid breaking migrations.
- Follow existing patterns: Provider for small app state, singletons for platform services, Navigator for routing. Avoid introducing a new global state container unless necessary.
- Tests: add unit/widget tests under `test/` following the existing test scaffold (`widget_test.dart`). Focus on logic-heavy modules (services, providers) rather than visual widgets.

If you need to run or debug behavior not visible in code
- To test notifications locally, run on a real device or emulator with notification permissions. Use `NotificationService().showImmediateNotification(...)` to trigger a test notification.
- To reproduce AFI download behavior, ensure network access and inspect logs from `settings_screen.dart` for HTTP status handling.

Concise examples
- Toggle theme: inspect `lib/providers/theme_provider.dart` — toggleTheme updates `SharedPreferences` key `isDarkMode` and calls `notifyListeners()`.
- Schedule reminder: `SettingsScreen._scheduleReminder()` computes an ID from `when.hashCode` and calls `NotificationService().scheduleInspectionReminder(...)` with payload `srr_reminder_<id>`.

If something is missing or unclear, ask for which area to deepen (build scripts, CI, test patterns, or release notes).
