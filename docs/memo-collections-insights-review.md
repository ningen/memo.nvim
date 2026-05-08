# Collections, Insights, And Review Packs

## Purpose

This batch adds higher-level views over memo entries:

- collections are named saved queries
- insights summarize hotspots, tag usage, task volume, and recommendations
- review packs turn memo evidence into review-ready Markdown

## Why This Helps

Users do not always know what to search for.
Collections and insights provide entry points when the question is vague: "what should I look at?" or "what is accumulating?"
Review packs are useful when the memo becomes evidence for an LLM or human review.

## Lower-Cost Alternatives

- Use `:MemoQuery` directly when a one-off filter is enough.
- Use `:MemoStats` when counts are sufficient.
- Use `:MemoPrompt --kind=review` when you only need LLM instructions, not diagnostics and recommendations.

## Commands

```vim
:MemoCollections
:MemoCollection {name}
:MemoInsights
:MemoRecommendations
:MemoReviewPack [query]
```

Default collections include `bugs`, `ideas`, and `open_tasks`.
Users can add more through `setup({ collections = { ... } })`.
