# Expanded Retrieval Commands

## Purpose

These commands expose the structured memo index without requiring Telescope.

## Commands

```vim
:MemoIndex
:MemoTimeline
:MemoExportFiltered [query] [--tag=name] [--date=YYYY-MM-DD] [--limit=N]
:MemoExportJsonl [query] [--tag=name] [--date=YYYY-MM-DD] [--limit=N]
:MemoOpenSource
```

## Why This Helps

- `MemoIndex` gives a dashboard-like overview of files, tags, and recent entries.
- `MemoTimeline` shows how work unfolded over time.
- `MemoExportFiltered` creates smaller LLM payloads than exporting the full memo.
- `MemoExportJsonl` gives scripts and external tools a stable machine-readable shape.
- `MemoOpenSource` shortens the path from a captured note back to the source location.

## Lower-Cost Alternatives

- Use `:MemoSearch` when a literal line search is enough.
- Use `:MemoExport` when the whole memo is small enough to paste directly.
- Use Telescope when interactive exploration matters more than a static Markdown buffer.
