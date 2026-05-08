# MemoProject and MemoGlobal

## Purpose

`MemoProject` and `MemoGlobal` open a specific memo scope regardless of the default `per_project` setting.

## Intent

Search and export features are most useful when users understand which memo file they are working with.
These commands make scope switching explicit without requiring a setup change.

## Usage

```vim
:MemoProject
:MemoGlobal
```

`MemoProject` opens `.memo.md` under the current git root.
If there is no git root, it falls back to the configured global memo path.

`MemoGlobal` opens the configured global memo path.

These commands are intentionally separate from `:Memo`:

- `:Memo` follows `per_project`.
- `:MemoProject` forces project scope.
- `:MemoGlobal` forces global scope.
