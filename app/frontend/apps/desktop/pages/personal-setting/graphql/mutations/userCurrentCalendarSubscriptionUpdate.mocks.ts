import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './userCurrentCalendarSubscriptionUpdate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockUserCurrentCalendarSubscriptionUpdate(defaults: Mocks.MockDefaultsValue<Types.UserCurrentCalendarSubscriptionUpdateMutation, Types.UserCurrentCalendarSubscriptionUpdateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.UserCurrentCalendarSubscriptionUpdateDocument, defaults)
}

export function waitForUserCurrentCalendarSubscriptionUpdateCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.UserCurrentCalendarSubscriptionUpdateMutation>(Operations.UserCurrentCalendarSubscriptionUpdateDocument)
}

export function mockUserCurrentCalendarSubscriptionUpdateError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.UserCurrentCalendarSubscriptionUpdateDocument, message, extensions);
}
