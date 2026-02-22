---
name: unity
description: Launch Unity Editor or run PlayMode/EditMode tests via CLI
---

# Unity CLI Skill

Invoke the Unity Editor binary for launching the editor or running tests.
The Unity binary path is defined in `~/.claude/CLAUDE.md`.

## Usage

`/unity` accepts an argument string. Parse it to determine the action:

| Argument | Action |
|----------|--------|
| (none), `open`, `launch` | Launch the editor with the current project |
| `test`, `test play`, `play`, `playmode` | Run PlayMode tests |
| `test edit`, `edit`, `editmode` | Run EditMode tests |
| `kill` | Force kill all Unity processes |

## Variables

```bash
UNITY="/home/midori/Unity/Hub/Editor/6000.3.6f1/Editor/Unity"
PROJECT_PATH="$(pwd)"
```

## Actions

### Launch Editor

Open Unity Editor with the current project in the background:

```bash
nohup env GDK_SCALE=2 GDK_DPI_SCALE=0.5 "$UNITY" -projectPath "$PROJECT_PATH" > /dev/null 2>&1 &
```

Report the PID and confirm launch.

### Run Tests

Run tests in batchmode. Use a temporary results file to capture output:

```bash
RESULTS_FILE=$(mktemp /tmp/unity-test-results-XXXXXX.xml)

"$UNITY" \
  -runTests \
  -batchmode \
  -projectPath "$PROJECT_PATH" \
  -testPlatform <PlayMode|EditMode> \
  -testResults "$RESULTS_FILE" \
  -logFile -

# After the command completes, read and summarize the XML results file
# Then clean up: rm "$RESULTS_FILE"
```

- `-testPlatform PlayMode` for play mode tests
- `-testPlatform EditMode` for edit mode tests
- `-logFile -` sends the Unity log to stdout so progress is visible
- The command will block until tests complete (may take minutes)
- Parse the XML results file and report: total, passed, failed, skipped
- Show details for any failed tests

### Kill Unity

Force kill all running Unity processes:

```bash
killall -9 Unity 2>/dev/null
```

Report how many processes were killed (check before/after with `pgrep -c Unity`).

### Handling Active Unity Sessions

When running tests in batchmode, Unity will fail if another Unity instance already has the project open. Detect this by checking the log output for indicators such as:

- `Multiple Unity instances cannot open the same project`
- `Already running - Unity is already running`
- `Could not launch Unity`
- Non-zero exit code combined with no test results XML generated

When this is detected:

1. **Ask the user** for confirmation: "Unity appears to be already running. Kill all Unity processes and retry?"
2. If the user confirms, run:
   ```bash
   killall -9 Unity 2>/dev/null; sleep 2
   ```
3. Then **retry the test command** from the beginning.
4. If the user declines, abort and report that tests cannot run while Unity is open.

## Notes

- **PlayMode vs EditMode are test designations**, not support flags. Tests are grouped into one or the other based on their assembly definition's `testPlatform` setting. PlayMode tests can run in compiled builds (standalone players); EditMode tests can only run inside the Unity Editor.
- **Default to PlayMode tests.** When the user says just `test` without specifying a designation, run PlayMode.
- Use a timeout of 600000ms (10 minutes) for test runs.
