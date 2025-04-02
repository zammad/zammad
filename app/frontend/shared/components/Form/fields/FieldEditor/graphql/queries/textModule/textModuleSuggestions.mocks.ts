import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './textModuleSuggestions.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockTextModuleSuggestionsQuery(defaults: Mocks.MockDefaultsValue<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TextModuleSuggestionsDocument, defaults)
}

export function waitForTextModuleSuggestionsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TextModuleSuggestionsQuery>(Operations.TextModuleSuggestionsDocument)
}

export function mockTextModuleSuggestionsQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.TextModuleSuggestionsDocument, message, extensions);
}
