# MemoToday

## Purpose

`MemoToday` lists today's memo entries in quickfix.

## Intent

The memo file is append-only and date-stamped. A daily view helps users recover the current working thread without introducing a separate journal format.

## Usage

```vim
:MemoToday
```

The command searches headers that begin with today's date in `YYYY-MM-DD` format and opens the matching entries in quickfix.

Useful follow-up commands:

```vim
:cnext
:cprev
:copen
```
