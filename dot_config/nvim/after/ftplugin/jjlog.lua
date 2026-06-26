-- jj.nvim log buffer. Navigation is single-key j/k; stop mini.keymap combos
-- (jj/kk/hh/ll and the notify-many-keys traps) from hijacking fast j/k mashing.
-- Same trick mini.files uses (see 'plugin/30_mini.lua').
vim.b.minikeymap_disable = true
