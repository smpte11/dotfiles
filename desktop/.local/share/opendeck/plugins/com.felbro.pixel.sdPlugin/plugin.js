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

const stateFile = path.join(process.env.XDG_STATE_HOME || path.join(os.homedir(), ".local/state"), "opendeck-pixel", "timers.json");
const today = () => new Date().toDateString();

const loadSaved = () => {
  try {
    const saved = JSON.parse(fs.readFileSync(stateFile, "utf8"));
    return saved.day === today() ? saved.timers : {};
  } catch {
    return {};
  }
};

const saved = loadSaved();
const timers = new Map();

const save = () => {
  const snapshot = { day: today(), timers: { ...saved } };
  for (const [context, entry] of timers) snapshot.timers[context] = entry.timer.snapshot();
  fs.mkdirSync(path.dirname(stateFile), { recursive: true });
  fs.writeFileSync(stateFile, JSON.stringify(snapshot));
};

const drawTimer = pomodoro.render(theme);
const renderTimer = (context) => {
  const entry = timers.get(context);
  if (entry) send("setImage", context, { image: drawTimer(entry.timer.view(Date.now())), target: 0 });
};
setInterval(() => {
  for (const [context, entry] of timers) {
    if (entry.timer.tick(Date.now())) {
      chime();
      send("showOk", context);
      save();
    }
    if (entry.timer.running()) renderTimer(context);
  }
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
      if (!timers.has(context)) timers.set(context, { timer: pomodoro.timer(payload?.settings, saved[context]), hold: null });
      renderTimer(context);
    },
    willDisappear() {},
    keyDown(context) {
      const entry = timers.get(context);
      entry.hold = setTimeout(() => {
        entry.hold = null;
        entry.timer.reset();
        save();
        renderTimer(context);
      }, holdToReset);
    },
    keyUp(context) {
      const entry = timers.get(context);
      if (entry.hold === null) return;
      clearTimeout(entry.hold);
      entry.hold = null;
      entry.timer.toggle(Date.now());
      save();
      renderTimer(context);
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
