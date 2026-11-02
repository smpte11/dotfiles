const { large, small, mix, rect, text, textWidth, svg, pad } = require("./pixel");

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
  const state = saved && saved.phase in labels ? { ...saved } : { phase: "work", completed: 0, remaining: durations.work, endsAt: null };

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
    snapshot: () => ({ ...state }),
    toggle(now) {
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
    },
    tick(now) {
      if (state.endsAt === null || remaining(now) > 0) return false;
      advance();
      return true;
    },
    view(now) {
      const left = remaining(now);
      return {
        phase: state.phase,
        running: state.endsAt !== null,
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
  const ink = theme.palette.white;
  return (view) => {
    const color = view.running ? phaseColors[view.phase] : mix(phaseColors[view.phase], background, 0.45);
    const dim = mix(phaseColors[view.phase], background, 0.75);
    const seconds = Math.ceil(view.remaining / 1000);
    const time = `${pad(Math.floor(seconds / 60))}:${pad(seconds % 60)}`;
    const label = labels[view.phase];
    const parts = [rect(0, 0, size, size, background)];
    parts.push(rect(0, 0, size, pixel, color), rect(0, size - pixel, size, pixel, color), rect(0, 0, pixel, size, color), rect(size - pixel, 0, pixel, size, color));
    parts.push(text(small, label, (size - textWidth(small, label, pixel)) / 2, 14, pixel, color));
    const timeX = (size - textWidth(large, time, pixel)) / 2;
    parts.push(text(large, time, timeX + pixel / 2, 46 + pixel / 2, pixel, dim));
    parts.push(text(large, time, timeX, 46, pixel, view.running ? ink : mix(ink, background, 0.45)));
    const barWidth = size - 32;
    const filled = Math.round((barWidth * view.progress) / pixel) * pixel;
    parts.push(rect(16, 90, barWidth, 8, dim), rect(16, 90, filled, 8, color));
    const dot = 12;
    const gap = 8;
    const dotsX = (size - (view.cycles * dot + (view.cycles - 1) * gap)) / 2;
    for (let i = 0; i < view.cycles; i++) {
      parts.push(rect(dotsX + i * (dot + gap), 112, dot, dot, i < view.completed ? phaseColors.work : dim));
    }
    return svg(size, size, parts.join(""));
  };
};

module.exports = { timer, render };
