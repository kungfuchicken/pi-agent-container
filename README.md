# pi-agent-container

My personal containerized setup for [pi-coding-agent](https://github.com/mariozechner/pi-coding-agent). 

Pi Agent Container abbreviates to PAC, and yes — we're leaning into it, waka-waka. Paku paku (ぱくぱく) is a Japanese onomatopoeia that means to eat quickly or in big bites. It can also describe the action of opening and closing one's mouth, often used to depict someone eating hungrily. That sure sounds like what coding agents are doing to me! The name Pac-Man is derived from this term, reflecting the videogame character's action of gobbling up dots in the game. This PAC gobbles tokens.

PAC manages version-pinned builds, weekly auto-updates, and rollback so the pac-dots are always fresh and the ghosts stay in the box. (The "C" works equally well as Container, Coding, or Controller — pick your flavor.) This is a living config. I'll be adding agent definitions, skills, extensions, and workflow details over time.

## Prerequisites

- [Lima](https://lima-vm.io/) with nerdctl (container runtime)
- [Node.js](https://nodejs.org/) with npm (for fetching version metadata)
- macOS (launchd scheduling is macOS-specific)

## Quick Start

```bash
# 1. Build the initial image — chomp your first pac-dot
make bump

# 2. Symlink the CLI tools to your PATH
ln -sf "$(pwd)/pi-container" ~/.local/bin/pi-container
ln -sf "$(pwd)/pi-build" ~/.local/bin/pi-build

# 3. Run pi against a project
pi-container dev --workspace ~/code/my-project
```

## Usage

### Running pi

```bash
# Full development mode (default)
pi-container
pi-container dev --workspace ~/code/my-project

# Read-only safe mode
pi-container safe --workspace ~/code/my-project

# Pass extra flags to pi
pi-container dev -- --model sonnet:high
```

### Modes

| Mode   | Description                                                                              |
| ------ | ---------------------------------------------------------------------------------------- |
| `dev`  | Full read/write/edit/bash access (default)                                               |
| `safe` | Read-only with restricted tools (read/grep/find/ls), dropped capabilities, memory limits |

### Build Management

The `pi-build` script handles the pac-man lifecycle: eat the latest dot, keep a power pellet or two in reserve.

```bash
pi-container bump               # Build latest version
pi-container bump 0.69.0        # Build a specific version
pi-container rollback            # Restore previous build
pi-container rollback v0.69.0-20260420T1800  # Restore specific build
pi-container list                # Show available builds
pi-container status              # Compare active vs latest on npm
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

## How It Works

### Image Tagging

```
pi-coding-agent:active                    <-- compose always uses this
pi-coding-agent:prev                      <-- previous active (quick rollback)
pi-coding-agent:v0.70.2-20260424T2100     <-- immutable versioned builds
```

The `active` tag only moves after a successful build. If the build fails, the existing image is untouched. The last 5 versioned builds are retained; older ones are pruned automatically.

### Authentication

Host auth tokens (`~/.pi/agent/auth.json`) are bind-mounted read-only into the container, so you don't need to re-authenticate each time you start a session.

### Environment Variables

Set these in your shell or in a `.env` file alongside `docker-compose.yml`:

| Variable            | Purpose              |
| ------------------- | -------------------- |
| `ANTHROPIC_API_KEY` | Anthropic API access |
| `OPENAI_API_KEY`    | OpenAI API access    |
| `GOOGLE_API_KEY`    | Google API access    |

### Lima Considerations

This setup uses `lima nerdctl` rather than Docker. A few things to note:

- Environment variables from the macOS host are not automatically forwarded into the Lima VM. The `pi-container` script and Makefile write a `.env` file that compose reads.
- The `HOST_HOME` variable bridges the macOS `$HOME` path into compose, since `$HOME` inside Lima resolves to the Linux home directory.
- The `pi-build` script includes an `ensure_lima()` function that starts the Lima VM if it isn't running (useful for the scheduled Friday build).

## File Overview

| File                          | Purpose                                                                          |
| ----------------------------- | -------------------------------------------------------------------------------- |
| `pi-container`                | CLI wrapper for running pi (symlink to `~/.local/bin/`)                          |
| `pi-build`                    | CLI for building, rolling back, and managing images (symlink to `~/.local/bin/`) |
| `docker-compose.yml`          | Compose config with `dev` and `safe` profiles                                    |
| `Dockerfile`                  | Builds the pi-coding-agent image with a pinned version                           |
| `Makefile`                    | Developer API wrapping all common tasks                                          |
| `com.pi-build.plist.template` | Launchd template for weekly scheduled builds                                     |
| `.pi-version`                 | Tracks the active pi-coding-agent version (generated, gitignored)                |
| `.env`                        | Compose environment bridge for Lima (generated, gitignored)                      |

## License

MIT. See [LICENSE](LICENSE).
