import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";

const PANE_TAG_OPTION = "@claude";
const DONE_AFTER_MS = 60_000;
const TMUX_COMMAND_TIMEOUT_MS = 1_000;
const paneTagEnabled = process.env.OMP_TMUX_PANE_TAG !== "0";
const promptStartedAt = new Map<string, number>();

type PaneState = {
  paneActive: string;
  windowActive: string;
  sessionAttached: string;
  sessionName: string;
  windowName: string;
};

function currentPane(): string | undefined {
  const pane = process.env.TMUX_PANE?.trim();
  return pane || undefined;
}

async function tmux(args: string[], captureOutput = false): Promise<string> {
  const child = Bun.spawn(["tmux", ...args], {
    stdout: captureOutput ? "pipe" : "ignore",
    stderr: "ignore",
    timeout: TMUX_COMMAND_TIMEOUT_MS,
    killSignal: "SIGKILL",
  });

  if (!captureOutput) {
    await child.exited;
    return "";
  }

  const output = await new Response(child.stdout).text();
  await child.exited;
  return output;
}

async function paneState(pane: string): Promise<PaneState | undefined> {
  const output = await tmux([
    "display",
    "-p",
    "-t",
    pane,
    "-F",
    "#{pane_active}\t#{window_active}\t#{session_attached}\t#{session_name}\t#{window_name}",
  ], true);
  const [paneActive, windowActive, sessionAttached, sessionName, windowName] = output.trim().split("\t");
  if (!paneActive || !windowActive || !sessionAttached || !sessionName || !windowName) return undefined;
  return { paneActive, windowActive, sessionAttached, sessionName, windowName };
}

async function clearPaneTag(): Promise<void> {
  const pane = currentPane();
  if (!pane) return;
  await tmux(["set-option", "-w", "-t", pane, "-u", PANE_TAG_OPTION]);
}

async function raiseAttention(flag: "ask" | "done", message: string): Promise<void> {
  const pane = currentPane();
  if (!pane) return;
  const state = await paneState(pane);
  if (!state) return;

  const clients = await tmux(["list-clients", "-t", state.sessionName, "-F", "#{client_flags}"], true);
  const focused = clients.split("\n").some((flags) => flags.includes("focused"));
  const visible =
    state.paneActive === "1" &&
    state.windowActive === "1" &&
    state.sessionAttached === "1" &&
    focused;
  if (visible) return;

  if (paneTagEnabled) {
    await tmux(["set-option", "-w", "-t", pane, PANE_TAG_OPTION, flag]);
  }

  const clientNames = await tmux(["list-clients", "-F", "#{client_name}"], true);
  for (const client of clientNames.split("\n").map((name) => name.trim()).filter(Boolean)) {
    await tmux([
      "display-message",
      "-c",
      client,
      `${message}, ${state.sessionName}:${state.windowName}`,
    ]);
  }
}

async function safely(action: () => Promise<void>): Promise<void> {
  try {
    await action();
  } catch (error) {
    console.error(`[tmux-attention] ${String(error)}`);
  }
}

function sessionId(ctx: ExtensionContext): string {
  return ctx.sessionManager.getSessionId();
}

export default function tmuxAttention(pi: ExtensionAPI): void {
  pi.on("session_start", async (_event, _ctx) => {
    await safely(clearPaneTag);
  });

  pi.on("input", async (_event, ctx) => {
    promptStartedAt.set(sessionId(ctx), Date.now());
    await safely(clearPaneTag);
  });

  pi.on("tool_result", async (_event, _ctx) => {
    await safely(clearPaneTag);
  });

  pi.on("tool_approval_requested", async (event, _ctx) => {
    await safely(() => raiseAttention("ask", `OMP asks${event.toolName ? `, ${event.toolName}` : ""}`));
  });

  pi.on("session_stop", async (_event, ctx) => {
    const id = sessionId(ctx);
    const startedAt = promptStartedAt.get(id);
    promptStartedAt.delete(id);
    if (startedAt === undefined || Date.now() - startedAt >= DONE_AFTER_MS) {
      await safely(() => raiseAttention("done", "OMP finished"));
    }
  });
}
