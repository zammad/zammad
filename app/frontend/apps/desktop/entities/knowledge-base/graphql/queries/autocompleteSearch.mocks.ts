import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './autocompleteSearch.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockAutocompleteSearchKnowledgeBaseAnswerQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchKnowledgeBaseAnswerQuery, Types.AutocompleteSearchKnowledgeBaseAnswerQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchKnowledgeBaseAnswerDocument, defaults)
}

export function waitForAutocompleteSearchKnowledgeBaseAnswerQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchKnowledgeBaseAnswerQuery>(Operations.AutocompleteSearchKnowledgeBaseAnswerDocument)
}

export function mockAutocompleteSearchKnowledgeBaseAnswerQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.AutocompleteSearchKnowledgeBaseAnswerDocument, message, extensions);
}
