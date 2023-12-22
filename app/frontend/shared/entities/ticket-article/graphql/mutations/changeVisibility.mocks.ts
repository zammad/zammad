import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './changeVisibility.api.ts'

export function mockTicketArticleChangeVisibilityMutation(defaults: Mocks.MockDefaultsValue<Types.TicketArticleChangeVisibilityMutation, Types.TicketArticleChangeVisibilityMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.TicketArticleChangeVisibilityDocument, defaults)
}

export function waitForTicketArticleChangeVisibilityMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.TicketArticleChangeVisibilityMutation>(Operations.TicketArticleChangeVisibilityDocument)
}
