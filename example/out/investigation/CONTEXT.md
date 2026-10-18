# CONTEXT
Objective: static investigation of "Enable Automated Version Update" dialog in Microsoft Launcher APK; find smallest suppression point.
Constraints: no APK modification/install, no device changes, no runtime claims.
APK: /app/original/com.microsoft.launcher_6.260402.0.1178950-1178950_minAPI24(arm64-v8a,armeabi-v7a)(nodpi)_apkmirror.com.apk
SHA-256: 32bbedd31d8488841e81cfa426e3ca594e3c4d17562e225ed1ff92539d2e4d20 (E000; no prior checkpoint existed -> nothing to compare)
Tools used historically: rea 6.5.0, apktool v3.0.3-SNAPSHOT, JDK 25. Tool state is not included.
Snapshot: curated notes and modification source only. Decoded APK, raw evidence, command histories, logging wrappers and private session state are omitted.
Progress: resources decoded (E002); apktool full decode E003 running.
Decisions: use apktool decode into workspace (read-only on APK) for public.xml IDs & smali xref, since rea resource output has no IDs.
Progress: smali analysis of Ea.* done (E004-E015); decoded/ present.
Progress (historical): all key code located; see FINDINGS.md F1-F14. Evidence IDs refer to omitted local evidence (JADX via rea 6.5.0, jadx 0.7.1).
Handoff: report is complete; remaining work in NEXT.md.
Session 2: reverified identity/tools, F15-F17 added. Handoff in NEXT.md.
