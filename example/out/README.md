# Curated static demo snapshot

This allowlisted text-only snapshot copies selected investigation notes and local
Microsoft Launcher modification source from `out/`. It is not a complete workspace,
release, upstream project, or reproducible build bundle. Original `out/` files were
not modified. Historical build/static-analysis claims in copied notes were not
rerun here; no device, emulator, install, runtime or authentication validation is
claimed. Static findings leave an unresolved contradiction: the observed dialog
appears unreachable through the two identified callers in the analyzed APK.

## Included (24 files)

- Investigation: `investigation/{CONTEXT,FINDINGS,NEXT}.md` (3).
- Modern LSPosed: Java hook, manifest, strings, three Xposed metadata files,
  `build.sh` and historical `README.md` (8).
- Legacy API-82 LSPosed: Java hook, manifest, scope array, entry asset and
  `build.sh.old` (5). Superseded; script retained under its original filename.
- Morphe-compatible local patch: custom Kotlin patch and two customized Gradle
  configuration files (3); historical `README.md` and `ATTEMPTS.md` (2);
  original `LICENSE` and `NOTICE` (2).
- This snapshot README (1).

## Excluded

All private Copilot and session state; decoded APK code/resources; APKs, JARs, MPPs,
DEX/classes and other binary outputs; Gradle wrappers; keystores/signing keys;
caches, SDKs and downloaded dependencies; upstream research, template and tool
source; upstream automation; `.git`; logs, raw evidence and command histories.
Evidence IDs and absent output paths in historical notes are references only.
No downloaded upstream implementation source is included.

## Sanitization and provenance

Credential values and historical signing details were removed from demo notes
and scripts. Session/tool-state and raw-invocation details were omitted from
notes. No personal email addresses or host user paths were found in the selected
text. Public artifact hashes, package IDs and generic container paths remain.

The Java hooks and custom Kotlin patch retain their original source and comments.
Morphe build configuration derives from the local `msl-patches` customization of
the Morphe patches template. Only its two customized build/config files were
selected; the template's patch-list-generator implementation was not copied.
The demo module Gradle file removes tasks/dependencies for that omitted utility
and replaces its template author placeholder with `Local demo`.
`msl-patches/LICENSE` (GPLv3) and `NOTICE` are preserved verbatim; no affiliation
with Morphe is claimed. No additional license is asserted for the LSPosed hooks.

## Missing dependencies and signing

Nothing here downloads, builds or signs automatically as part of the snapshot.
Build scripts were syntax-checked only, not executed. They require separately
supplied JDK, Android API 34 SDK/build-tools 34.0.0, R8 8.9.35 and appropriate
Xposed API libraries (modern 102.0.0 or legacy 82) at the paths they reference.

Both LSPosed scripts now require an existing persistent
`/app/signing/module.keystore` and environment variables
`APK_SIGNING_STORE_PASSWORD`, `APK_SIGNING_KEY_PASSWORD`,
`APK_SIGNING_KEY_ALIAS`. Passwords are passed to apksigner by environment
reference, not command-line literal. Keys are never generated or copied into
output directories; `/app/signing` must be mounted/provisioned separately.
Do not place keys or real credentials inside this snapshot.

Morphe tooling, Gradle distribution/wrappers, root template scaffolding, version
catalog and dependency artifacts are omitted. Customized Gradle settings retain
plugin 1.3.4 and optional GitHub Packages credential lookup via Gradle properties
or `GITHUB_ACTOR`/`GITHUB_TOKEN`; no credentials are supplied. Historical notes
identify patcher 1.15.1 and desktop tooling 1.18.1. Restore compatible external
build infrastructure separately before attempting a build; the reduced
configuration has not been build-tested.

Hooks use build-specific obfuscated names; patch fingerprints and compatibility
are likewise version-limited. Re-signing a launcher changes its identity and may
break upgrades/authentication; uninstalling an existing launcher can lose data.
No installation, build, signing, download or device action is authorized by
merely browsing this example.
