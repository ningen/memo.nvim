# Telescope Integration

## Purpose

The Telescope integration turns memo retrieval into an interactive picker.
It is most useful when a memo file has grown past the point where quickfix search is comfortable.

## Why This Helps

Quickfix is fast and built in, but it is line-oriented.
Memo entries are richer than lines: they have dates, projects, source locations, notes, tags, and code blocks.
Telescope lets users search across that entry-shaped text while previewing the full memo entry before jumping.

## Lower-Cost Alternative

For users who do not use Telescope, `:MemoSearch`, `:MemoTodo`, `:MemoToday`, and `:MemoTags` remain available.
Those commands cover the same retrieval needs with less dependency cost, but they are not as fluid for exploratory browsing.

## Usage

```vim
:MemoTelescope
```

Or through Telescope's extension API:

```lua
require("telescope").load_extension("memo")
require("telescope").extensions.memo.entries()
require("telescope").extensions.memo.search()
require("telescope").extensions.memo.tags()
```

Default selection opens the memo file at the selected entry.
