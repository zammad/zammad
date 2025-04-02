import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentCalendarSubscriptionList.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentCalendarSubscriptionList(defaults: Mocks.MockDefaultsValue<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentCalendarSubscriptionListDocument, defaults)
}

export function waitForUserCurrentCalendarSubscriptionListCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentCalendarSubscriptionListQuery>(Operations.UserCurrentCalendarSubscriptionListDocument)
}

export function mockUserCurrentCalendarSubscriptionListError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentCalendarSubscriptionListDocument, message, extensions);
}
