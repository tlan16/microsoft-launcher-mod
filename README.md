This is a demo of using REA and GitHub Copilot to modify a publicly distributed Android application.

---

Prerequisites:

1. docker
2. docker compose
3. github copilot subscription
4. GitHub **fine-grained personal access token** (`github_pat_...`) with
   **Account permissions > Copilot Requests: Read-only**. Create it under your
   **personal account** as resource owner, not an organization. Select
   **Public repositories** for repository access; no additional repository
   permissions are needed for this local APK investigation and public dependency
   downloads. Classic PATs (`ghp_...`) are not supported by Copilot CLI.

Create the token at [GitHub token settings](https://github.com/settings/personal-access-tokens/new).
Under **Permissions**, open the **Account** tab, select **Add permissions**, and
add **Copilot Requests**. See [Copilot CLI authentication](https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/authenticate-copilot-cli#authenticating-with-environment-variables).

First update the cp [.env.example](.env.example) to `.env` and fill in your GitHub token.

Now build and run the container iteratively:

```shell
docker compose run --rm -it --build app
```

Now you should be inside the container. You can run the following commands to investigate the APK.

```bash
APK='/app/original/com.microsoft.launcher_6.260402.0.1178950-1178950_minAPI24(arm64-v8a,armeabi-v7a)(nodpi)_apkmirror.com.apk'

mkdir -p /app/out/investigation

mkdir -p "$COPILOT_HOME"

rea doctor --provider jadx
rea inspect-android-package "$APK" --format json \
  | jq > /app/out/investigation/package.json
```

Compose sets `COPILOT_HOME=/app/out/copilot` automatically. `/app/out` is
bind-mounted to `./out` on the host, so Copilot configuration, session history,
logs, and any CLI-managed state/cache under its home survive disposable
containers and image rebuilds. `out/copilot/` is Git-ignored and excluded from
Docker build context. Existing state at this path is reused. Keep this
directory private: history, logs, and authentication state can contain sensitive
information. Do not commit or share it without reviewing and redacting its contents.

LLM prompt-token/KV caching is managed by GitHub/model providers, not a local
Docker folder. Persisting CLI state and resuming the same session preserves local
continuity, but does not persist server-side token caches or guarantee cache hits,
cache lifetime, or billing savings.

Use both persistent CLI history and investigation files: history supports session
resume, while evidence and checkpoints support recovery after context compaction
or starting a new session. This preserves recorded conversation/tool events and
saved artifacts, not hidden model reasoning or every transient file. Relevant
files left elsewhere in the container disappear when it exits.

### Persistent APK signing identity

Compose mounts project folder `./signing` at `/app/signing` and sets
`APK_SIGNING_DIR=/app/signing`. Keystores and local signing configuration stored
there survive container removal and image rebuilds. Contents are Git-ignored
except for the folder placeholder, and excluded from Docker build context.
Private keys are **not baked into image layers**. Back up this folder securely;
losing a signing key prevents normal upgrades of APKs signed with it.

Android normally requires matching package ID and signing certificate, plus a
non-decreasing `versionCode`, to update an installed app. Reuse each artifact
track's signing identity across builds; do not generate a fresh key per session.
A custom-signed Launcher APK cannot update the Microsoft-signed original.
Initial replacement normally requires uninstalling the original, risking app
data loss. An LSPosed module has its own package/signing identity and does not
require re-signing Launcher. See [Android app signing](https://developer.android.com/studio/publish/app-signing).

Now start a named investigation session:

```bash
copilot --allow-all-paths --allow-all --context long_context \
  --name microsoft-launcher-re -i '
Investigate and develop modifications for this local APK using REA CLI:
 /app/original/com.microsoft.launcher_6.260402.0.1178950-1178950_minAPI24(arm64-v8a,armeabi-v7a)(nodpi)_apkmirror.com.apk

Goal: stop only the recurring dialog titled "Enable Automated Version Update".
Body: "To enable the automated app version update, it requires identity
authentication with your AAD login. Please disregard this message if you
have already done so."
Buttons: "Not now" and "Enable".

First investigate the trigger, then attempt both modification approaches below.
Keep the original APK unchanged. Work on copies and do not install APKs, deploy
modules, connect to devices, or change device settings without explicit approval.
Use rea command --help to verify syntax before invoking unfamiliar commands.
Find matching string resources and resource IDs, then their code references.
Inspect dialog construction, callers, recurrence timing, stored preferences,
and both button handlers. Names may be obfuscated; do not rely only on
class-name searches. Distinguish observed code from hypotheses.

Tools provided by the Dockerfile (verify installed versions before use):
- Apktool 3.0.3 built from source; apktool and apktool.jar are installed under
  /usr/local/bin. Use it to decode resources/smali and rebuild APK copies.
  REA also exposes inspect-apktool-client and decode-android-resources.
- Android SDK at /opt/android-sdk; ANDROID_HOME and ANDROID_SDK_ROOT point there.
  Default packages: Android platform 35 (android.jar), build-tools 35.0.0,
  platform-tools, and command-line tools archive 11076708. Build arguments can
  override these versions. sdkmanager, adb, aapt2, apksigner, and zipalign are
  on PATH through cmdline-tools/latest/bin, platform-tools, and build-tools-bin.
  SDK licenses are accepted during image build. No emulator/system image or
  connected device is implied. Additional SDK platforms may be needed for a
  module build; inspect requirements before installing them.
- JADX headless MCP fat JAR at /opt/jadx/jadx-headless-mcp.jar, selected by
  REA_JADX_MCP_JAR; Ghidra at /opt/ghidra, selected by GHIDRA_INSTALL_DIR.
- Java JDK via JAVA_HOME=/opt/java; Node.js/npm, Python/pip/venv, git/gh,
  curl/wget, jq/yq, unzip/zip, and bash. Do not assume a system Gradle or
  Morphe/LSPosed development tooling is installed; inspect first and prefer
  project Gradle wrappers and isolated dependency environments.

Attempt both approaches after identifying an evidence-backed suppression point:
1. Morphe APK patch: research current official documentation and examples online,
   verify compatibility/toolchain requirements, and build a narrowly scoped
   patch that suppresses only this dialog. Store source, build instructions,
   commands, dependency versions, successful and failed attempts, logs, and
   resulting artifacts under /app/out/mod/morphe.
2. LSPosed module: research current official APIs/examples and build a module
   scoped to com.microsoft.launcher that hooks the narrowest justified method.
   Use the latest stable modern Xposed API supported by LSPosed (for example,
   API 101 or 102); verify the current version and compatibility from official
   documentation rather than assuming either example is latest. Do not default
   to the legacy API.
   Store source, build instructions, commands, dependency versions, successful
   and failed attempts, logs, and resulting artifacts under /app/out/mod/lsposed.
   Do not assume a rooted device or compatible LSPosed installation is available.

Preserve manual updates, authentication, and unrelated dialogs. Do not implement
an authentication bypass or globally suppress all dialogs. If either approach
is blocked, retain the failed attempts, evidence, blocker, and next steps; do not
claim success without building and checking its artifacts. Distinguish build/
static validation from device verification of the recurring popup.

You may use apt as root to install required OS packages inside this disposable
container. Record each package installation, SDK addition, or environment change
in /app/out/docker-file-change-suggestions.md with reason, exact commands,
versions, validation, and proposed Dockerfile changes so it can be made permanent.
Do not edit the project Dockerfile automatically. Check existing tools first.

Persistent workspaces: investigation evidence/checkpoints under
/app/out/investigation, modification work under /app/out/mod/morphe and
/app/out/mod/lsposed, and environment suggestions at the path above. Store all
work products in these mounted locations, never only in /tmp or another ephemeral
container directory. Use temporary files only for reproducible scratch work.
Do not store credentials or authentication headers. Treat generated signing keys
as sensitive; keep them private and never commit them. Store reusable keystores
and private signing configuration only under APK_SIGNING_DIR=/app/signing,
bind-mounted from the host project signing folder, not in modification artifacts
or image layers. Reuse an existing key for each artifact track; never overwrite
or regenerate it silently. If absent, create a persistent key with restrictive
permissions and keep passwords out of command logs and shell history.
Record only public certificate fingerprints, aliases, package IDs, and version
metadata in investigation checkpoints. Preserve package ID and signing identity
across upgrades and avoid decreasing versionCode. Check signing certificates
with apksigner; verify signed output and record its certificate fingerprint.
Explain that a custom-signed APK cannot upgrade the Microsoft-signed original;
do not uninstall it or risk device data without explicit approval.

Before investigating, read existing CONTEXT.md, FINDINGS.md, NEXT.md, and
commands.jsonl if present. Inventory existing evidence and reuse matching results.
Verify the APK SHA-256 and tool versions against the checkpoint. If they differ,
record the mismatch and keep new evidence separate; do not silently reuse results
from a different artifact. Verify existing tooling before installing anything.

Maintain these files incrementally, not just when the session ends:
- CONTEXT.md: objective, constraints, APK path and SHA-256, tool versions,
  workspace layout, current progress, and decisions with reasons.
- FINDINGS.md: verified facts and separate hypotheses/rejected hypotheses,
  with evidence file paths, Evidence IDs, exact code locations, and limitations.
- NEXT.md: prioritized next probes, unresolved questions, blockers, and exact
  commands needed to continue. Update before starting each long-running probe.
- commands.jsonl: append one record per investigative command with UTC time,
  command, working directory, purpose, stdout/stderr file paths, exit status,
  and outcome. Record a started entry before execution and a completed entry
  afterward so interrupted probes are detectable. Never log secrets.
- evidence/: uniquely named raw command outputs, complete REA JSON records,
  decoded resources, and source excerpts. Keep stdout and stderr separate so
  JSON remains parseable. Do not overwrite earlier evidence.

After each meaningful result, failed attempt, or decision, update the checkpoint
and findings. Before stopping or compacting, leave a self-contained handoff in
CONTEXT.md and NEXT.md. If interrupted, recover from the last checkpoint and
record incomplete commands rather than assuming they succeeded. Do not repeat
expensive work unless existing evidence is incomplete or a stated input changed.

Report exact classes, method signatures, resource IDs, conditions, and
smallest candidate suppression point. Explain whether suppression leaves
manual updates and authentication intact. State missing tools or unresolved
evidence explicitly. Report each modification approach separately with artifact
paths, validation performed, deployment prerequisites, and remaining device tests.
Do not claim runtime verification.
'
```

`--allow-all` grants broad permissions; omit it to approve tool calls individually.
Prompt restrictions are instructions, not a security boundary.

### Continue in a new container

On the host, start another container with the same Compose project directory:

```bash
docker compose run --rm -it --build app
```

Inside it, resume the named session; Compose already sets the state directory:

```bash
copilot --allow-all-paths --allow-all --context long_context \
  --resume microsoft-launcher-re -i '
Continue the launcher update-dialog investigation and both modification approaches.
First read /app/out/investigation/CONTEXT.md, FINDINGS.md, NEXT.md, and
commands.jsonl. Verify APK identity and tool versions, reconcile interrupted
commands, and continue the highest-priority unresolved probe. Keep recording
commands, evidence, findings, and checkpoints as instructed earlier.
Keep Morphe work under /app/out/mod/morphe and LSPosed work under
/app/out/mod/lsposed, including failed attempts. Record required container
package/SDK/environment changes in /app/out/docker-file-change-suggestions.md.
Verify existing Apktool and Android SDK tools before installing dependencies.
Reuse signing identities from /app/signing (APK_SIGNING_DIR); never regenerate
existing keys or expose private signing material in logs or build artifacts.
Keep the original APK unchanged; build modifications on copies. Do not install
APKs, deploy modules, connect to devices, or change device settings without
explicit approval. Preserve authentication, manual updates, and unrelated dialogs.
'
```

Use `copilot --resume` to select a session if the name is ambiguous. Do not run
multiple writers against the same investigation files simultaneously.

If session history is unavailable, remove `--resume microsoft-launcher-re` and
start a new session with the continuation prompt. Checkpoint files provide the
handoff; they cannot recover outputs that were never saved.
