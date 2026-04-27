import type { ExtensionAPI, ExtensionCommandContext } from "@mariozechner/pi-coding-agent";
import { existsSync, promises as fs } from "node:fs";
import * as path from "node:path";
import { randomUUID } from "node:crypto";

const GHOSTTY_SPLIT_SCRIPT = `on run argv
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
end run`;

function shellQuote(value: string): string {
	if (value.length === 0) return "''";
	return `'${value.replace(/'/g, `'"'"'`)}'`;
}

function getPiInvocationParts(): string[] {
	const currentScript = process.argv[1];
	if (currentScript && existsSync(currentScript)) {
		return [process.execPath, currentScript];
	}

	const execName = path.basename(process.execPath).toLowerCase();
	const isGenericRuntime = /^(node|bun)(\.exe)?$/.test(execName);
	if (!isGenericRuntime) {
		return [process.execPath];
	}

	return ["pi"];
}

function buildPiStartupInput(sessionFile: string | undefined, prompt: string): string {
	const commandParts = [...getPiInvocationParts()];

	if (sessionFile) {
		commandParts.push("--session", sessionFile);
	}

	if (prompt.length > 0) {
		commandParts.push("--", prompt);
	}

	return `${commandParts.map(shellQuote).join(" ")}\n`;
}

async function createForkedSession(ctx: ExtensionCommandContext): Promise<string | undefined> {
	const sessionFile = ctx.sessionManager.getSessionFile();
	if (!sessionFile) {
		return undefined;
	}

	const sessionDir = path.dirname(sessionFile);
	const branchEntries = ctx.sessionManager.getBranch();
	const currentHeader = ctx.sessionManager.getHeader();

	const timestamp = new Date().toISOString();
	const fileTimestamp = timestamp.replace(/[:.]/g, "-");
	const newSessionId = randomUUID();
	const newSessionFile = path.join(sessionDir, `${fileTimestamp}_${newSessionId}.jsonl`);

	const newHeader = {
		type: "session",
		version: currentHeader?.version ?? 3,
		id: newSessionId,
		timestamp,
		cwd: currentHeader?.cwd ?? ctx.cwd,
		parentSession: sessionFile,
	};

	const lines = [JSON.stringify(newHeader), ...branchEntries.map((entry) => JSON.stringify(entry))].join("\n") + "\n";

	await fs.mkdir(sessionDir, { recursive: true });
	await fs.writeFile(newSessionFile, lines, "utf8");

	return newSessionFile;
}

function getHostRelayDir(): string {
	const fromEnv = process.env.PAC_HOST_RELAY_DIR?.trim();
	if (fromEnv && fromEnv.length > 0) {
		return fromEnv;
	}
	return path.join(process.env.HOME ?? "/home/pac", ".pi", "host-relay");
}

function enqueueSplitRequest(cwd: string, input: string, forkedSessionFile?: string): string {
	const relayDir = getHostRelayDir();
	const timestamp = new Date().toISOString();
	const fileTimestamp = timestamp.replace(/[:.]/g, "-");
	const requestPath = path.join(relayDir, `split-${fileTimestamp}-${randomUUID()}.json`);

	const payload = {
		action: "split",
		cwd,
		input,
		timestamp,
		forkedSessionFile,
	};

	void fs
		.mkdir(relayDir, { recursive: true })
		.then(() => fs.writeFile(requestPath, `${JSON.stringify(payload, null, 2)}\n`, "utf8"))
		.catch(() => undefined);

	return requestPath;
}

function notifyForkResult(ctx: ExtensionCommandContext, forkedSessionFile: string | undefined, prompt: string, wasBusy: boolean): void {
	if (forkedSessionFile) {
		const fileName = path.basename(forkedSessionFile);
		const suffix = prompt ? " and sent prompt" : "";
		ctx.ui.notify(`Forked to ${fileName} in a new Ghostty split${suffix}.`, "info");
		if (wasBusy) {
			ctx.ui.notify("Forked from current committed state (in-flight turn continues in original session).", "info");
		}
	} else {
		ctx.ui.notify("Opened a new Ghostty split (no persisted session to fork).", "warning");
	}
}

export default function (pi: ExtensionAPI): void {
	pi.registerCommand("split-fork", {
		description: "Fork this session into a new pi process in a right-hand Ghostty split. Usage: /split-fork [optional prompt]",
		handler: async (args, ctx) => {
			const wasBusy = !ctx.isIdle();
			const prompt = args.trim();
			const forkedSessionFile = await createForkedSession(ctx);
			const startupInput = buildPiStartupInput(forkedSessionFile, prompt);

			if (process.platform !== "darwin") {
				const requestPath = enqueueSplitRequest(ctx.cwd, startupInput, forkedSessionFile);
				ctx.ui.notify(`Queued host relay split request: ${path.basename(requestPath)}`, "info");
				notifyForkResult(ctx, forkedSessionFile, prompt, wasBusy);
				return;
			}

			const result = await pi.exec("osascript", ["-e", GHOSTTY_SPLIT_SCRIPT, "--", ctx.cwd, startupInput]);
			if (result.code !== 0) {
				const reason = result.stderr?.trim() || result.stdout?.trim() || "unknown osascript error";
				ctx.ui.notify(`Failed to launch Ghostty split: ${reason}`, "error");
				if (forkedSessionFile) {
					ctx.ui.notify(`Forked session was created: ${forkedSessionFile}`, "info");
				}
				return;
			}

			notifyForkResult(ctx, forkedSessionFile, prompt, wasBusy);
		},
	});
}
