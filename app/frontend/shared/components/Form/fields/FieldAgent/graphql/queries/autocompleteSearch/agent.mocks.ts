import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './agent.api.ts'

export function mockAutocompleteSearchAgentQuery(defaults: Mocks.MockDefaultsValue<Types.AutocompleteSearchAgentQuery, Types.AutocompleteSearchAgentQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.AutocompleteSearchAgentDocument, defaults)
}

export function waitForAutocompleteSearchAgentQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.AutocompleteSearchAgentQuery>(Operations.AutocompleteSearchAgentDocument)
}
