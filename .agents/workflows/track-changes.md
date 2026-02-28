---
description: Track all code, API, and UI changes in the project changelog
---

# Change Tracking Workflow

This workflow ensures every code change, API update, or UI modification is recorded in `docs/CHANGELOG.md`.

## When to Use

Run this workflow **after every task you complete** — any code edit, new feature, API change, bug fix, or UI update.

## Steps

### 1. Read the existing changelog

Before writing, always read the current `docs/CHANGELOG.md` file to understand the latest entry format and avoid duplicates.

### 2. Determine the change category

Classify your change into one of these categories:

| Tag | Use for |
|-----|---------|
| `🎨 UI` | Visual/layout/widget changes, theme updates, new screens |
| `🔌 API` | New endpoints, API contract changes, request/response updates |
| `🛠️ Code` | Refactors, new services, BLoC changes, data models |
| `🐛 Fix` | Bug fixes, error handling, crash resolution |
| `📦 Deps` | Dependency additions, upgrades, removals |
| `🧪 Test` | New or updated tests |
| `📝 Docs` | Documentation updates |

### 3. Write the changelog entry

Add a new entry at the **top** of the `## Unreleased` section in `docs/CHANGELOG.md` using this format:

```markdown
### YYYY-MM-DD — Brief Title
**Tag** `🎨 UI` | **Scope**: `feature/component_name`

- What changed (be specific: file names, widget names, function names)
- Why it changed (context: user request, bug, optimization)
- What was affected (other files touched, side effects)

**Files modified:**
- `path/to/file.dart` — description of change
- `path/to/new_file.dart` — [NEW] description

**Breaking changes:** None (or describe what breaks)
```

### 4. Verify the entry

Re-read `docs/CHANGELOG.md` after editing to confirm the entry is well-formed and non-duplicative.

## Rules

- **Always read before writing** — never blindly append
- **One entry per logical change** — group related file edits into a single entry
- **Use present tense** — "Add", "Fix", "Update", not "Added"
- **Link file paths** — use backtick-wrapped relative paths
- **Never delete entries** — the log is append-only (newest at top)
- **Date format** — always use `YYYY-MM-DD` with the current local time
- **NO EMOJIS** — never use emoji characters anywhere in the codebase (Dart, markdown, comments, debug prints). Use plain text labels instead.
