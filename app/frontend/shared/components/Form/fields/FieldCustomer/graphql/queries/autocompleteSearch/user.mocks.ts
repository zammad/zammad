import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './user.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockAutocompleteSearchUserQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchUserDocument, defaults)
}

export function waitForAutocompleteSearchUserQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchUserQuery>(Operations.AutocompleteSearchUserDocument)
}

export function mockAutocompleteSearchUserQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.AutocompleteSearchUserDocument, message, extensions);
}
