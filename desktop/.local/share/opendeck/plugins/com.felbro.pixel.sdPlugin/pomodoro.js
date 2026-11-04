const { large, small, rect, text, textWidth, svg, pad } = require("./pixel");

const size = 144;
const pixel = 4;
const labels = { work: "WORK", shortBreak: "BREAK", longBreak: "LONG" };

const config = (settings = {}) => ({
  work: (settings.workMinutes ?? 25) * 60_000,
  shortBreak: (settings.shortBreakMinutes ?? 5) * 60_000,
  longBreak: (settings.longBreakMinutes ?? 15) * 60_000,
  cycles: settings.totalCycles ?? 4,
});

const timer = (settings, saved) => {
  const durations = config(settings);
  const autoAdvance = settings?.autoAdvance ?? false;
  const state =
    saved && saved.phase in labels
      ? { awaitingAck: false, ...saved }
      : { phase: "work", completed: 0, remaining: durations.work, endsAt: null, awaitingAck: false };

  const remaining = (now) => (state.endsAt === null ? state.remaining : Math.max(0, state.endsAt - now));

  const advance = () => {
    if (state.phase === "work") {
      state.completed += 1;
      state.phase = state.completed % durations.cycles === 0 ? "longBreak" : "shortBreak";
    } else {
      if (state.phase === "longBreak") state.completed = 0;
      state.phase = "work";
    }
    state.remaining = durations[state.phase];
    state.endsAt = null;
  };

  return {
    running: () => state.endsAt !== null,
    awaitingAck: () => state.awaitingAck,
    snapshot: () => ({ ...state }),
    toggle(now) {
      state.awaitingAck = false;
      if (state.endsAt === null) {
        state.endsAt = now + state.remaining;
      } else {
        state.remaining = remaining(now);
        state.endsAt = null;
      }
    },
    reset() {
      state.phase = "work";
      state.completed = 0;
      state.remaining = durations.work;
      state.endsAt = null;
      state.awaitingAck = false;
    },
    tick(now) {
      if (state.endsAt === null || remaining(now) > 0) return false;
      advance();
      if (autoAdvance) state.endsAt = now + state.remaining;
      else state.awaitingAck = true;
      return true;
    },
    view(now) {
      const left = remaining(now);
      return {
        phase: state.phase,
        running: state.endsAt !== null,
        flash: state.awaitingAck && Math.floor(now / 1000) % 2 === 0,
        remaining: left,
        progress: 1 - left / durations[state.phase],
        completed: state.phase === "longBreak" ? durations.cycles : state.completed % durations.cycles,
        cycles: durations.cycles,
      };
    },
  };
};

const render = (theme) => {
  const phaseColors = { work: theme.palette.red, shortBreak: theme.palette.green, longBreak: theme.palette.cyan };
  const background = theme.background;
  const track = theme.base.b02;
  const shadow = theme.base.b01;
  const muted = theme.palette.silver;
  return (view) => {
    const phase = phaseColors[view.phase];
    const color = view.flash ? background : phase;
    const fill = view.running ? color : muted;
    const ink = view.flash ? background : view.running ? theme.foreground : muted;
    const seconds = Math.ceil(view.remaining / 1000);
    const time = `${pad(Math.floor(seconds / 60))}:${pad(seconds % 60)}`;
    const label = labels[view.phase];
    const parts = [rect(0, 0, size, size, view.flash ? phase : background)];
    parts.push(text(small, label, (size - textWidth(small, label, pixel)) / 2, 14, pixel, color));
    const timeX = (size - textWidth(large, time, pixel)) / 2;
    parts.push(text(large, time, timeX + pixel / 2, 46 + pixel / 2, pixel, shadow));
    parts.push(text(large, time, timeX, 46, pixel, ink));
    const barWidth = size - 32;
    const filled = Math.round((barWidth * view.progress) / pixel) * pixel;
    parts.push(rect(16, 90, barWidth, 8, track), rect(16, 90, filled, 8, fill));
    const done = view.flash ? theme.foreground : phaseColors.work;
    const dot = 12;
    const gap = 8;
    const dotsX = (size - (view.cycles * dot + (view.cycles - 1) * gap)) / 2;
    for (let i = 0; i < view.cycles; i++) {
      parts.push(rect(dotsX + i * (dot + gap), 112, dot, dot, i < view.completed ? done : track));
    }
    return svg(size, size, parts.join(""));
  };
};

module.exports = { timer, render };
