# MemoStats

## Purpose

`MemoStats` opens a small Markdown summary for the active memo file.

## Intent

As the memo grows, users need lightweight observability:
how many entries exist, whether task markers are accumulating, and whether tags are being used.

## Usage

```vim
:MemoStats
```

The command reports:

- memo path
- total lines
- date-stamped entries
- task-like lines
- unique tags

The output is a scratch Markdown buffer, so it can also be copied into status notes or LLM prompts.
