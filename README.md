# LooneyShift

**Location-first iPhone utility — live location simulation, photo privacy, and IPA inspection.**

[Website](https://looney.is-a.dev/) · [Download IPA](https://github.com/chatLooney/LooneyShift/actions/runs/40846139295) · [Source](https://github.com/chatLooney/LooneyShift) · [Report a bug](https://github.com/chatLooney/LooneyShift/issues)

> **Build available:** An unsigned iPhone IPA has been built successfully by GitHub Actions. It must be signed using your own signing setup before installation. This build has **not** been verified on an iPhone. The repository is currently private; only authorised GitHub accounts can access its downloads.

## Download LooneyShift IPA

**Latest verified build:** [Build LooneyShift IPA — successful run #2](https://github.com/chatLooney/LooneyShift/actions/runs/40846139295) (29 October 2026).

1. Sign into GitHub with access to this repository.
2. Open the linked workflow run and scroll to **Artifacts**.
3. Download **`LooneyShift-unsigned`** (ZIP archive).
4. Extract **`LooneyShift-unsigned.ipa`** from the archive.
5. Sign the IPA with your own authorised signing method, then install it on your iPhone.

**Artifact details:** 7,014,170-byte ZIP artifact · generated 29 October 2026 · scheduled GitHub expiry 27 January 2027. GitHub Actions artifacts are temporary; if the artifact expires, rebuild it under [Actions](https://github.com/chatLooney/LooneyShift/actions/workflows/build_ipa.yml). **There is no published GitHub Release yet.** Do not use the Releases page as a purported IPA download until a release with a real IPA asset exists.

The downloadable IPA is *unsigned*, not a jailbreak, certificate, or ready-to-install App Store package. You must provide signing yourself. IPA builds are not proof that location simulation will function on every iOS version.

## Features

### Location Shift
- Map-first interface, place search, coordinates, saved bookmarks and route simulation.
- Connection status, pairing-file setup, device support files and Connect action.
- **Shift Location** to start location simulation and **Restore Location** to stop it.
- No jailbreak is required for the intended paired-device workflow, but compatibility and reliability depend on iOS, device services and correct setup.

### Photo Privacy
- Choose an image using the iOS system picker.
- Export a freshly encoded JPEG to strip GPS and camera/capture metadata.
- Keep the original image unchanged. JPEG export removes transparency, Live Photo motion, animation and HDR.

### IPA Inspector
- Inspect a local IPA archive without executing or installing it.
- Read app version, bundle identifier, minimum iOS, embedded frameworks, usage descriptions, available provisioning profile claims and SHA-256 checksum.
- Does not validate signing trust/revocation or decode all executable entitlements.

### Tools
- Device details, connection and pairing settings, app-expiry information and console.

## Compatibility and limitations

Designed for physical iPhones with a compatible developer-services/pairing setup. It is **not** a universal guarantee of location spoofing on iOS 26 or other releases. Some location-consuming apps may reject simulated location. Route/background continuity is subject to the iOS lifecycle; restarting the device may be necessary if restore fails. The build completed in CI, but the device acceptance checklist in [VALIDATION.md](VALIDATION.md) has not been completed.

## Set up on iPhone

1. Install a properly signed IPA and enable Developer Mode if your signing method requires it.
2. Enable the loopback VPN used by the device connection flow (the upstream configuration uses LocalDevVPN).
3. Import your own pairing file under Settings; this app cannot read pairing files stored inside another app.
4. Connect while the phone is unlocked and allow support files to download.
5. Select a point on the map, shift location, verify independently in another app, then restore and check that the real location returns.

Keep pairing records and signing credentials private. The app should be used only on devices you control and in accordance with app and service terms.

## Build it yourself

Requires a Mac with Xcode 26 or newer, signing for installation and access to the repository.

```bash
python3 scripts/fetch_idevice.py
xcodebuild archive \
  -project StikDebug.xcodeproj \
  -scheme StikDebug \
  -configuration Release \
  -archivePath build/LooneyShift.xcarchive \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

The internal Xcode project/scheme name remains `StikDebug` for build compatibility; the installed display name and bundle identifier are LooneyShift. The repository includes the [IPA build workflow](.github/workflows/build_ipa.yml); run it manually with **Run workflow** or push to `main`. Build artifacts appear under the corresponding Actions run, not automatically under Releases. Do not commit developer certificates, signing keys or pairing files.

## Project status

- ✅ iPhone archive and unsigned IPA packaging succeeded in GitHub Actions (run #2).
- ✅ Source includes location, photo-export and IPA-inspection screens.
- ⏳ Signed IPA installation and actual iPhone testing not yet verified.
- ⏳ Native test suite and end-to-end location restoration still require device validation.
- ⏳ Public GitHub Release with a permanent downloadable IPA has not been published.
- Not yet included: joystick, GPX route management, timers, face/plate redaction, IPA comparison and media conversion.

See [VALIDATION.md](VALIDATION.md) for test coverage and known limitations. Bug reports: [Issues](https://github.com/chatLooney/LooneyShift/issues).

## License

LooneyShift source is distributed under **GNU AGPL-3.0**, with upstream and other third-party terms retained. See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Credits and reference

LooneyShift builds on **[StikDebug](https://github.com/StikDebug/StikDebug)** (base commit `17b1e1d90d602a228de663a10efa987a9f9e547b`). Original copyrights and licence notices remain in the source and third-party notices.
