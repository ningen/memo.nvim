# MemoPruneBlank

## Purpose

`MemoPruneBlank` removes excessive blank lines from the active memo file.

## Intent

Append-only capture can gradually produce noisy Markdown.
This command performs a conservative cleanup: it only reduces runs of three or more blank lines to two blank lines.
Memo text, code blocks, headings, and task lines are left untouched.

## Usage

```vim
:MemoPruneBlank
```

The command writes the active memo file in place and reports how many blank lines were removed.

Use it before `:MemoExport` when preparing a cleaner LLM context payload.
