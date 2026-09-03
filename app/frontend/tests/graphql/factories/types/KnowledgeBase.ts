// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { type KnowledgeBase } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<KnowledgeBase> => {
  return {
    __typename: 'KnowledgeBase',
    id: convertToGraphQLId('KnowledgeBase', 999),
    // Pinned like `KnowledgeBaseLocale` pins its own back references: a knowledge base is reachable
    //   from deep inside other graphs (a notification's knowledge base answer, a locale), and
    //   generating its translation there walks on until the mocker trips its cap on generated ids
    //   for one type. Specs that render a knowledge base title supply the translation.
    translation: null,
  }
}
