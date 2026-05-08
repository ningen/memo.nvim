# MemoExport

## Purpose

`MemoExport` prepares accumulated memo content for use with an LLM.
It opens a scratch Markdown buffer that contains project metadata, the memo file path, and the memo body.

## Intent

Raw memo files are useful for humans, but an LLM benefits from a small amount of framing.
The export format makes it clear that the content is working context and asks the reader to preserve source paths and line numbers.

## Usage

```vim
:MemoExport
```

The command opens a `memo-export.md` scratch buffer.
Users can review, edit, yank, or paste that buffer into an LLM prompt.

The command uses the same memo path resolution as `:Memo`:

- `per_project = true` uses `.memo.md` under the current git root.
- Otherwise it uses the configured global memo path.
