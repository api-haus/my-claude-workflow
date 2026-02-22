# Session Status Skill

Shows active Claude sessions across all projects with key metadata.

## Usage

```bash
/claude-status          # Show all active sessions
/claude-status --here   # Show only current project sessions
/claude-status --clean  # Identify stale/abandoned sessions
```

## Output Format

```
Active Sessions (7 total)
═══════════════════════════════════════════════════════════

sim2d                    /home/midori/_dev/sim2d
├─ docs-modularity       2h ago    3 uncommitted  [RESUME]
├─ crate-merge          30m ago   clean          [RESUME]
└─ main                 2d ago    5 uncommitted  [STALE?]

p7                       /home/midori/_dev/p7
├─ player-api-tests     4h ago    clean          [RESUME]
└─ game-api             1d ago    2 uncommitted  [STALE?]

Unreal/UE_5.7            /mnt/archive4/UNREAL/UE_5.7
└─ fab-plugin-fix       6h ago    clean          [RESUME]

⚠️  2 stale sessions (>24h, uncommitted changes)
💡 Run `/claude-status --clean` to identify for cleanup
```

## Implementation Notes

- Scans ~/.claude/projects/ for session metadata
- Checks git status in each project path
- Shows last activity timestamp
- Flags sessions with uncommitted work
- Suggests resume/cleanup actions

## Integration

This skill is read-only. It never modifies sessions or code.
Use `/resume` manually after reviewing status.
