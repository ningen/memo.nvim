# Prompts, Source Links, Health, And Archive

## Purpose

This feature batch adds workflows around the indexed memo:

- prompt generation for different LLM tasks
- quickfix navigation to captured source files
- health checks for memo configuration and references
- conservative date-based archiving

## Why This Helps

LLM usage is not a single action. Sometimes the user wants a summary, sometimes a plan, sometimes debugging hypotheses.
Purpose-built prompts reduce repetitive manual framing.

Source links make captured notes operational again: the memo can lead back to code.
Health checks surface missing dependencies and broken references before the user relies on export output.
Archiving keeps the active memo small without deleting old context.

## Lower-Cost Alternatives

- Manually paste `:MemoExport` into an LLM and type instructions each time.
- Use quickfix search instead of source-link quickfix when source navigation is not needed.
- Keep one large memo file if it is still small enough.

## Commands

```vim
:MemoPrompt [--kind=summary|plan|review|debug|changelog] [query] [--tag=name] [--limit=N]
:MemoSources
:MemoBrokenSources
:MemoHealth
:MemoArchiveBefore YYYY-MM-DD
```

Archiving writes old entries to `{memo_path}.archive.md` and removes them from the active memo.
