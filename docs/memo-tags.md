# MemoTags

## Purpose

`MemoTags` creates a lightweight tag summary from hashtags inside the active memo file.

## Intent

Tags are a low-friction way to make captured notes easier to group later.
The plugin does not require frontmatter or a database; it simply scans memo text for hashtags.

## Usage

Write tags naturally in memo text:

```md
memo: investigate this branch #bug #parser
```

Then run:

```vim
:MemoTags
```

The command opens a scratch Markdown buffer with sorted tag counts.
