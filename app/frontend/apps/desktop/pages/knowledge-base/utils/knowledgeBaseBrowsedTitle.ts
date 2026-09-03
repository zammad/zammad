// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '#shared/i18n.ts'

import type { CategoryBreadcrumb } from '../types.ts'

interface KnowledgeBaseBrowsedTitleOptions {
  categoryBreadcrumb?: CategoryBreadcrumb
  knowledgeBaseTitle?: Maybe<string>
}

// The title of the node being browsed: the opened category, or the knowledge base
//   itself at the root. Shared so the header and the search placeholder cannot drift
//   apart. The fallback is translated here rather than left as a bare `__()` marker —
//   callers interpolate the result into an already translated frame, where a raw
//   English string would surface untranslated.
export const knowledgeBaseBrowsedTitle = ({
  categoryBreadcrumb,
  knowledgeBaseTitle,
}: KnowledgeBaseBrowsedTitleOptions): string =>
  categoryBreadcrumb?.at(-1)?.translation?.title ??
  knowledgeBaseTitle ??
  i18n.t(__('Knowledge Base'))
