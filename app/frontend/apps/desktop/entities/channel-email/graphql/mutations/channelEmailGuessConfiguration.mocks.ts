import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './channelEmailGuessConfiguration.api.ts'

export function mockChannelEmailGuessConfigurationMutation(defaults: Mocks.MockDefaultsValue<Types.ChannelEmailGuessConfigurationMutation, Types.ChannelEmailGuessConfigurationMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChannelEmailGuessConfigurationDocument, defaults)
}

export function waitForChannelEmailGuessConfigurationMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChannelEmailGuessConfigurationMutation>(Operations.ChannelEmailGuessConfigurationDocument)
}
