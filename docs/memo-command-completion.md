# Command Completion

## Purpose

Command completion makes the expanded command surface easier to remember.

## Why This Helps

After adding query syntax, prompt kinds, collections, and templates, the main usability risk is recall burden.
Completion keeps those features discoverable without adding UI dependencies.

## Lower-Cost Alternative

Users can keep the docs open or define their own keymaps.
Built-in completion is cheaper during day-to-day use because it works inside `:` commands.

## Supported Commands

```vim
:MemoPrompt --kind=<Tab>
:MemoQuery tag:<Tab>
:MemoCollection <Tab>
```

Completion intentionally suggests syntax and names; it does not scan every possible tag yet.
