// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { type KnowledgeBaseCategory } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<KnowledgeBaseCategory> => {
  return {
    __typename: 'KnowledgeBaseCategory',
    id: convertToGraphQLId('KnowledgeBase::Category', 999),
    parent: null,
    knowledgeBase: {
      __typename: 'KnowledgeBase',
      id: convertToGraphQLId('KnowledgeBase', 999),
    },
    translations: [],
    // Breaks the translation cycle (category -> translation -> category -> ...).
    // Each turn also builds `kbLocale`, so the mocker's id budget for `Locale`
    // runs out first and the loop guard blames `Locale`, not the category.
    translation: null,
    // Breaks the self-referential breadcrumb cycle (breadcrumb -> category ->
    // breadcrumb -> ...), which otherwise lets the auto-mocker recurse until it
    // overflows the stack.
    breadcrumb: [],
  }
}
