import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './create.api.ts'

export function mockTicketCreateMutation(defaults: Mocks.MockDefaultsValue<Types.TicketCreateMutation, Types.TicketCreateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketCreateDocument, defaults)
}

export function waitForTicketCreateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketCreateMutation>(Operations.TicketCreateDocument)
}
