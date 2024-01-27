import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './channelEmailAdd.api.ts'

export function mockChannelEmailAddMutation(defaults: Mocks.MockDefaultsValue<Types.ChannelEmailAddMutation, Types.ChannelEmailAddMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChannelEmailAddDocument, defaults)
}

export function waitForChannelEmailAddMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChannelEmailAddMutation>(Operations.ChannelEmailAddDocument)
}
