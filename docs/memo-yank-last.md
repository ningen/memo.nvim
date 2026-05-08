# MemoYankLast

## Purpose

`MemoYankLast` copies the most recent memo entry to the unnamed register and the system clipboard.
It is meant for quickly moving the latest captured context into a chat, issue, review comment, or LLM prompt.

## Intent

`MemoExport` is useful when the whole memo matters.
Often, only the most recent capture is relevant. This command keeps that path short and avoids opening the memo file just to copy a small block.

## Usage

```vim
:MemoYankLast
```

The command reads the active memo file, finds the last `---` separator, and yanks from that entry to the end of the file.

Registers:

- `"` receives the entry for normal Vim paste.
- `+` receives the entry for system clipboard paste.
