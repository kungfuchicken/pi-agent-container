#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <split-request.json>" >&2
  exit 2
fi

request_path="$1"
if [[ ! -f "$request_path" ]]; then
  echo "error: request not found: $request_path" >&2
  exit 1
fi

read_field() {
  local field="$1"
  /usr/bin/python3 - "$request_path" "$field" <<'PY'
import json
import sys

request_path = sys.argv[1]
field = sys.argv[2]

with open(request_path, "r", encoding="utf-8") as f:
    payload = json.load(f)

value = payload.get(field, "")
if isinstance(value, str):
    sys.stdout.write(value)
else:
    sys.stdout.write("")
PY
}

cwd="$(read_field cwd)"
startup_input="$(read_field input)"

if [[ -z "$cwd" ]]; then
  echo "error: split request missing 'cwd': $request_path" >&2
  exit 1
fi

if [[ -z "$startup_input" ]]; then
  echo "error: split request missing 'input': $request_path" >&2
  exit 1
fi

osascript -e 'on run argv
	set targetCwd to item 1 of argv
	set startupInput to item 2 of argv
	tell application "Ghostty"
		set cfg to new surface configuration
		set initial working directory of cfg to targetCwd
		set initial input of cfg to startupInput
		if (count of windows) > 0 then
			try
				set frontWindow to front window
				set targetTerminal to focused terminal of selected tab of frontWindow
				split targetTerminal direction right with configuration cfg
			on error
				new window with configuration cfg
			end try
		else
			new window with configuration cfg
		end if
		activate
	end tell
end run' -- "$cwd" "$startup_input"
