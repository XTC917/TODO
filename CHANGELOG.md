# Changelog

## v2.3.1

### Fixed
- Reminder notifications now request **exact alarm** permission (`SCHEDULE_EXACT_ALARM`) after notification permission — required on Android 12+ for `zonedSchedule` to fire on time; immediate test notifications were unaffected.
- Removed `USE_EXACT_ALARM` (alarm-clock apps only); scheduling uses `exactAllowWhileIdle` when permitted, with inexact fallback.
- Settings → Notifications adds **Allow exact alarms** button when exact permission is missing.

## v2.3.0

### Fixed (Release notification investigation)
- Added release-visible notification diagnostics (`adb logcat | findstr JUJUNotify`) to pinpoint init/permission/show/schedule failures in release APKs.
- Test notification button no longer depends on the Reminders toggle; it only calls `show()` and does not trigger reschedule.
- Added ProGuard keep rules for `flutter_local_notifications` (preventive; minify is currently off).

### Notes
- Confirmed root causes from prior releases: invalid Android icon resource name (`@drawable/...` in Dart) and background notification callback breaking plugin init in release only. Both were fixed in v2.2.5/v2.2.7; if release still fails, use logcat tags above on a fresh v2.3.0 install.

## v2.2.10

### Changed
- Initial onboarding events now follow the app language setting (not only the system locale at first launch).
- Switching language in Settings updates the 8 starter event titles when they are still the default onboarding set.

## v2.2.9

### Fixed
- Fixed first-launch onboarding seeding only inserting the welcome row: English onboarding titles exceeded the 30-character title limit, so inserts failed after the first item; limit raised to 50.
- Fixed legacy partial seeds (old builds left only “Welcome to JUJU Schedule”) being treated as complete — incomplete onboarding is now detected and re-seeded automatically.

## v2.2.8

### Changed
- Removed all demo/sample-data UI and tracking. First launch with an empty database now inserts onboarding schedules and todos (same as user-created data). They can be edited, completed, or deleted; deleted items are not restored unless app data is cleared or the app is reinstalled.
- Initial presets: 5 timeline hints (welcome, add, edit, reminder, focus) and 3 todo hints (theme, language, stats).

### Added
- `scripts/install_release.ps1` / `install_release.bat`: build release APK and install to a USB-connected phone via ADB.

## v2.2.7

### Fixed
- Onboarding presets now seed in `main()` before UI (same timing as debug), with a v3 flag so installs stuck on the old v2 marker can seed again when the database is empty.
- Repairs the broken “only Welcome left” partial seed from older builds automatically.
- Release notifications: removed the background notification callback that could make plugin `initialize()` fail in release (debug was unaffected); restored init in `main()` like debug; added missing `ActionBroadcastReceiver` in AndroidManifest.

## v2.2.6

### Changed
- Removed the sample-data toggle. On first install, a small set of onboarding schedules/todos is written once into the database; users can edit or delete them like normal tasks.
- Reduced onboarding items to 4 timeline entries + 4 todos with basic usage hints.

### Fixed
- Fixed sample-data toggle getting stuck and startup crashes caused by bulk seeding plus notification sync racing.
- Improved notification initialization timing, init success checks, test-button loading feedback, and clearer error messages.

## v2.2.5

### Fixed
- Fixed notifications not showing after granting permission: Android icon must be the drawable name (`ic_notification`), not `@drawable/ic_notification`, which caused plugin init and `show()` to fail silently in release builds.
- Fixed statistics focus ranking hiding "View details" when there were fewer than 3 (day) or 5 (week/month/year) entries — the detail sheet is now always reachable when focus data exists.

## v2.2.4

### Changed
- Sample data is now stored in the database and behaves exactly like user-created tasks (edit, delete, toggle).
- Sample data is enabled by default on first install again.

## v2.2.3

### Fixed
- Improved notification permission detection with permission_handler and more reliable scheduling on OEM ROMs.
- Notifications no longer skip scheduling when hasPermission() falsely returns false.
- Added in-app "Allow notifications" button and exact-alarm hint in notification settings.
- Fixed release background notification handler registration.

### Improved
- Sample/demo items now show a "Sample" badge; default sample data is off for new installs.
- Sample items remain read-only by design (not stored in your database).

## v2.2.2

### Fixed
- Fully decoupled database CRUD from notification sync; notification failures no longer block or fail saves/deletes.
- Notification sync now runs asynchronously after DB writes instead of in the same await chain.
- Save form only reports failure for database errors, not navigation or notification side effects.
- Hardened notification permission checks with safe initialize, retries, and refresh on settings resume.

## v2.2.1

### Fixed
- Fixed database import leaving SQLite closed so create/edit/delete failed in release builds.
- Fixed notification permission status not refreshing after granting in system settings.
- Fixed notification body builder crashing scheduled saves when localization was unavailable.

## v2.2.0

### Added
- Added built-in sample schedules and todos for first-time beta onboarding.
- Added Show Sample Data toggle in General settings with hide confirmation.

### Improved
- Sample data is merged at display time and never written to the user database.

## v2.1.6

### Added
- Added multi-level Settings navigation with dedicated sub-pages.
- Added Focus settings for default countdown, display mode, and keep screen awake.

### Improved
- Redesigned Settings homepage with category rows and current status labels.
- Split Settings into separate files for easier maintenance and extension.
