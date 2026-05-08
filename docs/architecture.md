# Architecture

## Purpose

This document explains the module layout after the retrieval and LLM workflow expansion.

## Module Map

- `memo.init`: public setup entrypoint and current config accessor.
- `memo.config`: default configuration and config merging.
- `memo.commands`: user command registration.
- `memo.window`: floating memo and quick capture windows.
- `memo.buffer`: memo buffer cache and append helpers.
- `memo.util`: small formatting and line utilities.
- `memo.parser`: converts memo Markdown into structured entries.
- `memo.index`: loads entries across active, global, project, and extra memo files.
- `memo.format`: Markdown, JSONL, timeline, and index formatting.
- `memo.actions`: command-facing orchestration.
- `memo.scratch`: scratch buffer creation.
- `memo.telescope`: optional Telescope pickers.
- `memo.query`: lightweight query syntax.
- `memo.tasks`: TODO and checkbox parsing.
- `memo.journal`: digest and standup generation.
- `memo.prompt`: LLM prompt variants.
- `memo.links`: source reference resolution.
- `memo.archive`: date-based archive planning and writing.
- `memo.health`: memo environment checks.
- `memo.collections`: saved query collections.
- `memo.insights`: aggregate signals and recommendations.
- `memo.review`: review pack generation.
- `memo.git_context`: git status and diff-stat context.
- `memo.dedupe`: duplicate candidate detection.
- `memo.completion`: command completion helpers.
- `memo.validate`: config shape validation.
- `memo.version`: version metadata.

## Design Intent

The plugin still has a small core: capture text, append to Markdown, and open floating windows.
The larger feature set is layered on top of structured parsing so retrieval features do not each invent their own file scanning model.

## Extension Points

- Add new retrieval behavior by consuming `memo.index.load`.
- Add new LLM output by formatting entries through `memo.format` or `memo.prompt`.
- Add new command UX through `memo.commands`.
- Add optional UI integrations beside `memo.telescope` without changing core capture.
