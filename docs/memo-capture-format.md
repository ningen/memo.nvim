# Memo Capture Format

## Purpose

`capture` settings customize how `MemoHere` writes quick memo entries.

## Intent

Different workflows use different labels.
Some users want `memo:`, others prefer `note:`, `reason:`, or a label tuned for LLM prompts.
Some captures should include source code, while others should record only the location and note.

## Usage

```lua
require("memo").setup({
  capture = {
    note_label = "note",
    include_code = true,
  },
})
```

Options:

- `note_label`: prefix used before the typed quick memo text.
- `include_code`: when `false`, `MemoHere` records the location and note without embedding the current line or selected range.

Example output:

```md
---
## 2026-05-09 12:00 | memo.nvim | lua/memo/window.lua:48

note: revisit this branch
```
