# Repository Resolution Rules

Shared reference for skills that accept `--repo <identifier>` in polyrepo environments.

## Resolution Order

When `--repo <identifier>` is provided, resolve in this order:

### 1. Exact Path

If identifier is an existing directory path (absolute or relative), use it directly.

```
--repo acme/myapp         → acme/myapp/
--repo /abs/path/to/repo         → /abs/path/to/repo
--repo ./relative/path           → ./relative/path
```

### 2. Project Name Match

If not a path, search workspace directories for a matching project name:

**Search locations** (in order):
- `products/`
- `personal/`
- `research/` (and subdirectories like `research/lab/`)
- `misc/`

**Match against**: Directory names

```
--repo myapp        → acme/myapp/
--repo tracker   → products/tracker/
--repo scraper       → research/lab/scraper/
--repo blog          → personal/blog/
```

**If multiple matches**: List them and ask user to clarify.

### 3. Worktree Path

If identifier contains `.worktrees/`, resolve as a worktree directory:

```
--repo myapp/.worktrees/impl-audio-effects  → acme/myapp/.worktrees/impl-audio-effects/
```

## Verification

After resolution, verify it's a git repository:

```bash
git -C <resolved_path> rev-parse --git-dir
```

If verification fails, report error with the attempted path.

## Usage in Git Commands

Once resolved, all git commands should use `-C <path>`:

```bash
git -C <resolved_path> status
git -C <resolved_path> diff --staged
git -C <resolved_path> log main..HEAD
```

## If `--repo` is Omitted

- Use current working directory
- Verify it's within a git repository
- If not in a repo, ask user to specify with `--repo`

## Implementation Notes for Claude

1. **Resolve early**: Resolve `--repo` before any git operations
2. **Report resolved path**: Always show the user which path was resolved
3. **Use `find` or `ls` for discovery**: When searching by name, use filesystem tools
4. **Handle ambiguity**: If multiple projects match, list options and ask

## Example Resolution Code

```bash
# Check if exact path exists
if [[ -d "$identifier" ]]; then
    resolved="$identifier"
# Otherwise search by name
else
    # Search in known locations
    found=$(find products personal research misc \
        -maxdepth 2 -type d -name "$identifier" 2>/dev/null | head -5)

    if [[ $(echo "$found" | wc -l) -eq 1 ]]; then
        resolved="$found"
    elif [[ -n "$found" ]]; then
        echo "Multiple matches found:"
        echo "$found"
        # Ask user to clarify
    else
        echo "No project found matching: $identifier"
    fi
fi

# Verify it's a git repo
git -C "$resolved" rev-parse --git-dir >/dev/null 2>&1
```
