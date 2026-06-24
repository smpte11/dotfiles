# Pure-inspired yazi flavor

**Date:** 2026-06-24
**Status:** Approved design

## Goal

Create a yazi flavor, `pure.yazi`, whose visual style is inspired by the Pure
zsh prompt (sindresorhus/pure): near-monochrome, lots of negative space, muted
grey chrome, a single magenta accent, and a blue path. It must drop into the
existing chezmoi dotfiles.

## Guiding principle

Pure never hardcodes hex. It styles prompt elements with ANSI color *names and
indices* (`magenta`, `blue`, `242`, `yellow`), so it inherits whatever palette
the terminal provides. We do the same: the flavor's UI is built entirely from
ANSI named colors plus `reset`, so it automatically follows the user's live
ghostty palette (currently `eldritch`, set via `.chezmoidata.toml` →
`active_theme`). This is both faithful to Pure and keeps the flavor in sync with
the rest of the themed apps with zero templating on the UI side.

yazi `theme.toml` accepts only: `reset`, hex (`#RRGGBB`), and 16 ANSI named
colors (`black`, `white`, `red`, `lightred`, `green`, `lightgreen`, `yellow`,
`lightyellow`, `blue`, `lightblue`, `magenta`, `lightmagenta`, `cyan`,
`lightcyan`, `gray`, `darkgray`). It does **not** accept 256-palette indices, so
Pure's grey `242` is approximated with `darkgray` (which maps to the terminal's
bright-black slot).

The one exception is the preview-pane syntax theme: tmTheme files require
hardcoded hex and cannot reference ANSI slots, so `tmtheme.xml` is a chezmoi
template that pulls hex from `active_theme`.

## File layout (chezmoi source)

```
dot_config/yazi/
  theme.toml                          # selects the flavor
  flavors/pure.yazi/
    flavor.toml                       # static; ANSI-named colors only
    tmtheme.xml.tmpl                  # renders to tmtheme.xml; hex from active_theme
    README.md
    LICENSE                           # MIT, user's name
    LICENSE-tmtheme                   # tmTheme attribution
```

`theme.toml` content:

```toml
[flavor]
dark  = "pure"
light = "pure"
```

`flavor.toml` is **not** a `.tmpl` — it contains only ANSI names + `reset`, so it
follows the terminal palette without rendering. Only `tmtheme.xml.tmpl` is
templated.

## Color mapping (Pure → ANSI)

| Pure element        | Pure color | yazi usage                                              | ANSI value     |
|---------------------|------------|---------------------------------------------------------|----------------|
| `❯` prompt success  | magenta    | primary accent: normal mode, selection/markers, active tab, find position | `magenta`      |
| path                | blue       | `cwd`, directory entries                                | `blue`         |
| git branch / 242    | 242 grey   | borders, inactive tabs, secondary status, symlinks      | `darkgray`     |
| execution_time      | yellow     | progress, executable entries                            | `yellow`       |
| prompt error        | red        | errors, orphan symlinks, cut markers                    | `red`          |
| git dirty           | 218 pink   | copy/find accents                                       | `lightmagenta` |
| listing body        | (terminal) | regular file names, panel text                          | `reset`        |

## File listing — "monochrome + minimal hints"

- Regular files: `reset` (terminal foreground).
- Cursor / hovered line: `{ reversed = true }` — monochrome highlight, no accent
  bar, matching Pure's restraint.
- Directories: `blue` (echoes Pure's path).
- Executables: `magenta`.
- Symlinks: `darkgray`; orphan/broken symlinks: `red`.
- No per-filetype rainbow (images, archives, media, etc. inherit `reset`). The
  `[filetype]` rules list is reduced to the conditional `is = ...` entries above
  (dir, exec, link, orphan) and nothing mime-based.

## Chrome (Pure-minimal)

- **Borders:** `darkgray`, using the thinnest available border symbols; minimal
  separators between panes.
- **Mode indicator:** `magenta` for normal; `lightmagenta` and `yellow` for
  select / unset (kept low-key, reading like Pure's single accent).
- **Tabs:** active uses `magenta`; inactive uses `darkgray`; simple separators.
- **Status bar:** muted overall — `cwd` `blue`, permission/secondary text
  `darkgray`, progress `yellow`, progress error `red`.
- **Overlays** (`which`, `confirm`, `input`, `pick`, `cmp`, `tasks`, `help`,
  `notify`, `spot`): `darkgray` borders, `magenta` for active/hovered/selected,
  `reset` body text, `yellow`/`red` for warn/error notification titles.

Every section in yazi's `theme.toml` schema is given an explicit, restrained
value so the flavor is complete and nothing falls back to yazi defaults that
would reintroduce saturated colors.

## Preview tmTheme (`tmtheme.xml.tmpl`)

A restrained, low-saturation tmTheme templated from `active_theme`. Mapping:

- background → `active_theme.background`
- default foreground → `active_theme.foreground`
- comments → `active_theme.base.b02` / `b03` (muted)
- keyword / storage → `palette.magenta`
- function / entity → `palette.blue`
- type / class → `palette.cyan`
- string → `palette.green`
- number / constant → `palette.yellow`
- variable / parameter → `foreground`

It references the eldritch and minischeme structures already present in
`.chezmoidata.toml` (`background`, `foreground`, `palette.*`, `base.b00`–`b07`),
so switching `active_theme` keeps the preview colors consistent with the UI
(which follows the same palette via ghostty).

## Licensing

- `LICENSE`: MIT, attributed to the user (Felix Brousseau-Tremblay), following
  the flavor-template convention.
- `LICENSE-tmtheme`: attribution for the tmTheme, noting it is an original
  low-saturation theme authored for this flavor.

## Out of scope

- `preview.png`: cannot be generated headlessly. The README will include a note
  on how to capture one, rather than ship a placeholder image.
- No changes to other apps' themes; ghostty already drives the ANSI palette this
  flavor depends on.

## Success criteria

1. `chezmoi apply` produces a valid `~/.config/yazi/flavors/pure.yazi/` with a
   rendered `tmtheme.xml` and a static `flavor.toml`.
2. `theme.toml` selects `pure`; `yazi` launches with no theme-parse errors.
3. UI colors track the terminal palette: switching `active_theme` (and
   re-applying ghostty) visibly recolors yazi's chrome via ANSI slots.
4. The listing is near-monochrome with only dir/exec/symlink/orphan hints; no
   filetype rainbow.
5. Preview syntax highlighting renders with the low-saturation palette drawn
   from `active_theme`.
