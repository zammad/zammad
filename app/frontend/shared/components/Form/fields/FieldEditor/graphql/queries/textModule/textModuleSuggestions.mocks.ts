import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './textModuleSuggestions.api.ts'

export function mockTextModuleSuggestionsQuery(defaults: Mocks.MockDefaultsValue<Types.TextModuleSuggestionsQuery, Types.TextModuleSuggestionsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.TextModuleSuggestionsDocument, defaults)
}

export function waitForTextModuleSuggestionsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TextModuleSuggestionsQuery>(Operations.TextModuleSuggestionsDocument)
}
