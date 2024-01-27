import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './channelEmailValidateConfigurationRoundtrip.api.ts'

export function mockChannelEmailValidateConfigurationRoundtripMutation(defaults: Mocks.MockDefaultsValue<Types.ChannelEmailValidateConfigurationRoundtripMutation, Types.ChannelEmailValidateConfigurationRoundtripMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChannelEmailValidateConfigurationRoundtripDocument, defaults)
}

export function waitForChannelEmailValidateConfigurationRoundtripMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChannelEmailValidateConfigurationRoundtripMutation>(Operations.ChannelEmailValidateConfigurationRoundtripDocument)
}
