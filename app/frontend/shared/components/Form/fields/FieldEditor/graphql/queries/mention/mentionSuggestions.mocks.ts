import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './mentionSuggestions.api.ts'

export function mockMentionSuggestionsQuery(defaults: Mocks.MockDefaultsValue<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.MentionSuggestionsDocument, defaults)
}

export function waitForMentionSuggestionsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.MentionSuggestionsQuery>(Operations.MentionSuggestionsDocument)
}
