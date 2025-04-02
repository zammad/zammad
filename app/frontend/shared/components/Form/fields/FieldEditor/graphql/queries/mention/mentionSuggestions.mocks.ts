import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './mentionSuggestions.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockMentionSuggestionsQuery(defaults: Mocks.MockDefaultsValue<Types.MentionSuggestionsQuery, Types.MentionSuggestionsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.MentionSuggestionsDocument, defaults)
}

export function waitForMentionSuggestionsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.MentionSuggestionsQuery>(Operations.MentionSuggestionsDocument)
}

export function mockMentionSuggestionsQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.MentionSuggestionsDocument, message, extensions);
}
