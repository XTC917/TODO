# Changelog

## v2.6.1

### Fixed
- Recurring schedules: completing one occurrence no longer grays out all future virtual instances (each day keeps its own completion state).
- Recurring series end date (`repeatUntil`) is stored in the database instead of being appended to the user-visible note.
- Recurring **only this occurrence** edits (e.g. custom reminder) persist after restarting the app; edit form still shows the series repeat rule (weekly/daily) instead of “one-time”.

## v2.6.0

### Changed
- Unified localized **app display name**: English `JUJU Schedule`, 简体中文 `JUJU日常`, 한국어 `JUJU 일정` (in-app l10n, About, Android launcher).
- Android **application ID / package name** → `com.juju.schedule` (all locales).
- Database export embeds appearance & focus-preset settings inside the `.sqlite` file (single-file backup on Android); import restores them automatically. Legacy `.settings.json` sidecar still supported on desktop.

## v2.5.5

### Changed
- New todo **deadline** default time is **23:59** (was 18:00).
- Focus custom duration picker: minutes **0–60** (every minute, was 5-minute steps).
- Focus end: in-app summary dialog + **vibration**; **notification** when pomodoro completes in background.
- **Normal / Strict** focus modes (text toggle above pomodoro/stopwatch, left-aligned; preference remembered):
  - **Strict**: leaving the app during an active session triggers reminders every 10s (max 5); after 1 minute away the session ends with **0 min** recorded (marked incomplete in history).
- Focus records show **普通/严格** (normal/strict) enforcement type.
- Focus page layout: duration presets (max **9**) below task picker; **+ Add custom duration** as text under chips; records link at bottom; page scrolls when content overflows.
- Focus session **persists** across background/kill (wall-clock timer); strict-mode reminders use **scheduled notifications** when app is backgrounded.
- Settings → Notifications: **autostart** prompt on all Android devices (same pattern as battery optimization).
- Normal/Strict toggle hidden while a focus session is active.

## v2.5.4

### Changed
- Timeline widget: shows all upcoming timeline items (schedules + timed todos), with completion checkbox.
- Todo widget: list rows include date and time; compact 2×2 shows 3 items and + button layout fixed; widget titles shortened to **JUJU 待办 / JUJU 日程** (no "Schedule").
- All **+** entry points (FAB, widgets) open the same default add-task form as Home (Todo/Schedule picker).
- Add-task form: title and note fields have a ✓ button to dismiss the keyboard before picking date/time.
- Quick Add **Edit** opens the same add-task form with parsed fields prefilled (type not locked).
- Quick Add deadline parsing: phrases like **截止6点** / **6点前完成** map to todo + deadline mode with correct end time; **下午三点截止** → 15:00 (supports **的** between period and time). English **due by 3 pm** / **by 8 tonight** aligned to the same rules.
- Quick Add **Edit** returns to the existing add-task form with prefilled fields (no stacked form pages).

## v2.5.3

### Added
- **Quick Add**: type a sentence (e.g. “明天下午3点和导师开会”) to parse title, date, time, and type locally — no AI, no network. Preview before save; edit opens the existing create form.
- Quick Add also parses **reminder offsets** from phrases like “提前五分钟” / “提前半小时和一小时通知我”, passed into existing `reminderOffsetsSeconds` and notification scheduling.
- Quick Add supports **Chinese and English** natural-language input based on the current app language; other UI languages show an unsupported notice.
- Quick Add recognizes explicit **Schedule / Todo** intent (e.g. 创建日程 / add a todo); preview lets you switch type before confirm — switching opens the existing add-task form with preserved fields.

## v2.5.2

### Added
- Settings → **Feedback**: opens an external form in the system browser.
- Localized feedback forms — Chinese UI uses the Chinese form; all other languages use the shared English form.

## v2.5.1

### Changed
- Todo widget: show pending todos across dates — long-term (no date) first, then by nearest date; removed x/x completion line.
- Schedule widget: show upcoming schedules in chronological order (not limited to today); non-today items include date prefix; hide slots whose end time has already passed.
- Widget titles prefixed with **JUJU Schedule** (todo, schedule, focus).

## v2.5.0

### Fixed
- Database export: checkpoint WAL before copying so recent writes are included in the `.sqlite` backup.
- Database import: reject non-SQLite files before overwrite so a bad pick cannot replace the live database.

## v2.4.9

### Added
- Recurring events: choose **this occurrence only**, **this and future**, or **all** when editing or deleting.
- Completing/checking off a recurring event affects **only that occurrence**.

### Fixed
- Deleting **this and future** on a recurring event no longer duplicates many copies on the same day.

## v2.4.8

### Changed
- Focus widget: rounded corners on the **Open focus** button.

## v2.4.7

### Fixed
- Todo widget: smoother check-off (brief ✓ state, then list refreshes ~1.4s later).
- App UI refreshes immediately when toggling todos from the home-screen widget.

### Changed
- Todo widget checkbox: circle ○ / filled ✓ instead of square boxes.
- Focus widget: pending count text matches focus duration size.

## v2.4.6

### Added
- Todo widget **2×2 compact** size: progress + 2 todos, checkbox toggle, and + to add.

## v2.4.5

### Fixed
- Todo widget checkbox: use a dedicated broadcast receiver so taps toggle completion reliably.

### Changed
- Focus widget: shows pending todo count at the top; button moved toward the bottom.
- All widgets: rounder corners (18dp).

## v2.4.4

### Added
- Todo and schedule widgets: **+** button (top-right) opens add todo / add schedule form.
- Todo widget: visible checkbox squares; tap to toggle completion (native + background sync).

### Changed
- Focus widget opens the Focus tab only (no auto-start countdown).
- Widget todo list also includes undated pending todos when today’s list is sparse.

## v2.4.3

### Added
- Settings → **桌面小组件**: step-by-step guide for adding home screen widgets.
- Todo widget: tap **○ / ✓** to check off items without opening the app.
- Onboarding sample todo: see Settings for widget setup.

## v2.4.2

### Added
- Android home screen widgets: **今日待办** (todos + completion), **今日日程** (schedule list), **专注** (focus time + one-tap start).
- Widget data syncs from the app; tap opens the relevant tab or starts a focus session.

## v2.4.1

### Added
- Appearance: accent-tinted backgrounds that follow the selected theme color.
- Custom accent and background colors via HSL sliders (continuous hue/saturation/lightness).

### Changed
- Scaffold, app bar, navigation bar, cards, and inputs now derive from the active accent or custom background.

## v2.4.0

First friend-share release with reliable Android reminders.

### Added
- Reminder module rewritten (schedule/cancel/reschedule, `[JUJU Reminder]` logs, Release ProGuard Gson rules).
- Settings → Notifications: autostart guide for Xiaomi/Redmi/POCO; battery optimization and exact-alarm prompts.

### Changed
- Test notification removed from settings; notification permission uses system settings only.
- Reminder sync is awaited on save so alarms register before leaving the app; no full reschedule on every foreground resume.

### Fixed
- Release reminders failing due to R8 + Gson (`Missing type parameter`) and MIUI background kills (autostart / battery / exact alarm).

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
