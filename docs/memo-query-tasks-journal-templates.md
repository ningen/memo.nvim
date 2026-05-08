# Query, Tasks, Journal, And Templates

## Purpose

This batch expands memo retrieval beyond one-off search:

- query expressions combine text, tag, date, project, and path filters
- task parsing turns memo TODOs and checkboxes into task reports
- journal digests summarize work by date
- templates give quick captures a repeatable shape

## Why This Helps

These features increase the range of value without duplicating the same search command.
They support different user goals: finding, reporting, following up, and capturing higher-quality notes.

## Lower-Cost Alternatives

- Use `:MemoSearch` for one literal keyword.
- Use plain Markdown checkboxes without task reports if the memo is small.
- Type templates manually if only one person uses the plugin rarely.

## Query Syntax

```text
tag:bug notag:done date:2026-05-09 before:2026-06-01 after:2026-05-01 project:memo.nvim path:lua limit:20 crash
```

## Commands

```vim
:MemoQuery {query}
:MemoTaskReport
:MemoDigest
:MemoStandup
:MemoTemplates
```
