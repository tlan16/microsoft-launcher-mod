# LSPosed attempt: disable "Enable Automated Version Update" dialog (MS Launcher 6.260402.0.1178950)

Curated historical notes: referenced binaries, SDKs, libraries, logs and evidence are excluded. Build and static-check results below describe earlier local work, not validation of this snapshot. See ../../README.md for limitations and demo signing requirements.

UPDATE (api 102): module rebuilt on the modern libxposed API 102.0.0 (io.github.libxposed:api, Maven Central; 101.0.0, 101.0.1, 102.0.0 exist).
Output: out/NoAadPrompt-lsposed-api102.apk. The earlier legacy API-82 build is kept in legacy-api82/ (superseded).
Result: BUILT + statically checked only; NOT runtime-tested (no adb/device/emulator, no /dev/kvm). Nothing installed anywhere.

## Modern API packaging (from api-102 sources, lib/api102/src, package-info.java)
- Entry class extends io.github.libxposed.api.XposedModule, listed in META-INF/xposed/java_init.list (src: meta/META-INF/xposed/)
- META-INF/xposed/module.prop: minApiVersion=102, targetApiVersion=102, staticScope=true; scope.list: com.microsoft.launcher
- No xposedmodule meta-data / xposed_init (legacy only). android:label/android:description in manifest. Module minSdk 26 (API requirement; launcher minAPI is 24, so devices on 24-25 are unsupported by this module).
## Hook (src/com/local/noaadprompt/ModuleMain.java)
onPackageReady(PackageReadyParam): if package == com.microsoft.launcher -> param.getClassLoader().loadClass("Ea.e").getDeclaredMethod("b", WeakReference, Runnable) -> hook(m).intercept(chain -> { Runnable r = (Runnable) chain.getArg(1); if (r != null) r.run(); return null; }) (never calls proceed -> original dialog code is skipped). Logs via XposedModule.log(). Class/method missing -> warning log, no-op. Default exception mode "protective": if the hooker throws before proceed, the framework continues with the original method (dialog would show).
Same semantics as the Morphe patch. Target verified statically in original APK (/app/out/investigation FINDINGS F3-F6, F13).
## Use (manual, by user)
Install the APK on a device with an LSPosed build supporting API 102 (older LSPosed that only supports legacy/101 may not load it: unverified), enable it with scope com.microsoft.launcher, force-stop the launcher, check LSPosed log for "hooked Ea.e.b".
## Build: ./build.sh  (tools in sdk/, lib/api102/classes.jar, lib/r8.jar; all inside workspace, no apt)
Attempts: build3 failed (androidx.annotation.NonNull not on classpath -> annotation removed); build4 OK, apksigner verify OK; dex contains Ea.e/onPackageReady/intercept strings.
(JDK 25 javac --release 17; D8 from r8 8.9.35 since build-tools 34 d8 crashes, see legacy-api82/build1.*)

---- Earlier legacy API-82 notes ----

Result: module BUILT and statically checked. NOT runtime-tested: no adb/device/emulator (no /dev/kvm) in this container, and nothing was installed anywhere.
Output: out/NoAadPrompt-lsposed.apk (package com.local.noaadprompt, legacy Xposed API 82, scope com.microsoft.launcher).
Historical module used a throwaway signing identity; keys and credential values are omitted. Demo scripts instead require /app/signing/module.keystore and APK_SIGNING_STORE_PASSWORD, APK_SIGNING_KEY_PASSWORD and APK_SIGNING_KEY_ALIAS environment variables. They neither generate nor copy keys. Hooking leaves the launcher APK signature unchanged; upgrade/auth behavior still requires device validation.

## Hook (src/com/local/noaadprompt/Hook.java)
handleLoadPackage for com.microsoft.launcher -> hook `Ea.e.b(java.lang.ref.WeakReference, java.lang.Runnable)` (static, returns void) with XC_MethodReplacement: run args[1] if non-null, return null.
Same semantic as the Morphe patch. Names are obfuscated => valid for this build only; if class `Ea.e` is missing it logs "[NoAadPrompt] class Ea.e not found" to the LSPosed log and does nothing.
Target was verified statically in the original APK (/app/out/investigation FINDINGS F3-F6, F13).

## Use (manual, by user)
Install out/NoAadPrompt-lsposed.apk on a rooted device with LSPosed (Zygisk/Riru), enable module, tick scope "com.microsoft.launcher", force-stop launcher. Check LSPosed log for "hooked Ea.e.b".

## Build (reproducible): ./build.sh
Tools downloaded into workspace (no apt): sdk/ (cmdline-tools 13114758; platforms;android-34; build-tools;34.0.0), lib/api-82.jar (legacy, superseded), lib/api102 (modern, Maven Central), lib/r8.jar (R8 8.9.35 from Google Maven).
## Attempts
1. build1.*: build-tools 34.0.0 bundled d8 (R8 8.2.2) crashed with NPE on Hook$1.class when compiled by JDK 25 -> FAILED.
2. Used newer D8 from r8-8.9.35.jar -> build2.* OK; aapt2 link, zipalign, apksigner verify OK.
3. Static checks: aapt2 dump badging shows xposedmodule metadata; assets/xposed_init = com.local.noaadprompt.Hook; classes.dex present.
Session 2: identity verified, signing dir empty, throwaway keys flagged (see ../../investigation/FINDINGS.md F17).
