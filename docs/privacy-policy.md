# Privacy Policy — Hanahuac

**Effective date:** 2026-06-21
**Last updated:** 2026-06-21

This Privacy Policy describes how the Hanahuac app ("Hanahuac", "the app", "we") handles
information. The short version: **Hanahuac collects no personal data, transmits nothing off your
device, and shares nothing with anyone.**

Hanahuac is an open-source geography learning app. Its source code is public, so the claims below
can be independently verified.

---

## Summary

- **No data collected.** Hanahuac does not collect, store, or process any personal data about you.
- **Fully offline.** The app makes no network connections. It does not access location services,
  the camera, the microphone, your photo library, or send notifications.
- **No tracking.** There is no analytics, advertising, or tracking of any kind.
- **On-device only.** Your learning progress and preferences live solely in local storage on your
  device.
- **No sharing.** Because no data leaves your device, nothing is ever shared with third parties.

---

## Information We Collect

**None.** Hanahuac does not collect any personal or usage information.

The app contains no networking code: it makes no HTTP requests and opens no network connections, so
there is no mechanism by which data could be transmitted off your device.

Hanahuac also does not request or use any of the following device capabilities or permissions:

- **Location** — no location services are used. (Map content is drawn from geographic data bundled
  with the app; the app never reads your device's location.)
- **Camera and microphone** — never accessed.
- **Photo library** — never accessed.
- **Notifications** — the app does not request notification permission or send notifications.
- **Contacts, calendars, health, or other personal data** — never accessed.

## On-Device Storage

Your learning progress (such as quiz history and review cards) and your app preferences are stored
**only on your device** using the operating system's local on-device database (Apple SwiftData).
This data never leaves your device under the current shipped configuration.

You remain in full control of this data: deleting the app removes its on-device storage.

## iCloud / CloudKit Sync

Hanahuac includes a CloudKit-ready architecture for optionally syncing learning progress across a
user's own devices via Apple iCloud. **This feature is currently disabled and is not active in
shipped builds.** It is gated behind a compile-time flag (`CLOUDKIT_SYNC`) that is not defined in
released builds, so the app does not connect to iCloud and does not transmit any data to Apple's
CloudKit service.

If this functionality is ever enabled in a future release, this Privacy Policy will be updated
beforehand to describe what is synced and how iCloud handles that data.

## Third-Party SDKs, Analytics, Tracking, and Advertising

Hanahuac contains **no third-party software development kits (SDKs)**. It uses **no** analytics,
crash-reporting, advertising, or tracking services (for example, no Firebase, Crashlytics, Google
Analytics, Amplitude, Mixpanel, Sentry, Facebook, or similar). The app has zero external
dependencies and relies only on Apple's first-party frameworks.

## Data Sharing

**We share no data.** Because Hanahuac collects no data and makes no network connections, there is
nothing to share, sell, or disclose to third parties, advertisers, or data brokers.

## Children's Privacy

Hanahuac collects no personal information from anyone, including children. The app is safe to use
without any data being gathered.

## Changes to This Policy

If the app's data practices ever change, this document will be updated and the "Last updated" date
above will be revised. The current version is always available in the project's public repository.

## Contact

Hanahuac is an open-source project. For questions about this Privacy Policy, please open an issue on
the project's GitHub repository:

<https://github.com/beyerja/ProjectHana/issues>
