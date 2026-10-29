# Validation — 29 October 2026

## Passed in the authoring environment

- Syntax-tree checks on 15 modified/new Swift files. Existing parser limitations in the upstream map file were compared against the unchanged base.
- Xcode OpenStep project parsed successfully; ZIPFoundation package/product/framework references resolve within the project.
- Info.plist, entitlements, shared scheme XML, package resolution JSON, asset catalogue JSON, and image references parsed/checked.
- `git diff --check` passed.
- Base source verified at StikDebug commit `17b1e1d90d602a228de663a10efa987a9f9e547b`.

These are structural checks, not Swift type checking, compilation, or runtime tests.

## Added native tests — not run here

`StikDebugTests/LooneyShiftTests.swift` contains:

- A synthetic JPEG carrying GPS, camera model and capture-date metadata; export must remove them, retain dimensions, and preserve the original input.
- A synthetic IPA with app metadata and a framework; inspection must return expected fields without executing its fake binary.
- A ZIP path-traversal entry that must be rejected.
- Malformed provisioning-profile rejection.

The environment is Linux and has neither Xcode nor the Apple SDK. The upstream static idevice library is for device builds, so these tests require a suitable Apple build/test setup. No native tests, archive build, signed installation, UI screenshots, or phone validation were performed here.

## Required phone acceptance checks

1. Signed app installs as LooneyShift without replacing StikDebug.
2. New logo and map-first tab appear; Settings and Tools work.
3. Import the user's pairing record, enable LocalDevVPN, connect and mount developer support files.
4. Shift to a coordinate and verify it in another app; restore and verify real location returns.
5. Exercise bookmark search and route simulation; check background/foreground transitions and connection loss.
6. Import a known GPS-tagged photo, share its cleaned copy and independently inspect output metadata.
7. Inspect a known IPA and compare its bundle/version/profile information with trusted desktop tools.
8. Confirm website link opens https://looney.is-a.dev/.

## Known limits

- Upstream route lifecycle/background constraints remain.
- Temporary photo exports are removed when the screen is left; save/share before navigating away.
- IPA Inspector decodes provisioning-profile claims, not executable entitlements, and does not verify certificate trust or revocation.
- The CI workflow is prepared but has not been pushed or run. No destination GitHub repository has been provided.
