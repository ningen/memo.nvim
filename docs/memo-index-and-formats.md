# Memo Index And Formats

## Purpose

The index layer treats memo files as structured entries instead of plain lines.
This is the foundation for features such as filtered exports, timelines, JSONL output, and multi-file retrieval.

## Why This Helps

Line search is cheap, but it loses the relationship between a note, its source location, tags, date, and code block.
The index keeps those pieces together, which is more useful for LLM prompts and interactive review.

## Lower-Cost Alternative

Users who only need a quick lookup can keep using `:MemoSearch`.
The index exists for workflows where entry-level context matters.

## Supported Shapes

- Markdown entry bundles for human reading and LLM prompts
- JSONL entries for external tools
- Timelines grouped by date
- Tag and project groupings

The parser intentionally follows the format that `memo.nvim` already writes, so existing memo files remain compatible.
