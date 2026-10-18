Gradle build with app.morphe.patches plugin 1.3.4 failed: plugin only on GitHub Packages (needs PAT). See build1.stderr
Attempt 2: gradle with GITHUB_TOKEN env (GITHUB_ACTOR=token); token never logged
Attempt 2 result: auth OK, compile error: unresolved ResourceType (need import). Kotlinc 2.4.21 also downloaded to tools/ (unused fallback).
Attempt 3: gradle buildAndroid OK -> msl-aad-patches.mpp; running morphe-desktop patch (no -i install)
Attempt 3 done OK; attempt 4 patch OK; verified via rea. See README.md
Session 2: identity verified, signing dir empty, throwaway keys flagged (see ../../investigation/FINDINGS.md F17).
