/**
 * notify-user — HTTP beep when Pi needs user input or finishes a task.
 *
 * GET http://host.docker.internal:9001/beep
 */

import type { ExtensionAPI, ExtensionUIContext } from "@earendil-works/pi-coding-agent";

const BEEP_URL = "http://host.docker.internal:9001/beep";

const wrappedUi = new WeakSet<ExtensionUIContext>();

function beep(): void {
	fetch(BEEP_URL, { method: "GET" }).catch(() => {});
}

function wrapBlockingUi(ui: ExtensionUIContext): void {
	if (wrappedUi.has(ui)) return;
	wrappedUi.add(ui);

	const { select, confirm, input, editor, custom } = ui;

	ui.select = async (title, options, opts) => {
		beep();
		return select(title, options, opts);
	};

	ui.confirm = async (title, message, opts) => {
		beep();
		return confirm(title, message, opts);
	};

	ui.input = async (title, placeholder, opts) => {
		beep();
		return input(title, placeholder, opts);
	};

	ui.editor = async (title, prefill) => {
		beep();
		return editor(title, prefill);
	};

	ui.custom = async (factory, options) => {
		beep();
		return custom(factory, options);
	};
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (ctx.hasUI) wrapBlockingUi(ctx.ui);
	});

	pi.on("agent_end", async () => {
		beep();
	});
}
