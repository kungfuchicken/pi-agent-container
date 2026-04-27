# pi-agent-container

My personal polyglot dev container for [pi-coding-agent](https://github.com/mariozechner/pi-coding-agent), with Rust, Python, TypeScript, and C++ toolchains.

Pi Agent Container abbreviates to PAC, and yes — we're leaning into it, waka-waka. Paku paku (ぱくぱく) is a Japanese onomatopoeia that means to eat quickly or in big bites. It can also describe the action of opening and closing one's mouth, often used to depict someone eating hungrily. That sure sounds like what coding agents are doing to me! The name Pac-Man is derived from this term, reflecting the videogame character's action of gobbling up dots in the game. This PAC gobbles tokens.

PAC manages version-pinned builds, weekly auto-updates, and rollback so the pac-dots are always fresh and the ghosts stay in the box. (The "C" works equally well as Container, Coding, or Controller — pick your flavor.) This is a living config. I'll be adding agent definitions, skills, extensions, and workflow details over time.

The container runs as a dedicated `pac` user (UID 1001), not root, to avoid creating root-owned files on host bind mounts.

## Prerequisites

- [Lima](https://lima-vm.io/) with nerdctl (container runtime)
- [Node.js](https://nodejs.org/) with npm (for fetching version metadata)
- macOS (launchd scheduling is macOS-specific)

## Toolchains

All versions are pinned as `ARG`s in the Dockerfile. Bump them the same way you bump pi itself.

### Rust

`rustup` with a pinned stable toolchain. Includes `clippy`, `rustfmt`, and `rust-analyzer`. Host `~/.cargo/registry/` is bind-mounted for crate cache persistence.

### Python

`uv` as the package/environment manager. Python installed via `uv python install` (pinned). Global tools via `uv tool install`: `ruff`, `mypy`, `pytest` (all pinned). Host `~/.cache/uv/` is bind-mounted for download cache persistence. Per-project `.venv/` lives in the code mount.

### TypeScript / Node.js

Node.js LTS installed from a direct tarball (not the `node` base image). Global tools via `npm install -g`: `eslint`, `prettier`, `typescript`, `vitest` (all pinned). Project-level `node_modules/` in the code mount takes precedence.

### C++

`build-essential` (gcc, g++, make), `clang`, `clang-tidy`, `clang-format`, `cmake`. Also provides `pkg-config` and `libssl-dev` (needed by many Rust crates too).

### Dev Utilities

`git`, `gh`, `curl`, `wget`, `jq`, `openssh-client`, `ripgrep` (rg), `fd-find` (symlinked to `fd`).

## Quick Start

```bash
# 1. Build the initial image — chomp your first pac-dot
make bump

# 2. Symlink the CLI tools to your PATH
ln -sf "$(pwd)/pi-agent-container" ~/.local/bin/pi-agent-container
ln -sf "$(pwd)/pi-build" ~/.local/bin/pi-build

# 3. Run pi against a project
pi-agent-container dev --workspace ~/code/my-project
```

## Usage

### Running pi

```bash
# Full development mode (default)
pi-agent-container
pi-agent-container dev --workspace ~/code/my-project

# Read-only safe mode
pi-agent-container safe --workspace ~/code/my-project

# Pass extra flags to pi
pi-agent-container dev -- --model sonnet:high
```

### Modes

| Mode   | Description                                                                              |
| ------ | ---------------------------------------------------------------------------------------- |
| `dev`  | Full read/write/edit/bash access (default)                                               |
| `safe` | Read-only with restricted tools (read/grep/find/ls), dropped capabilities, memory limits |

### Build Management

The `pi-build` script handles the pac-man lifecycle: eat the latest dot, keep a power pellet or two in reserve.

```bash
pi-agent-container bump               # Build latest version
pi-agent-container bump 0.69.0        # Build a specific version
pi-agent-container rollback            # Restore previous build
pi-agent-container rollback v0.69.0-20260420T1800  # Restore specific build
pi-agent-container list                # Show available builds
pi-agent-container status              # Compare active vs latest on npm
```

Or equivalently via make:

```bash
make bump
make rollback
make list
make status
```

### Scheduled Builds

A weekly build runs every Friday at 9 PM via macOS launchd — the automatic power pellet. If the build fails, the existing active image is untouched.

```bash
make install-schedule      # Generate plist from template and load
make uninstall-schedule    # Unload and remove
```

Logs: `/tmp/pi-build.log` and `/tmp/pi-build.err`

## Skills

PAC includes a set of general-purpose Claude Code skills for planning, implementation, code review, and workflow management.

| Skill                  | Purpose                                                |
| ---------------------- | ------------------------------------------------------ |
| `planning`             | Collaborative design planning through dialogue         |
| `impl-planning`        | Create implementation plans from approved design plans |
| `implement`            | Begin implementation from an approved plan             |
| `stage`                | List plans and advance through lifecycle stages        |
| `worktree-merge`       | Merge work from a git worktree back to main            |
| `github-issue`         | Generate properly formatted GitHub Issues              |
| `gemini-code-review`   | Request a code review from Gemini                      |
| `gemini-design-review` | Request a design plan review from Gemini               |
| `gemini-impl-review`   | Request an implementation plan review from Gemini      |
| `gemini-merge-review`  | Request a pre-merge review from Gemini                 |
| `ra`                   | Run rust-analyzer CLI commands for Rust code analysis  |

Skills live in `skills/` with shared support files in `skills/_shared/`.

## Extensions

Pi extensions vendored as source in `extensions/`. All extensions follow a single model: source files checked into the repo.

From [HazAT/pi-config](https://github.com/HazAT/pi-config):
- **answer** — `/answer` command + `Ctrl+.` shortcut; extracts questions from assistant responses into interactive Q&A
- **cost** — `/cost` command; displays API expenditure summaries by date, project, and model
- **execute-command** — Tool enabling agents to self-invoke slash commands programmatically
- **todos** — `/todos` command; file-based task management with interactive TUI

From [xRyul/pi-show-diffs](https://github.com/xRyul/pi-show-diffs):
- **show-diffs** — Diff approval viewer before edit and write tools change files

From [maria-rcks/pi-github](https://github.com/maria-rcks/pi-github):
- **github** — GitHub integration; issues, PRs, and thread management

From [badlogic/pi-doom](https://github.com/badlogic/pi-doom):
- **doom** — `/doom` command; play DOOM in your terminal

From [mitsuhiko/agent-stuff](https://github.com/mitsuhiko/agent-stuff):
- **btw** — Background subagent sessions with TUI management
- **context** — `/context` command; shows loaded extensions, skills, context files, and token usage
- **control** — Inter-session communication via Unix domain sockets
- **files** — `/files` and `/diff` commands; browse git tree with quick actions
- **go-to-bed** — Prompts for confirmation during quiet hours (midnight–6 AM)
- **notify** — Desktop notifications when the agent finishes and awaits input
- **session-breakdown** — `/session-breakdown` command; usage analytics across sessions
- **split-fork** — Fork a session into a new Ghostty split pane
- **uv** — Redirects Python tooling (pip, poetry) to uv equivalents
- **whimsical** — Whimsical loading messages ("Schlepping...", "Combobulating...")

## Mounts and Workspace Layout

The container mirrors your host workspace layout. The entire workspace root is mounted read-only, with targeted read-write overlays for paths that need writes. This keeps the mount count low (10 total) while honoring least privilege.

```
/home/pac/
├── .pi/                        <- bind: ~/.pi/ (rw — agent state + host relay)
├── .claude/                    <- bind: ~/.claude/ (rw)
├── .config/gh/                 <- bind: ~/.config/gh/ (rw — token refresh)
├── .ssh/                       <- bind: ~/.ssh/ (ro)
├── .cache/uv/                  <- bind: ~/.cache/uv/ (rw)
│
/workspace/                     <- bind: $WORKSPACE_ROOT (ro — entire workspace)
├── AGENTS.md, CLAUDE.md, ...   (visible from workspace root mount)
├── my-project/
│   └── mirror/                 <- rw overlay (when this is the active repo + cwd)
├── ~working/
│   ├── plans/                  <- rw overlay
│   ├── reports/                <- rw overlay
│   └── apps/
│       └── pi-agent-container/ (visible from workspace root — extensions, skills, agents)
├── dotfiles/                  (visible — GIT_CONFIG_GLOBAL points here)
└── ...
```

The active repo path is computed as a relative path within the workspace (`WORKSPACE_RELPATH`) and mounted as a read-write overlay. It's also the container's working directory.

`WORKSPACE_ROOT` is derived automatically from `WORKING_DIR` — it's the parent directory. For `~/code/myworkspace/~working/`, `WORKSPACE_ROOT` = `~/code/myworkspace/`. You can override it directly if the convention doesn't apply.

`WORKING_DIR` defaults to `../../` relative to this repo, assuming it lives at `~working/apps/pi-agent-container/`.

`GIT_CONFIG_GLOBAL` is resolved automatically by the `pi-agent-container` script: if `~/.gitconfig` is a symlink into the workspace, it's converted to the corresponding `/workspace/...` path. No separate mount needed.

## Host Relay (via Safisto)

The container can't directly interact with macOS — no `osascript`, no `open`, no window management. The **host relay** pattern bridges this gap using [safisto](https://github.com/your/safisto) (Secure Automated FileSystem Task Orchestrator) running on the host.

### How it works

1. The container writes a JSON request file to `~/.pi/host-relay/` (bind-mounted rw)
2. Safisto watches `~/.pi/host-relay/` on the host
3. Safisto matches the file and runs the corresponding macOS command
4. Safisto deletes the request file after processing

The container never gets shell access to the host. Communication is one-way through files with a well-defined schema. Safisto validates and acts on each request independently.

### Use cases

| Request type | Container writes | Safisto runs on host |
|---|---|---|
| **Ghostty split** | `split-*.json` with cwd and startup command | `osascript` to create a Ghostty split pane |
| **Open URL** | `open-url-*.json` with URL | `open` to launch in default browser |
| **Preview file** | `preview-*.json` with file path | `open -a Preview` for images/PDFs |

### Request format

Each request is a JSON file dropped into `~/.pi/host-relay/`. The filename prefix determines the action type. Example:

```json
// split-2026-04-26T19-43-00Z.json
{
  "action": "split",
  "cwd": "/workspace/code",
  "input": "pi --session /home/pac/.pi/agent/sessions/forked.jsonl"
}
```

```json
// open-url-2026-04-26T19-45-00Z.json
{
  "action": "open-url",
  "url": "http://localhost:5173"
}
```

```json
// preview-2026-04-26T19-50-00Z.json
{
  "action": "preview",
  "path": "/workspace/code/output/chart.png"
}
```

### Safisto config (host side)

```yaml
watch:
  - ~/.pi/host-relay

rules:
  - name: ghostty-split
    match:
      glob: "split-*.json"
    actions:
      - run:
          command: ~/.pi/ghostty-split.sh
          args: ["{{path}}"]
      - delete:

  - name: open-url
    match:
      glob: "open-url-*.json"
    actions:
      - run:
          command: ~/.pi/open-url.sh
          args: ["{{path}}"]
      - delete:

  - name: preview
    match:
      glob: "preview-*.json"
    actions:
      - run:
          command: ~/.pi/preview.sh
          args: ["{{path}}"]
      - delete:
```

Each handler script reads the JSON, extracts the fields, and calls the macOS API. This pattern is extensible — new host interactions are a new rule and a small script.

## How It Works

### Image Tagging

```
pi-coding-agent:active                    <-- compose always uses this
pi-coding-agent:prev                      <-- previous active (quick rollback)
pi-coding-agent:v0.70.2-20260424T2100     <-- immutable versioned builds
```

The `active` tag only moves after a successful build. If the build fails, the existing image is untouched. The last 5 versioned builds are retained; older ones are pruned automatically.

### Authentication and State

`~/.pi/`, `~/.claude/`, and `~/.config/gh/` are bind-mounted into the container, so auth tokens, session state, memory, and project settings all persist across container restarts. `~/.ssh/` is mounted read-only for git operations over SSH.

### Environment Variables

Set these in your shell or in a `.env` file alongside `docker-compose.yml`:

| Variable             | Purpose                                                              |
| -------------------- | -------------------------------------------------------------------- |
| `ANTHROPIC_API_KEY`  | Anthropic API access                                                 |
| `OPENAI_API_KEY`     | OpenAI API access                                                    |
| `GOOGLE_API_KEY`     | Google API access                                                    |
| `WORKING_DIR`        | Host path to `~working/` (plans and reports)                         |
| `WORKSPACE_ROOT`     | Parent of `~working/` (auto-derived, override if needed)             |
| `WORKSPACE_DIR`      | Host path to active repo                                             |
| `WORKSPACE_RELPATH`  | Active repo path relative to WORKSPACE_ROOT (auto-derived)           |
| `GIT_CONFIG_GLOBAL`  | Container path to gitconfig (auto-resolved from ~/.gitconfig symlink)|

### Lima Considerations

This setup uses `lima nerdctl` rather than Docker. A few things to note:

- Environment variables from the macOS host are not automatically forwarded into the Lima VM. The `pi-agent-container` script and Makefile write a `.env` file that compose reads.
- The `HOST_HOME` variable bridges the macOS `$HOME` path into compose, since `$HOME` inside Lima resolves to the Linux home directory.
- The `pi-build` script includes an `ensure_lima()` function that starts the Lima VM if it isn't running (useful for the scheduled Friday build).

## File Overview

| File                          | Purpose                                                                          |
| ----------------------------- | -------------------------------------------------------------------------------- |
| `pi-agent-container`          | CLI wrapper for running pi (symlink to `~/.local/bin/`)                          |
| `pi-build`                    | CLI for building, rolling back, and managing images (symlink to `~/.local/bin/`) |
| `docker-compose.yml`          | Compose config with `dev` and `safe` profiles                                    |
| `Dockerfile`                  | Multi-stage build with all pinned toolchains + pi-coding-agent                   |
| `Makefile`                    | Developer API wrapping all common tasks                                          |
| `com.pi-build.plist.template` | Launchd template for weekly scheduled builds                                     |
| `.pi-version`                 | Tracks the active pi-coding-agent version (generated, gitignored)                |
| `.env`                        | Compose environment bridge for Lima (generated, gitignored)                      |
| `skills/`                     | Claude Code skills for planning, review, and workflow                            |
| `skills/_shared/`             | Shared support files referenced by multiple skills                               |
| `extensions/`                 | Pi extensions vendored as source                                                 |

## License

MIT. See [LICENSE](LICENSE).
