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
    // Pinned, which also stops the auto-mocker from recursing through `answer` back into another
    //   translation. The cost is that several translations in one document share this id unless a
    //   fixture gives them their own - and then the cache holds one of them for all, whichever
    //   arrived last. A spec rendering more than one answer has to say which is which.
    id: convertToGraphQLId('KnowledgeBase::Answer::Translation', 999),
    title: 'Knowledge Base Answer Translation Title',
    // Breaks the translation -> navigation -> answer -> translation cycle for auto-generated mocks.
    //   Individual query fixtures supply navigation when they exercise it.
    navigation: null,
    // `visibility` drives the state icon (KnowledgeBaseAnswerIcon) wherever a translation is
    //   rendered (linked answers, AI suggestions). It is a non-null enum, so pin it to a stable
    //   default — otherwise the auto-mocker leaves it undefined here and the icon throws.
    visibility: EnumKnowledgeBaseVisibility.Published,
    // The locale the knowledge base specs browse ('/knowledge-base/locale/en-us/...'): a view
    //   compares it against the locale it was routed to, and an auto-generated code would put
    //   every one of them into its missing-translation state (see `isTranslationMissing`).
    kbLocale: {
      __typename: 'KnowledgeBaseLocale',
      id: convertToGraphQLId('KnowledgeBase::Locale', 999),
      systemLocale: {
        __typename: 'Locale',
        id: convertToGraphQLId('Locale', 999),
        locale: 'en-us',
      },
    },
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
