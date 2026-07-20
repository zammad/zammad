// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { type KnowledgeBaseLocale } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

// Breaks the KnowledgeBase <-> KnowledgeBaseLocale reference cycle
// (knowledgeBase -> kbLocales/currentLocale -> knowledgeBase -> ...), which
// otherwise lets the auto-mocker recurse until it hits the generated-id loop
// guard, producing flaky "Too many generated ids" failures.
export default (): DeepPartial<KnowledgeBaseLocale> => {
  return {
    __typename: 'KnowledgeBaseLocale',
    id: convertToGraphQLId('KnowledgeBase::Locale', 999),
    knowledgeBase: {
      __typename: 'KnowledgeBase',
      id: convertToGraphQLId('KnowledgeBase', 999),
      kbLocales: [],
      currentLocale: null,
    },
  }
}
