# Worktree Context And Dedupe

## Purpose

This batch connects memo context with the current git worktree and adds duplicate candidate detection.

## Why This Helps

For LLM work, memo context is more useful when paired with the code changes currently in flight.
`MemoWorktreePrompt` gives the model both sides: what the user captured and what git says changed.

Duplicate detection helps when quick capture is used heavily.
It does not delete anything automatically; it only surfaces likely repeated notes.

## Lower-Cost Alternatives

- Run `git status` and `git diff --stat` manually, then paste them near `:MemoExport`.
- Use normal text search to find repeated lines if duplicate cleanup is rare.

## Commands

```vim
:MemoWorktreePrompt
:MemoDuplicates
```

`MemoWorktreePrompt` opens a Markdown scratch buffer.
`MemoDuplicates` opens a Markdown report of likely duplicate memo entries.
