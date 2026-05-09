# Picker Selection Window

## Purpose

Selecting a memo entry from `MemoPicker`, `MemoSnacks`, or `MemoTelescope` opens the memo file in the centered memo floating window.

## Why This Helps

Previously, picker selection used a normal `:edit`.
That made retrieval feel different from the rest of the plugin and could disrupt the user's current layout.
Opening in the centered memo window keeps browsing lightweight and preserves the memo-focused UI.

## Usage

```vim
:MemoPicker
```

Select an entry.
The memo file opens in the configured floating window and jumps to the selected entry.

The same behavior applies to:

```vim
:MemoSnacks
:MemoTelescope
```
