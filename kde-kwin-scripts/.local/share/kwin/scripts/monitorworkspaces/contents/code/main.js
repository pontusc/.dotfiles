// monitorworkspaces - Hyprland-style monitor-bound virtual desktops for KWin.
//
// Super+1..5 each ALWAYS drive a fixed monitor's virtual desktop, and Steam/
// games are routed onto a dedicated games desktop on the main monitor.
//
// Requires "Switch desktop independently for each screen"
// (kwinrc [Windows] PerOutputVirtualDesktops=true), Plasma 6.7+, Wayland.
//
// Multi-machine safe: if the expected outputs are not all connected, this
// script registers nothing and routes nothing (see REQUIRED_OUTPUTS).

// --- Config -----------------------------------------------------------------

// Super+<key> switches <output> to virtual desktop index <desktop>
// (0-based: index 0 == "Desktop 1").
var WORKSPACES = [
    { key: 1, desktop: 0, output: "DP-1" },
    { key: 2, desktop: 1, output: "DP-1" },
    { key: 3, desktop: 2, output: "DP-1" },  // games desktop
    { key: 4, desktop: 3, output: "DP-3" },
    { key: 5, desktop: 4, output: "DP-3" },
];

// Where games land.
var GAMES_DESKTOP = 2;        // 0-based -> "Desktop 3"
var GAMES_OUTPUT = "DP-1";
var SWITCH_TO_GAME_ON_LAUNCH = true;  // show the games desktop on its monitor when a game opens

// Game window matching (resourceClass is always lowercase in KWin).
var GAME_CLASSES = ["steam"];        // exact match (Steam client)
var GAME_PREFIXES = ["steam_app_"];  // prefix match (all Proton/Steam games)
var GAME_NAMED = [];                 // exact classes for native games, e.g. "factorio"

// Chat apps pinned to all desktops (always visible on their monitor).
var PIN_ALL_DESKTOPS = ["discord", "teamspeak"];  // substring match, lowercase

// This script only activates when ALL these outputs are connected.
var REQUIRED_OUTPUTS = ["DP-1", "DP-3"];

// --- Helpers ----------------------------------------------------------------

function outputByName(name) {
    var screens = workspace.screens;
    for (var i = 0; i < screens.length; i++) {
        if (screens[i].name === name) {
            return screens[i];
        }
    }
    return null;
}

function haveRequiredOutputs() {
    for (var i = 0; i < REQUIRED_OUTPUTS.length; i++) {
        if (outputByName(REQUIRED_OUTPUTS[i]) === null) {
            return false;
        }
    }
    return true;
}

function isGame(cls) {
    if (!cls) {
        return false;
    }
    if (GAME_CLASSES.indexOf(cls) !== -1 || GAME_NAMED.indexOf(cls) !== -1) {
        return true;
    }
    for (var i = 0; i < GAME_PREFIXES.length; i++) {
        if (cls.indexOf(GAME_PREFIXES[i]) === 0) {
            return true;
        }
    }
    return false;
}

function isPinned(cls) {
    if (!cls) {
        return false;
    }
    for (var i = 0; i < PIN_ALL_DESKTOPS.length; i++) {
        if (cls.indexOf(PIN_ALL_DESKTOPS[i]) !== -1) {
            return true;
        }
    }
    return false;
}

// Focus + raise the topmost normal, non-minimized window on the given
// output+desktop, so keyboard focus follows a switch/move. Returns false if
// there is no eligible window (e.g. an empty desktop). KWin scripts cannot
// move the mouse cursor (workspace.cursorPos is read-only), so this is
// focus-only -- the pointer stays where it is.
function focusTopOn(out, desk) {
    var wins = workspace.stackingOrder;  // bottom-to-top; topmost is last
    for (var i = wins.length - 1; i >= 0; i--) {
        var w = wins[i];
        if (w.output === out
            && (w.onAllDesktops || w.desktops.indexOf(desk) !== -1)
            && !w.minimized
            && w.normalWindow
            && w.wantsInput
            && !w.skipSwitcher) {
            workspace.activeWindow = w;
            workspace.raiseWindow(w);
            return true;
        }
    }
    return false;
}

// --- Window routing ---------------------------------------------------------

function routeWindow(window) {
    var cls = String(window.resourceClass || "").toLowerCase();

    if (isPinned(cls)) {
        window.onAllDesktops = true;
        return;
    }

    if (isGame(cls)) {
        var desk = workspace.desktops[GAMES_DESKTOP];
        var out = outputByName(GAMES_OUTPUT);
        if (!desk || !out) {
            return;
        }
        window.desktops = [desk];
        workspace.sendClientToScreen(window, out);
        if (SWITCH_TO_GAME_ON_LAUNCH) {
            workspace.setCurrentDesktopForScreen(desk, out);
        }
    }
}

// --- Shortcut wiring --------------------------------------------------------

// KWin on Wayland strips Shift from global-shortcut matching unless the shifted
// key is a letter (xkb.cpp modifiersRelevantForGlobalShortcuts; KDE bug 434988),
// so "Meta+Shift+<digit>" never fires -- only the digit's shifted SYMBOL does.
// QKeySequence needs the literal symbol char ("$"), NOT the keysym name
// ("dollar"), which parses to an empty (unbound) sequence. us-layout symbols:
var SHIFT_SYMBOL = { 1: "!", 2: "@", 3: "#", 4: "$", 5: "%" };

function registerWorkspaceShortcuts() {
    WORKSPACES.forEach(function (ws) {
        // Meta+<key>: switch <output> to its workspace.
        registerShortcut(
            "monitorworkspaces_ws" + ws.key,
            "Monitor Workspaces: workspace " + ws.key + " (" + ws.output + ")",
            "Meta+" + ws.key,
            function () {
                var out = outputByName(ws.output);
                var desk = workspace.desktops[ws.desktop];
                if (out && desk) {
                    workspace.setCurrentDesktopForScreen(desk, out);
                    focusTopOn(out, desk);
                }
            }
        );

        // Move the active window to that workspace and follow it there
        // (Hyprland movetoworkspace style). Physically Meta+Shift+<key>, but
        // bound to Meta+<shifted symbol> per the Wayland bug noted above. The
        // action name is bumped ("_movewindow_") when the key changes so
        // KGlobalAccel re-binds instead of keeping a stale entry for the name.
        registerShortcut(
            "monitorworkspaces_movewindow_ws" + ws.key,
            "Monitor Workspaces: move window to workspace " + ws.key + " (" + ws.output + ")",
            "Meta+" + SHIFT_SYMBOL[ws.key],
            function () {
                var w = workspace.activeWindow;
                var out = outputByName(ws.output);
                var desk = workspace.desktops[ws.desktop];
                if (w && out && desk) {
                    w.desktops = [desk];
                    workspace.sendClientToScreen(w, out);
                    workspace.setCurrentDesktopForScreen(desk, out);
                    workspace.activeWindow = w;   // keep focus on the moved window
                    workspace.raiseWindow(w);
                }
            }
        );
    });
}

// --- Startup ----------------------------------------------------------------

// On load, pin each monitor to its first/home desktop (the first WORKSPACES
// entry for that output). KWin otherwise restores whatever desktop each screen
// was left on before reboot, so without this a session left on the games
// desktop comes back there instead of starting in a known state.
function resetToHomeDesktops() {
    var done = {};
    WORKSPACES.forEach(function (ws) {
        if (done[ws.output]) {
            return;
        }
        var out = outputByName(ws.output);
        var desk = workspace.desktops[ws.desktop];
        if (out && desk) {
            workspace.setCurrentDesktopForScreen(desk, out);
            done[ws.output] = true;
        }
    });
}

// --- Entry point ------------------------------------------------------------

if (haveRequiredOutputs()) {
    registerWorkspaceShortcuts();
    workspace.windowAdded.connect(routeWindow);
    resetToHomeDesktops();
}
