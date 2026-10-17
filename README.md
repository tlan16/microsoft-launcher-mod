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

Now start a named investigation session:

```bash
copilot --allow-all-paths --allow-all --context long_context \
  --name microsoft-launcher-re -i '
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

Persistent workspace: /app/out/investigation. Store all evidence, scripts,
decoded resources, source excerpts, and other work products there, never only
in /tmp or another ephemeral container directory. Use temporary files only for
reproducible scratch work. Do not store credentials or authentication headers.

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
evidence explicitly. Do not claim runtime verification.
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
Continue the launcher update-dialog investigation.
First read /app/out/investigation/CONTEXT.md, FINDINGS.md, NEXT.md, and
commands.jsonl. Verify APK identity and tool versions, reconcile interrupted
commands, and continue the highest-priority unresolved probe. Keep recording
commands, evidence, findings, and checkpoints as instructed earlier.
Investigation only: do not modify/install the APK or change device settings.
'
```

Use `copilot --resume` to select a session if the name is ambiguous. Do not run
multiple writers against the same investigation files simultaneously.

If session history is unavailable, remove `--resume microsoft-launcher-re` and
start a new session with the continuation prompt. Checkpoint files provide the
handoff; they cannot recover outputs that were never saved.
