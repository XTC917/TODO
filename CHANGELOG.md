# Changelog

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
