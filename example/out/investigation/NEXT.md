# NEXT
1. Ask user for installed launcher versionName/versionCode/SHA (or pull APK split) - the dialog may come from a different build; compare Ea.e.b / yb.d.f there with `rea inspect-android-method`.
2. Provide signing key in /app/signing (APK_SIGNING_DIR); then re-sign Morphe output on a copy (apksigner) instead of throwaway key.
3. Trace K / yb.t chain cadence (LauncherActivity ~L5100-5200) - low value given F16.
4. Install/deploy of Morphe APK or LSPosed module needs explicit user approval (not done).
Both mods target the statically unreachable-in-this-build dialog builder. Effectiveness and safety remain unverified on devices; these notes do not establish runtime behavior.
