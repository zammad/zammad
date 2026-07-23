// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { AutocompleteSearchKnowledgeBaseAnswerQuery } from '#shared/graphql/types.ts'
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

type AutocompleteSearchKnowledgeBaseAnswerEntry =
  AutocompleteSearchKnowledgeBaseAnswerQuery['autocompleteSearchKnowledgeBaseAnswer'][number]

export const testOptions: AutocompleteSearchKnowledgeBaseAnswerEntry[] = [
  {
    __typename: 'AutocompleteSearchKnowledgeBaseAnswerEntry',
    value: convertToGraphQLId('KnowledgeBase::Answer::Translation', 1),
    label: 'Reset your password',
    heading: 'Account',
    visibility: EnumKnowledgeBaseVisibility.Published,
  },
  {
    __typename: 'AutocompleteSearchKnowledgeBaseAnswerEntry',
    value: convertToGraphQLId('KnowledgeBase::Answer::Translation', 2),
    label: 'Set up two-factor authentication',
    heading: 'Security',
    visibility: EnumKnowledgeBaseVisibility.Draft,
  },
]
