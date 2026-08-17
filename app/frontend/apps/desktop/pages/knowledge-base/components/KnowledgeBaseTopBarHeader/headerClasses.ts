// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { HeaderContentWidth } from './types'

// The answer article's reading column (KnowledgeBaseAnswer.vue), so the header
//   content that has to line up with it — via `HEADER_CONTENT_WIDTH_CLASSES.reading`
//   below — can reuse the exact same class string instead of a second formula
//   that has to be kept in sync by hand. Two differently sized paddings can
//   only ever line up by coincidence at one specific width, so both reach the
//   same 48rem reading measure (a ticket article's width, ArticleList.vue's
//   max-w-4xl minus px-16) through the header's own px-5.5 padding, not the
//   article's original, larger px-16 — that would've grown the article's text
//   measure to keep the same outer max-width.
export const READING_COLUMN_CLASS = 'max-w-[calc(var(--container-3xl)+2.750rem)] px-5.5'

// The header rows are nested inside the header's own px-5.5 padding, while the
//   content they must line up with is not. `wide`'s target (the browse view's
//   card grid section) uses that same px-5.5 as its own padding, so a max-width
//   calculated relative to it (below) still lines up. `reading`'s rows instead
//   break out of the header's own padding via `HEADER_CONTENT_OUTER_CLASSES`
//   and reapply `READING_COLUMN_CLASS` verbatim, so they measure against the
//   same reference frame (the full content column) as the article itself.
export const HEADER_CONTENT_WIDTH_CLASSES: Record<HeaderContentWidth, string> = {
  wide: 'max-w-[calc(var(--container-7xl)-2.750rem)]',
  reading: READING_COLUMN_CLASS,
}

export const HEADER_CONTENT_OUTER_CLASSES: Record<HeaderContentWidth, string> = {
  wide: '',
  reading: '-mx-5.5',
}

// The header's first row is pinned to the stepper/toolbar row's fixed height,
//   with the remaining row(s) sized to content. Shared so TopBarHeaderFull.vue
//   and TopBarHeaderFullSkeleton.vue can't drift apart and produce mismatched
//   heights (TopBarHeaderShell.vue measures the rendered height off of this).
export const HEADER_ROWS_WITH_DETAILS_CLASS = 'grid-rows-[1.5rem_auto_auto]'
export const HEADER_ROWS_CLASS = 'grid-rows-[1.5rem_auto]'
