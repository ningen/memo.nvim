# Feature Matrix

## Retrieval

| Feature | Value | Lower-cost alternative |
| --- | --- | --- |
| `MemoSearch` | Literal lookup into the active memo file. | Use `/` after opening `:Memo`. |
| `MemoQuery` | Combine text, tags, dates, projects, paths, and limits. | Use repeated `MemoSearch` calls. |
| `MemoTelescope` | Interactive entry picker with preview. | Use quickfix commands when Telescope is not installed. |
| `MemoIndex` | Overview of files, tags, and recent entries. | Use `MemoStats` for only counts. |
| `MemoTimeline` | Date-grouped work history. | Search date strings manually. |

## LLM Workflows

| Feature | Value | Lower-cost alternative |
| --- | --- | --- |
| `MemoExport` | Full memo context with instructions. | Open the memo file and copy it manually. |
| `MemoExportFiltered` | Smaller prompt payloads for a focused question. | Manually delete unrelated entries before pasting. |
| `MemoExportJsonl` | Machine-readable output for scripts or external tools. | Parse Markdown externally. |
| `MemoPrompt` | Purpose-specific prompt framing. | Type instructions manually each time. |
| `MemoWorktreePrompt` | Combine memo evidence with git status and diff stat. | Manually paste `git status` and `git diff --stat`. |
| `MemoReviewPack` | Review-oriented evidence pack. | Use `MemoPrompt --kind=review` when diagnostics are not needed. |

## Organization

| Feature | Value | Lower-cost alternative |
| --- | --- | --- |
| `MemoTags` | Lightweight grouping through hashtags. | Plain text search. |
| `MemoCollections` / `MemoCollection` | Saved reusable views. | Re-type query syntax. |
| `MemoTodo` / `MemoTaskReport` | Extract follow-up work. | Maintain a separate task tracker. |
| `MemoToday` / `MemoDigest` / `MemoStandup` | Daily recall and reporting. | Search today's date manually. |
| `MemoArchiveBefore` | Keep active memo small while retaining history. | Move old entries manually. |
| `MemoDuplicates` | Find repeated quick captures. | Search repeated text manually. |

## Maintenance

| Feature | Value | Lower-cost alternative |
| --- | --- | --- |
| `MemoHealth` | Check readable files, entries, references, and Telescope. | Debug each component manually. |
| `MemoValidateConfig` | Catch setup shape mistakes. | Inspect setup table manually. |
| `MemoPruneBlank` | Remove low-value whitespace before export. | Format the Markdown file manually. |
| `MemoVersion` | Support metadata for issue reports. | Ask users to report plugin and Neovim versions manually. |

## Capture

| Feature | Value | Lower-cost alternative |
| --- | --- | --- |
| `MemoHere` | Quick context-aware note taking. | Open `:Memo` and type manually. |
| Capture format settings | Fit note labels and code inclusion to workflow. | Edit entries after capture. |
| `MemoTemplates` | Discover repeatable capture shapes. | Keep snippets elsewhere. |
