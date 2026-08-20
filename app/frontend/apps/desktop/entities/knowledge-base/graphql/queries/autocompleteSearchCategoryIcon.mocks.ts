import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './autocompleteSearchCategoryIcon.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockAutocompleteSearchKnowledgeBaseCategoryIconQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery, Types.AutocompleteSearchKnowledgeBaseCategoryIconQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchKnowledgeBaseCategoryIconDocument, defaults)
}

export function waitForAutocompleteSearchKnowledgeBaseCategoryIconQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchKnowledgeBaseCategoryIconQuery>(Operations.AutocompleteSearchKnowledgeBaseCategoryIconDocument)
}

export function mockAutocompleteSearchKnowledgeBaseCategoryIconQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.AutocompleteSearchKnowledgeBaseCategoryIconDocument, message, extensions);
}
