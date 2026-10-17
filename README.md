This is a demo of using REA and GitHub Copilot to modify a publicly distributed Android application.

---

Prerequisites:

1. docker
2. docker compose
3. github copilot subscription
4. github fine-grained personal access

First update the cp [.env.example](.env.example) to `.env` and fill in your GitHub token.

Now build and run the container:

```shell
docker compose run --rm -it --build app
```

Now you should be inside the container. You can run the following commands to investigate the APK.

```bash
APK='/app/original/com.microsoft.launcher_6.260402.0.1178950-1178950_minAPI24(arm64-v8a,armeabi-v7a)(nodpi)_apkmirror.com.apk'

mkdir -p /app/out/investigation

rea doctor --provider jadx
rea inspect-android-package "$APK" --format json \
  | jq > /app/out/investigation/package.json
```

Now you can use GitHub Copilot to help you investigate the APK. Run the following command:

```bash
copilot --allow-all-paths --allow-all --context long_context -i '
Investigate this local APK using REA CLI:
 /app/original/com.microsoft.launcher_6.260402.0.1178950-1178950_minAPI24(arm64-v8a,armeabi-v7a)(nodpi)_apkmirror.com.apk

Goal: stop only the recurring dialog titled "Enable Automated Version Update".
Body: "To enable the automated app version update, it requires identity
authentication with your AAD login. Please disregard this message if you
have already done so."
Buttons: "Not now" and "Enable".

Investigation only. Do not modify/install the APK or change device settings.
Use rea command --help to verify syntax before invoking unfamiliar commands.
Find matching string resources and resource IDs, then their code references.
Inspect dialog construction, callers, recurrence timing, stored preferences,
and both button handlers. Names may be obfuscated; do not rely only on
class-name searches. Distinguish observed code from hypotheses.

Save evidence and findings under /app/out/investigation.
Report exact classes, method signatures, resource IDs, conditions, and
smallest candidate suppression point. Explain whether suppression leaves
manual updates and authentication intact. State missing tools or unresolved
evidence explicitly. Do not claim runtime verification.
'
```
