# Config Validation

## Purpose

`MemoValidateConfig` checks the expanded setup table for common shape mistakes.

## Why This Helps

As the plugin gains templates, collections, capture settings, and window styling, silent misconfiguration becomes more likely.
Validation gives users a cheap first check before debugging behavior.

## Lower-Cost Alternative

Users can inspect their setup manually.
The command is worthwhile because configuration errors often look like feature bugs.

## Usage

```vim
:MemoValidateConfig
```

The command opens a Markdown report.
