// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  EnumKnowledgeBaseVisibility,
  type KnowledgeBaseAnswerTranslation,
} from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

export default (): DeepPartial<KnowledgeBaseAnswerTranslation> => {
  return {
    __typename: 'KnowledgeBaseAnswerTranslation',
    id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 999),
    title: 'Knowledge Base Answer Translation Title',
    // `visibility` drives the state icon (KnowledgeBaseAnswerIcon) wherever a translation is
    //   rendered (linked answers, AI suggestions). It is a non-null enum, so pin it to a stable
    //   default — otherwise the auto-mocker leaves it undefined here and the icon throws.
    visibility: EnumKnowledgeBaseVisibility.Published,
    categoryTreeTranslation: [
      {
        __typename: 'KnowledgeBaseCategoryTranslation',
        id: convertToGraphQLId('KnowledgeBase::Category::Translation', 999),
        title: 'Knowledge Base Category Translation Title',
        category: {
          __typename: 'KnowledgeBaseCategory',
          id: convertToGraphQLId('KnowledgeBase::Category', 999),
        },
      },
    ],
  }
}
