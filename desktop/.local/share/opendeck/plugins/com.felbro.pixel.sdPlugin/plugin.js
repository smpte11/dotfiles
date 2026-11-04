const { execFile } = require("node:child_process");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const theme = require("./colors.json");
const { clock } = require("./clock");
const pomodoro = require("./pomodoro");

const holdToReset = 600;

const args = {};
for (let i = 2; i < process.argv.length; i += 2) args[process.argv[i].slice(1)] = process.argv[i + 1];

const ws = new WebSocket(`ws://127.0.0.1:${args.port}`);
const send = (event, context, payload) => {
  if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify({ event, context, payload }));
};

const chime = () => {
  const [command, ...rest] =
    os.platform() === "darwin" ? ["afplay", "/System/Library/Sounds/Glass.aiff"] : ["canberra-gtk-play", "--id", "complete"];
  execFile(command, rest, () => {});
};

const clocks = new Set();
const drawClock = clock(theme);
const renderClocks = () => {
  const image = drawClock(new Date());
  for (const context of clocks) send("setImage", context, { image, target: 0 });
};
const tickClocks = () => {
  renderClocks();
  setTimeout(tickClocks, 60_000 - (Date.now() % 60_000));
};

const stateFile = path.join(process.env.XDG_STATE_HOME || path.join(os.homedir(), ".local/state"), "opendeck-pixel", "timer.json");
const today = () => new Date().toDateString();

const loadSaved = () => {
  try {
    const saved = JSON.parse(fs.readFileSync(stateFile, "utf8"));
    return saved.day === today() ? saved.timer : undefined;
  } catch {
    return undefined;
  }
};

let focus = null;
let focusSettings = null;
const keys = new Map();

const save = () => {
  fs.mkdirSync(path.dirname(stateFile), { recursive: true });
  fs.writeFileSync(stateFile, JSON.stringify({ day: today(), timer: focus.snapshot() }));
};

const drawTimer = pomodoro.render(theme);
const renderTimers = () => {
  if (focus === null) return;
  const image = drawTimer(focus.view(Date.now()));
  for (const context of keys.keys()) send("setImage", context, { image, target: 0 });
};
setInterval(() => {
  if (focus === null) return;
  if (focus.tick(Date.now())) {
    chime();
    for (const context of keys.keys()) send("showOk", context);
    save();
  }
  if (focus.running() || focus.awaitingAck()) renderTimers();
}, 1000);

const actions = {
  "com.felbro.pixel.clock": {
    willAppear(context) {
      clocks.add(context);
      renderClocks();
    },
    willDisappear(context) {
      clocks.delete(context);
    },
  },
  "com.felbro.pixel.pomodoro": {
    willAppear(context, payload) {
      if (focus === null) {
        focusSettings = payload?.settings ?? {};
        focus = pomodoro.timer(focusSettings, loadSaved());
      } else if (!pomodoro.sameSettings(payload?.settings, focusSettings)) {
        send("setSettings", context, focusSettings);
      }
      keys.set(context, { hold: null });
      renderTimers();
    },
    didReceiveSettings(context, payload) {
      const settings = payload?.settings ?? {};
      if (pomodoro.sameSettings(settings, focusSettings)) return;
      focusSettings = settings;
      focus.configure(focusSettings);
      for (const other of keys.keys()) if (other !== context) send("setSettings", other, focusSettings);
      save();
      renderTimers();
    },
    willDisappear(context) {
      clearTimeout(keys.get(context)?.hold);
      keys.delete(context);
    },
    keyDown(context) {
      const key = keys.get(context);
      key.hold = setTimeout(() => {
        key.hold = null;
        focus.reset();
        save();
        renderTimers();
      }, holdToReset);
    },
    keyUp(context) {
      const key = keys.get(context);
      if (key.hold === null) return;
      clearTimeout(key.hold);
      key.hold = null;
      focus.toggle(Date.now());
      save();
      renderTimers();
    },
  },
};

ws.addEventListener("open", () => {
  ws.send(JSON.stringify({ event: args.registerEvent, uuid: args.pluginUUID }));
});

ws.addEventListener("message", ({ data }) => {
  const { event, action, context, payload } = JSON.parse(data);
  actions[action]?.[event]?.(context, payload);
});

ws.addEventListener("close", () => process.exit(0));

tickClocks();
