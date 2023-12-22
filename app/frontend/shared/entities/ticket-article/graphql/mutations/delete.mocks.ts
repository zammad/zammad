import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './delete.api.ts'

export function mockTicketArticleDeleteMutation(defaults: Mocks.MockDefaultsValue<Types.TicketArticleDeleteMutation, Types.TicketArticleDeleteMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketArticleDeleteDocument, defaults)
}

export function waitForTicketArticleDeleteMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketArticleDeleteMutation>(Operations.TicketArticleDeleteDocument)
}
