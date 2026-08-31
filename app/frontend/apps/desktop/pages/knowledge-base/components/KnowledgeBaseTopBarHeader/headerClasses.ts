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

// The create/edit form's column (KnowledgeBaseAnswerCreateContent.vue,
//   KnowledgeBaseAnswerEditContent.vue), shared with them for the same reason as
//   the reading column above: the header carries the title field and the badge
//   row, so both have to measure exactly like the fields below them.
export const FORM_COLUMN_CLASS = 'max-w-270 px-5.5'

// The header rows are nested inside the header's own px-5.5 padding, while the
//   content they must line up with is not. `wide`'s target (the browse view's
//   card grid section) uses that same px-5.5 as its own padding, so a max-width
//   calculated relative to it (below) still lines up. The rows of `reading` and
//   `form` instead break out of the header's own padding via
//   `HEADER_CONTENT_OUTER_CLASSES` and reapply their column class verbatim, so
//   they measure against the same reference frame (the full content column) as
//   the article, respectively the form, itself.
export const HEADER_CONTENT_WIDTH_CLASSES: Record<HeaderContentWidth, string> = {
  wide: 'max-w-[calc(var(--container-7xl)-2.750rem)]',
  reading: READING_COLUMN_CLASS,
  form: FORM_COLUMN_CLASS,
}

export const HEADER_CONTENT_OUTER_CLASSES: Record<HeaderContentWidth, string> = {
  wide: '',
  reading: '-mx-5.5',
  form: '-mx-5.5',
}
