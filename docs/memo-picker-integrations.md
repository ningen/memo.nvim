# Picker Integrations

## Purpose

`memo.nvim` supports optional picker integrations for interactive memo browsing.

## Integrations

- `:MemoSnacks` uses `folke/snacks.nvim` picker.
- `:MemoTelescope` uses `nvim-telescope/telescope.nvim`.
- `:MemoPicker` prefers Snacks when available and falls back to Telescope.

## Why This Helps

Telescope is widely used and already supported.
Snacks picker is a modern alternative with a simple custom picker API and fast fuzzy matching.
Supporting both lets users keep their preferred picker without changing the memo storage or parser.

## Lower-Cost Alternative

Users can rely on quickfix commands such as `:MemoSearch`, `:MemoTodo`, and `:MemoToday`.
Those commands avoid optional dependencies, but they do not provide interactive preview.

## Usage

```vim
:MemoPicker
:MemoSnacks
:MemoTelescope
```

For Snacks, install and enable the picker:

```lua
{
  "folke/snacks.nvim",
  opts = {
    picker = { enabled = true },
  },
}
```

The implementation uses the same structured memo entries as the Telescope picker.
