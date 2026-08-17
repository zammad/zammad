// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { KnowledgeBaseAnswer } from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<KnowledgeBaseAnswer> => {
  return {
    __typename: 'KnowledgeBaseAnswer',
    // Breaks the answer -> navigation -> answer cycle for auto-generated mocks.
    // Individual query fixtures can supply navigation when they exercise it.
    navigation: null,
    category: null,
    archivedBy: null,
    internalBy: null,
    publishedBy: null,
  }
}
