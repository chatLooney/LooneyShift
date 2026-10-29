# LooneyShift

**Location spoofing first.** An iPhone app derived from [StikDebug](https://github.com/StikDebug/StikDebug), with photo privacy and IPA inspection in a secondary Tools tab.

Website: **https://looney.is-a.dev/**

Repository: https://github.com/chatLooney/LooneyShift

## This first source version

- Opens on the location map, with search, coordinate import, bookmarks, and route simulation inherited from StikDebug.
- Connection banner, connect action, and shortcut to pairing settings.
- Shift Location and Restore Location controls.
- Photo Privacy: import a photo with the system picker, decode and re-encode a still JPEG, verify removal of GPS/camera/capture-date metadata, then share a copy. The original is unchanged. Exports lose transparency, Live Photo motion, animation, and HDR.
- IPA Inspector: local ZIP metadata analysis, bundle ID/version/minimum iOS, declared usage descriptions, embedded framework names, provisioning-profile details and allowed entitlements, signature-resource presence, and streamed SHA-256. No installation or execution. Profile claims are not cryptographically verified; executable entitlements are not decoded yet.
- LooneyShift app icon, distinct bundle ID `dev.looney.LooneyShift`, and `looneyshift://` URL scheme.
- Original device details, app expiry and console screens remain under Tools.

This is **source code, not a compiled or device-tested IPA**. StikDebug location simulation already works on the user's iPhone 15 Pro running iOS 26; this modified app still needs its own build and device test. Native Swift/Xcode tests have not run in the Linux authoring environment. See VALIDATION.md.

## Build on a Mac

1. Install Xcode 26 or newer, open `StikDebug.xcodeproj`, and select the `StikDebug` scheme. The internal project/scheme/module names are retained to preserve the upstream build structure; the installed display name is LooneyShift.
2. Run `python3 scripts/fetch_idevice.py` in the project folder to fetch and verify the pinned upstream device library. Allow Swift Package Manager to resolve the dependencies, including ZIPFoundation 0.9.20.
3. Select your development team and an available bundle ID if necessary. App Groups are not needed for the visible features in this version.
4. Select a connected iPhone and build/run. The bundled `libidevice_ffi.a` is inherited unchanged from upstream and targets physical devices; simulator builds may require rebuilding idevice for the simulator.

## Build an unsigned IPA on GitHub

Upload this complete source tree to a repository you control, including `.github/workflows/build_ipa.yml`. In Actions, run **Build LooneyShift IPA**. The workflow archives on a macOS runner and uploads `LooneyShift-unsigned.ipa` as an artifact. It does not publish a release or modify your website. Sign the downloaded IPA using your existing iOS signing setup before installation.

The build workflow runs when this source is pushed to the main branch. Do not upload signing keys, pairing records, or personal certificates to source control.

## Setup on the iPhone

1. Install the signed LooneyShift app and enable Developer Mode if required by your signing method.
2. Enable your working loopback VPN (the upstream setup uses LocalDevVPN).
3. Open Settings in LooneyShift and import the device's pairing file. LooneyShift uses its own app container, so it cannot automatically read StikDebug's imported pairing file.
4. Let the developer support files download, then tap Connect. Keep the phone unlocked during initial setup.
5. Select a place on the map, tap Shift Location, and check a location-consuming app. Test Restore Location before relying on it.

Background operation and route persistence depend on iOS lifecycle behaviour. A successful local 'active' status is not proof that another app is receiving the simulated location. If restoration fails, reconnect and retry; a device restart may be needed. This project makes no claim of being undetectable by other apps.

## Current scope

The first version retains upstream route behaviour. New joystick controls, GPX route management, timers, face/plate redaction, IPA version comparison, and media conversion are not implemented. The original debugging implementation remains in source where it supports shared dependencies; its app-launch/JIT screen is not a main tab.

## Licence and attribution

GNU AGPL-3.0; see LICENSE and THIRD_PARTY_NOTICES.md. Original author notices are preserved. Base upstream commit: `17b1e1d90d602a228de663a10efa987a9f9e547b`. LooneyShift adds its own navigation, branding, metadata-cleaning tool, IPA inspector, connection guidance, and build packaging. The bundled idevice dependency and other upstream dependencies retain their respective licences.
