import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './channelEmailAdd.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChannelEmailAddMutation(defaults: Mocks.MockDefaultsValue<Types.ChannelEmailAddMutation, Types.ChannelEmailAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChannelEmailAddDocument, defaults)
}

export function waitForChannelEmailAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChannelEmailAddMutation>(Operations.ChannelEmailAddDocument)
}

export function mockChannelEmailAddMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChannelEmailAddDocument, message, extensions);
}
