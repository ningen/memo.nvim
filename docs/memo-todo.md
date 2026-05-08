# MemoTodo

## Purpose

`MemoTodo` extracts task-like lines from the active memo file and places them in quickfix.

## Intent

Memos often contain small follow-ups. Requiring a separate task system would make capture heavier.
This command keeps memo capture casual while still making TODOs retrievable.

## Usage

```vim
:MemoTodo
```

The command matches:

- `TODO`
- `FIXME`
- Markdown checkboxes such as `- [ ]` and `- [x]`

Results are opened in quickfix, so normal quickfix navigation applies:

```vim
:cnext
:cprev
```
