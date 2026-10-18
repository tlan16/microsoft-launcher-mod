# Morphe attempt: disable "Enable Automated Version Update" dialog (MS Launcher 6.260402.0.1178950)

Curated historical notes: binaries, template/tool source, logs and raw evidence are excluded. Build and static-check results below describe earlier local work, not validation of this snapshot. See ../../README.md for provenance, missing dependencies and limitations.

Result: SUCCESS (build + patch + static verification; NOT runtime-tested, nothing installed).
Output APK: out/MSLauncher-6.260402-noAadPrompt.apk  (sha256 7051263b0598b38ecdbe4e655950cc3a39ddec62e633014cb28ad534244e811c)
Historically signed with a throwaway local key; key, alias and credential details are omitted. Future signing requires a separately provisioned persistent key in /app/signing. Historical output had a DIFFERENT signature than the original; cannot be installed as an update over the Play/APKMirror build (uninstall first = data loss) and
signature-dependent features (Intune/MSAL broker, Play licensing) may break. Unverified.

## Research
- Morphe = ReVanced fork. Tools: morphe-desktop 1.18.1 (CLI/GUI jar, dl/), morphe-patcher (lib), morphe-patches (official; YouTube/Reddit/Music only -> no MS Launcher patches, so custom patch required), morphe-patches-template.
- Docs: research/patcher_*.md (patch anatomy, fingerprinting). Template build needs GitHub Packages auth (GITHUB_TOKEN env, GITHUB_ACTOR any non-empty).
- .mpp = jar with classes.dex + resources + manifest.

## Patch
msl-patches/patches/src/main/kotlin/app/mslauncher/patches/aadprompt/AadUpdatePromptPatch.kt
- Fingerprint (obfuscation-resistant): public static void (WeakReference, Runnable) that loads resource literal layout/view_appcenter_checkupdate_reminder (matches Ea.e.b).
- Injects at index 0: `if (p1 != null) p1.run(); return` -> skips dialog builder, continuation still runs (same as the Not-now/Enable continuation). Manual update/auth impact is static reasoning only, not device-verified.

## Attempts (ATTEMPTS.md has the log)
1. Gradle w/o token: plugin app.morphe.patches not resolvable (GitHub Packages 401) -> build1.*
2. With GITHUB_TOKEN: compile error, missing import app.morphe.patcher.resource.ResourceType -> build2.*
3. Fixed -> BUILD SUCCESSFUL (build3.*), mpp: msl-aad-patches.mpp
4. Historical exclusive patch attempt selected "Disable AAD update prompt" in full-bytecode mode; no failed patches were reported. Raw invocation and signing details are omitted.
5. Verification: rea inspect-android-method on patched APK, Ea.e.b decompiles to `if (runnable != null) runnable.run();` (verify_Ea_e_b.stdout).
