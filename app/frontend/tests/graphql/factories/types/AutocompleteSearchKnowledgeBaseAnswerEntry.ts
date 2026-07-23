// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  type AutocompleteSearchKnowledgeBaseAnswerEntry,
  EnumKnowledgeBaseVisibility,
} from '#shared/graphql/types.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

// `visibility` drives the state icon in the answer picker (see KnowledgeBaseAnswerIcon). It is a
//   non-null enum, so the auto-mocker would otherwise pick a *random* value on every run, making
//   any icon assertion flaky. Pin it to a stable default; individual tests still override it.
export default (): DeepPartial<AutocompleteSearchKnowledgeBaseAnswerEntry> => {
  return {
    __typename: 'AutocompleteSearchKnowledgeBaseAnswerEntry',
    visibility: EnumKnowledgeBaseVisibility.Published,
  }
}
