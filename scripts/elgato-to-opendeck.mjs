#!/usr/bin/env node
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { parseArgs } from "node:util";

const repo = path.resolve(import.meta.dirname, "..");
const { values: args } = parseArgs({
  options: {
    elgato: { type: "string", default: path.join(os.homedir(), "Library/Application Support/com.elgato.StreamDeck/ProfilesV3") },
    starterpack: { type: "string", default: "/Applications/OpenDeck.app/Contents/Resources/plugins/com.amansprojects.starterpack.sdPlugin" },
    plugins: {
      type: "string",
      multiple: true,
      default: [path.join(repo, "desktop/.local/share/opendeck/plugins/com.felbro.journal.sdPlugin"), path.join(repo, "desktop/.local/share/opendeck/plugins/com.felbro.pixel.sdPlugin")],
    },
    out: { type: "string", default: path.join(repo, "desktop/.local/share/opendeck") },
  },
});

const targets = ["macos", "linux"];
const models = { "20GBJ9901": { columns: 4, rows: 2, touchpoints: 2, infobars: 1 } };
const elgatoDevice = /^@\(1\)\[\d+\/\d+\/(\w+)\]$/;
const selfRendering = new Set(["com.felbro.journal.sdPlugin", "com.felbro.pixel.sdPlugin"]);
const infobarActions = { "com.elgato.streamdeck.system.digitaltime": "com.felbro.pixel.clock" };
const timerSettings = ["workMinutes", "shortBreakMinutes", "longBreakMinutes", "totalCycles"];

const defaultState = {
  alignment: "middle",
  background_colour: "#000000",
  colour: "#FFFFFF",
  family: "Liberation Sans",
  image: "actionDefaultImage",
  image_override: null,
  image_scale: 100,
  name: "",
  show: true,
  size: 16,
  stroke_colour: "#000000",
  stroke_size: 3,
  style: "Regular",
  text: "",
  text_override: null,
  underline: false,
};

const manifestStateKeys = {
  Image: "image",
  Name: "name",
  Title: "text",
  ShowTitle: "show",
  TitleColor: "colour",
  TitleAlignment: "alignment",
  FontFamily: "family",
  FontStyle: "style",
  FontSize: "size",
  FontUnderline: "underline",
};

const fontFamilies = {
  arial: "Liberation Sans",
  "arial black": "Archivo Black",
  "comic sans ms": "Comic Neue",
  courier: "Courier Prime",
  georgia: "Tinos",
  impact: "Anton",
  "microsoft sans serif": "Liberation Serif",
  tahoma: "Open Sans",
  "trebuchet ms": "Fira Sans",
};

const media = {
  previous: { title: "Previous", key: "MediaPrevTrack" },
  playPause: { title: "Play", key: "MediaPlayPause" },
  next: { title: "Next", key: "MediaNextTrack" },
  mute: { title: "Mute", key: "VolumeMute" },
  volumeUp: { title: "Volume +", key: "VolumeUp" },
  volumeDown: { title: "Volume -", key: "VolumeDown" },
};
const multimediaByIndex = [media.previous, media.playPause, media.next, null, media.mute, media.volumeUp, media.volumeDown];
const appleMusic = {
  "com.elgato.applemusic.previous": media.previous,
  "com.elgato.applemusic.play": media.playPause,
  "com.elgato.applemusic.next": media.next,
};

const modifiers = {
  macos: { KeyCmd: "Meta", KeyCtrl: "Control", KeyOption: "Alt", KeyShift: "Shift" },
  linux: { KeyCmd: "Control", KeyCtrl: "Control", KeyOption: "Alt", KeyShift: "Shift" },
};
const linuxShortcuts = {
  "cmd+shift+3": ["Print"],
  "cmd+shift+4": ["Print"],
  "cmd+shift+5": ["Print"],
  "cmd+ctrl+space": null,
};
const qtKeys = {
  0x01000000: "Escape",
  0x01000001: "Tab",
  0x01000003: "Backspace",
  0x01000004: "Return",
  0x01000005: "Return",
  0x01000007: "Delete",
  0x01000010: "Home",
  0x01000011: "End",
  0x01000012: "LeftArrow",
  0x01000013: "UpArrow",
  0x01000014: "RightArrow",
  0x01000015: "DownArrow",
  0x01000016: "PageUp",
  0x01000017: "PageDown",
  ...Object.fromEntries(Array.from({ length: 20 }, (_, i) => [0x01000030 + i, `F${i + 1}`])),
};

const apps = {
  macos: (target) => (target === "/Applications/Elgato Stream Deck.app" ? "open -a OpenDeck" : `open ${JSON.stringify(target)}`),
  linux: (target) => ({ "/": "xdg-open /", "/System/Applications/Calculator.app": "gnome-calculator" })[target],
};

const readJson = (file) => JSON.parse(fs.readFileSync(file, "utf8").replace(/^﻿/, ""));

const sorted = (value) => {
  if (Array.isArray(value)) return value.map(sorted);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.keys(value).sort().map((key) => [key, sorted(value[key])]));
  }
  return value;
};

const writeJson = (file, value) => {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(sorted(value), null, 2));
};

const iconPath = (pluginDir, plugin, icon) => {
  const base = path.join(pluginDir, icon);
  const suffix = [".svg", "@2x.png"].find((ext) => fs.existsSync(base + ext)) ?? ".png";
  return `plugins/${plugin}/${icon}${suffix}`;
};

const loadActions = (pluginDir) => {
  const manifest = readJson(path.join(pluginDir, "manifest.json"));
  const plugin = path.basename(pluginDir);
  return manifest.Actions.map((entry) => {
    const icon = iconPath(pluginDir, plugin, entry.Icon ?? "");
    const inspector = entry.PropertyInspectorPath ?? manifest.PropertyInspectorPath;
    const states = entry.States.map((manifestState) => {
      const state = { ...defaultState };
      for (const [key, field] of Object.entries(manifestStateKeys)) {
        if (manifestState[key] !== undefined && manifestState[key] !== null) state[field] = manifestState[key];
      }
      state.size = Number(state.size);
      state.image = state.image === "actionDefaultImage" ? icon : iconPath(pluginDir, plugin, state.image);
      state.family = fontFamilies[state.family.toLowerCase().trim()] ?? state.family;
      return state;
    });
    return {
      name: entry.Name,
      uuid: entry.UUID,
      plugin,
      tooltip: entry.Tooltip ?? "",
      icon,
      disable_automatic_states: entry.DisableAutomaticStates ?? false,
      visible_in_action_list: entry.VisibleInActionsList ?? true,
      supported_in_multi_actions: entry.SupportedInMultiActions ?? true,
      property_inspector: inspector ? `plugins/${plugin}/${inspector}` : "",
      controllers: entry.Controllers ?? ["Keypad"],
      encoder: null,
      states,
    };
  });
};

const actions = Object.fromEntries([args.starterpack, ...args.plugins].flatMap(loadActions).map((action) => [action.uuid, action]));
const starter = (name) => actions[`com.amansprojects.starterpack.${name}`];

const ronChar = (char) => (char === "'" || char === "\\" ? `'\\${char}'` : `'${char}'`);
const ronString = (text) => `"${text.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`;
const ron = (tokens) => `[${tokens.join(",")}]`;
const press = (keys) => [...keys.slice(0, -1).map((key) => `Key(${key},Press)`), `Key(${keys.at(-1)},Click)`, ...keys.slice(0, -1).reverse().map((key) => `Key(${key},Release)`)];

const qtKey = (code) => {
  if (qtKeys[code]) return qtKeys[code];
  if (code === 32) return "Space";
  if (code > 32 && code < 127) return `Unicode(${ronChar(String.fromCharCode(code).toLowerCase())})`;
  return null;
};

const hotkey = (settings, target) => {
  const tokens = [];
  for (const entry of settings.Hotkeys.filter((entry) => entry.QTKeyCode !== 33554431)) {
    const key = qtKey(entry.QTKeyCode);
    if (!key) return null;
    const held = ["KeyCmd", "KeyCtrl", "KeyOption", "KeyShift"].filter((modifier) => entry[modifier]);
    const combo = [...held.map((modifier) => modifier.slice(3).toLowerCase()), key.replace(/^Unicode\('(.*)'\)$/, "$1").toLowerCase()].join("+");
    if (target === "linux" && combo in linuxShortcuts) {
      if (!linuxShortcuts[combo]) return null;
      tokens.push(...press(linuxShortcuts[combo]));
      continue;
    }
    tokens.push(...press([...new Set(held.map((modifier) => modifiers[target][modifier])), key]));
  }
  return tokens.length ? ron(tokens) : null;
};

const mediaKey = (entry) => ({ action: starter("inputsimulation"), settings: { down: ron([`Key(${entry.key},Click)`]) }, title: entry.title });
const switchTo = (profile, title) => ({ action: starter("switchprofile"), settings: { profile }, title });

const convertAction = (elgato, target, folders) => {
  const settings = elgato.Settings ?? {};
  switch (elgato.UUID) {
    case "com.elgato.streamdeck.system.website":
      return { action: starter("openurl"), settings: { down: settings.path } };
    case "com.elgato.streamdeck.system.open": {
      const command = apps[target](JSON.parse(settings.path));
      return command && { action: starter("runcommand"), settings: { down: command } };
    }
    case "com.elgato.streamdeck.system.text": {
      const tokens = [`Text(${ronString(settings.pastedText)})`, ...(settings.isSendingEnter ? ["Key(Return,Click)"] : [])];
      return { action: starter("inputsimulation"), settings: { down: ron(tokens) } };
    }
    case "com.elgato.streamdeck.system.hotkey": {
      const down = hotkey(settings, target);
      return down && { action: starter("inputsimulation"), settings: { down } };
    }
    case "com.elgato.streamdeck.system.multimedia": {
      const entry = multimediaByIndex[settings.actionIdx];
      return entry && { ...mediaKey(entry), title: null };
    }
    case "com.elgato.streamdeck.profile.openchild":
      return switchTo(folders.child(settings.ProfileUUID, elgato.States?.[0]?.Title));
    case "com.elgato.streamdeck.profile.backtoparent":
      return switchTo(folders.parent, "Back");
    case "com.oreosparkman.productivity-timer.timer":
      return { action: actions["com.felbro.pixel.pomodoro"], settings: Object.fromEntries(timerSettings.filter((key) => key in settings).map((key) => [key, settings[key]])) };
    default:
      if (appleMusic[elgato.UUID]) return mediaKey(appleMusic[elgato.UUID]);
      if (actions[elgato.UUID]) return { action: actions[elgato.UUID], settings };
      return null;
  }
};

const instance = (converted, context, imageOverride, elgatoState) => {
  const states = converted.action.states.map((state) => ({ ...state }));
  const state = states[0];
  const title = converted.title === undefined ? elgatoState?.Title : converted.title;
  if (title) {
    state.text = title.replace(/\n+/g, "\n");
    state.show = elgatoState?.ShowTitle ?? true;
    state.alignment = elgatoState?.TitleAlignment ?? (imageOverride ? "bottom" : "middle");
    state.colour = elgatoState?.TitleColor ?? state.colour;
  }
  if (imageOverride) state.image_override = imageOverride;
  if (selfRendering.has(converted.action.plugin)) state.image = "0.svg";
  return { action: converted.action, context, states, current_state: 0, settings: converted.settings, children: null };
};

const folderName = (title) => (title ?? "Folder").replace(/\s+/g, " ").replace(/\//g, "-").trim() || "Folder";

const convertBundle = (bundleDir, report) => {
  const manifest = readJson(path.join(bundleDir, "manifest.json"));
  const serial = manifest.Device.UUID.match(elgatoDevice)?.[1];
  const model = models[manifest.Device.Model];
  if (!serial || !model) {
    report.push(`skip ${manifest.Name}: device ${manifest.Device.Model} is not a supported physical deck`);
    return [];
  }
  const device = `sd-${serial}`;
  const base = manifest.Name === "Default Profile" ? "Default" : manifest.Name;
  const pageDir = (id) => path.join(bundleDir, "Profiles", id.toUpperCase());
  const profiles = [];
  const visited = new Set();
  const neoActions = (id) => readJson(path.join(pageDir(id), "manifest.json")).Controllers.find((controller) => controller.Type === "Neo")?.Actions ?? {};
  const sharedNeo = neoActions(manifest.Pages.Default);

  const convertInfobar = (neo, name) => {
    const infobars = Array(model.infobars).fill(null);
    for (const [coordinates, elgato] of Object.entries(neo)) {
      const action = actions[infobarActions[elgato.UUID]];
      if (coordinates !== "1,0" || !action) {
        report.push(`both ${device} ${name}: dropped Neo ${coordinates} ${elgato.UUID}`);
        continue;
      }
      infobars[0] = instance({ action, settings: {}, title: null }, "Infobar.0.0", null, null);
    }
    return infobars;
  };

  const convertPage = (id, name, parent, navigation) => {
    if (visited.has(id.toLowerCase())) return;
    visited.add(id.toLowerCase());
    const dir = pageDir(id);
    const page = readJson(path.join(dir, "manifest.json"));
    const keypad = page.Controllers.find((controller) => controller.Type === "Keypad")?.Actions ?? {};
    const children = new Map();
    const folders = {
      parent,
      child: (childId, title) => {
        const childName = `${name}/${folderName(title)}`;
        children.set(childId, childName);
        return childName;
      },
    };
    const keys = Object.fromEntries(targets.map((target) => [target, Array(model.columns * model.rows + model.touchpoints).fill(null)]));
    const images = [];
    for (const [coordinates, elgato] of Object.entries(keypad)) {
      const [column, row] = coordinates.split(",").map(Number);
      const position = row * model.columns + column;
      const context = `Keypad.${position}.0`;
      const elgatoState = elgato.States?.[0];
      for (const target of targets) {
        const converted = convertAction(elgato, target, folders);
        if (!converted) {
          report.push(`${target} ${device} ${name} key ${position}: dropped ${elgato.UUID}`);
          continue;
        }
        const imageOverride = elgatoState?.Image ? "0-user.png" : null;
        if (imageOverride && target === targets[0]) images.push([path.join(dir, elgatoState.Image), path.join(device, name, context, imageOverride)]);
        keys[target][position] = instance(converted, context, imageOverride, elgatoState);
      }
    }
    const neo = neoActions(id);
    const infobars = convertInfobar(Object.keys(neo).length ? neo : sharedNeo, name);
    if (navigation) {
      for (const target of targets) {
        keys[target][model.columns * model.rows] = instance(switchTo(navigation.previous, null), `Keypad.${model.columns * model.rows}.0`, null, null);
        keys[target][model.columns * model.rows + 1] = instance(switchTo(navigation.next, null), `Keypad.${model.columns * model.rows + 1}.0`, null, null);
      }
    }
    profiles.push({ device, name, keys, images, infobars });
    for (const [childId, childName] of children) convertPage(childId, childName, name, null);
  };

  const pages = manifest.Pages.Pages;
  const pageName = (index) => (index === 0 ? base : `${base}/Page ${index + 1}`);
  pages.forEach((id, index) => {
    const navigation = pages.length > 1 ? { previous: pageName((index + pages.length - 1) % pages.length), next: pageName((index + 1) % pages.length) } : null;
    convertPage(id, pageName(index), null, navigation);
  });
  return profiles;
};

const report = [];
const bundles = fs.readdirSync(args.elgato).filter((entry) => entry.endsWith(".sdProfile")).sort();
const profiles = bundles.flatMap((bundle) => convertBundle(path.join(args.elgato, bundle), report));

fs.rmSync(path.join(args.out, "images"), { recursive: true, force: true });
fs.rmSync(path.join(args.out, "profiles"), { recursive: true, force: true });
for (const profile of profiles) {
  for (const [source, destination] of profile.images) {
    const file = path.join(args.out, "images", destination);
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.copyFileSync(source, file);
  }
  for (const target of targets) {
    writeJson(path.join(args.out, "profiles", target, profile.device, `${profile.name}.json`), { keys: profile.keys[target], sliders: [], infobars: profile.infobars });
  }
}

console.log(`wrote ${profiles.length} profiles for ${targets.join(" and ")} to ${path.relative(process.cwd(), args.out) || "."}`);
for (const line of report) console.log(line);
