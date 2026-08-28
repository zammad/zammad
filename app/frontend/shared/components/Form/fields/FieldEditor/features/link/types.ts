// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

// We can't export it from a link extension since it causes a dependency circle.
export const EXTENSION_NAME = 'link'

// The two flavours of the link form. Both write the same `link` mark; the knowledge base answer one
//   picks its target from the answer autocomplete instead of taking a URL, and marks the mark up
//   for the server (see `answerLink.ts`).
export type LinkFormVariant = 'url' | 'knowledgeBaseAnswer'
