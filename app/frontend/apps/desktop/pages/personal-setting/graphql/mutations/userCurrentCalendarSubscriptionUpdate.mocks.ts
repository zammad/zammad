import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentCalendarSubscriptionUpdate.api.ts'

export function mockUserCurrentCalendarSubscriptionUpdate(defaults: Mocks.MockDefaultsValue<Types.UserCurrentCalendarSubscriptionUpdateMutation, Types.UserCurrentCalendarSubscriptionUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentCalendarSubscriptionUpdateDocument, defaults)
}

export function waitForUserCurrentCalendarSubscriptionUpdateCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentCalendarSubscriptionUpdateMutation>(Operations.UserCurrentCalendarSubscriptionUpdateDocument)
}
