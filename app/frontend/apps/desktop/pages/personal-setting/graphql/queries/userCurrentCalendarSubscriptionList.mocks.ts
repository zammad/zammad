import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentCalendarSubscriptionList.api.ts'

export function mockUserCurrentCalendarSubscriptionList(defaults: Mocks.MockDefaultsValue<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentCalendarSubscriptionListDocument, defaults)
}

export function waitForUserCurrentCalendarSubscriptionListCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentCalendarSubscriptionListQuery>(Operations.UserCurrentCalendarSubscriptionListDocument)
}
