# MemoSearch

## Purpose

`MemoSearch` makes accumulated memo entries searchable without leaving Neovim.
It sends matching lines from the active memo file to the quickfix list, so users can move through results with normal quickfix commands.

## Intent

The plugin already captures code context into Markdown. As the memo grows, the next useful step is retrieval.
This feature keeps retrieval simple: literal, case-insensitive line search over the memo file selected by the current configuration.

## Usage

```vim
:MemoSearch keyword
```

Matches are shown in quickfix.

```vim
:cnext
:cprev
:cclose
```

When `per_project = true`, the command searches the current project's `.memo.md` if the current buffer is inside a git repository.
Otherwise it searches the configured global memo path.
