/**
 * Caveman mode indicator in the footer.
 *
 * Replaces the built-in footer with a single line: token stats on the left,
 * and on the right the caveman mode directly beside the model name and the
 * current jj bookmark. Default mode is "caveman" because
 * ~/.pi/agent/APPEND_SYSTEM.md activates the caveman voice at every session
 * startup. Mode changes are tracked from raw user input; input always passes
 * through unchanged.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

type CavemanMode = "caveman" | "ultracave" | "megacave" | "off";

export default function (pi: ExtensionAPI) {
	let mode: CavemanMode = "caveman";
	let bookmark = "";
	let requestRender: (() => void) | null = null;

	async function refreshBookmark(): Promise<void> {
		const at = await pi.exec("jj", ["log", "-r", "@", "--no-graph", "-T", 'bookmarks ++ " "'], { timeout: 5000 });
		let name = at.code === 0 ? at.stdout.trim() : "";
		if (!name) {
			const parent = await pi.exec("jj", ["log", "-r", "@-", "--no-graph", "-T", 'bookmarks ++ " "'], { timeout: 5000 });
			name = parent.code === 0 ? parent.stdout.trim() : "";
		}
		bookmark = name;
		requestRender?.();
	}

	pi.on("session_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		await refreshBookmark();
		ctx.ui.setFooter((tui, theme, _footerData) => {
			requestRender = () => tui.requestRender();
			return {
				invalidate() {},
				render(width: number): string[] {
					let input = 0,
						output = 0,
						context = 0;
					for (const e of ctx.sessionManager.getBranch()) {
						if (e.type === "message" && e.message.role === "assistant") {
							const m = e.message as AssistantMessage;
							input += m.usage.input;
							output += m.usage.output;
							context = m.usage.input;
						}
					}
					const fmt = (n: number) => (n < 1000 ? `${n}` : `${(n / 1000).toFixed(1)}k`);
					const window = ctx.model?.contextWindow ?? 0;
					const ctxLabel = window ? `${fmt(context)}/${fmt(window)}` : fmt(context);
					const left = theme.fg("dim", `in ↑${fmt(input)} out ↓${fmt(output)} ctx ${ctxLabel}`);

					const caveman = theme.fg(mode === "off" ? "dim" : "accent", `caveman: ${mode}`);
					const bookmarkStr = bookmark ? ` (${bookmark})` : "";
					const right = theme.fg("dim", `${ctx.model?.id || "no-model"}${bookmarkStr}`);
					const line = `${caveman}  ${right}`;

					const pad = " ".repeat(Math.max(1, width - visibleWidth(left) - visibleWidth(line)));
					return [truncateToWidth(left + pad + line, width)];
				},
			};
		});
	});

	pi.on("input", async (event, ctx) => {
		const text = event.text.trim().toLowerCase();
		let changed = false;
		if (text.includes("stop caveman") || text.includes("normal mode")) {
			mode = "off";
			changed = true;
		} else if (text.includes("/caveman ultra") || text.startsWith("/ultracave")) {
			mode = "ultracave";
			changed = true;
		} else if (text.includes("/caveman wenyan") || text.startsWith("/megacave")) {
			mode = "megacave";
			changed = true;
		} else if (text.includes("/caveman") || text.includes("/skill:caveman")) {
			mode = "caveman";
			changed = true;
		}
		if (changed) requestRender?.();
		if (ctx.mode === "tui") await refreshBookmark();
		return { action: "continue" };
	});

	pi.registerCommand("caveman-status", {
		description: "Report the current caveman mode",
		handler: async (_args, ctx) => {
			ctx.ui.notify(`Caveman mode: ${mode}`, "info");
		},
	});
}
