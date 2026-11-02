const { large, small, mix, steps, rect, text, textWidth, svg, pad } = require("./pixel");

const width = 248;
const visibleWidth = 232;
const height = 58;
const pixel = 2;
const horizon = 38;
const sun = { x: 160, r: 28 };
const stars = [
  [6, 4], [44, 2], [70, 8], [96, 4], [118, 12], [130, 2], [142, 8], [196, 6], [204, 30], [222, 26], [124, 26],
];

const scene = (colors) => {
  const parts = [];
  const bands = 6;
  for (let y = 0; y < horizon; y += pixel) {
    const band = Math.floor((y / horizon) * bands) / (bands - 1);
    parts.push(rect(0, y, width, pixel, steps([colors.background, mix(colors.background, colors.sky, 0.5), mix(colors.background, colors.neon, 0.6)], band)));
  }
  for (const [x, y] of stars) parts.push(rect(x, y, pixel, pixel, mix(colors.date, colors.sky, 0.3)));
  const gaps = [[24, 26], [29, 31], [33, 36]];
  for (let y = horizon - sun.r; y < horizon; y += pixel) {
    if (gaps.some(([from, to]) => y >= from && y < to)) continue;
    const half = Math.floor(Math.sqrt(sun.r ** 2 - (horizon - y) ** 2) / pixel) * pixel;
    parts.push(rect(sun.x - half, y, half * 2, pixel, mix(colors.sunTop, colors.sunBottom, (y - (horizon - sun.r)) / sun.r)));
  }
  parts.push(rect(0, horizon, width, height - horizon, mix(colors.background, "#000000", 0.35)));
  for (let offset = -4; offset <= 2; offset++) {
    parts.push(`<line x1="${sun.x}" y1="${horizon}" x2="${sun.x + offset * 64}" y2="${height}" stroke="${colors.neon}" stroke-width="${pixel}"/>`);
  }
  for (const y of [horizon + 4, horizon + 9, horizon + 16]) parts.push(rect(0, y, width, pixel, colors.neon));
  parts.push(rect(0, horizon, width, pixel, colors.glow));
  return parts.join("");
};

const clock = (theme) => {
  const colors = {
    background: theme.background,
    sky: theme.palette.blue,
    neon: theme.palette.magenta,
    glow: theme.palette.bright_magenta,
    sunTop: theme.palette.yellow,
    sunBottom: theme.palette.red,
    time: theme.palette.cyan,
    date: theme.palette.white,
  };
  const backdrop = scene(colors);
  return (now) => {
    const time = `${pad(now.getHours())}:${pad(now.getMinutes())}`;
    const day = now.toLocaleDateString("en", { weekday: "short" }).toUpperCase();
    const date = `${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
    const dayX = visibleWidth - 6 - textWidth(small, day, pixel);
    const dateX = visibleWidth - 6 - textWidth(small, date, pixel);
    return svg(
      width,
      height,
      backdrop +
        text(large, time, 10, 7, 4, colors.neon) +
        text(large, time, 8, 5, 4, colors.time) +
        text(small, day, dayX + pixel, 6, pixel, colors.background) +
        text(small, day, dayX, 4, pixel, colors.date) +
        text(small, date, dateX + pixel, 18, pixel, colors.background) +
        text(small, date, dateX, 16, pixel, colors.date),
    );
  };
};

module.exports = { clock };
