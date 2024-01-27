import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './channelEmailValidateConfigurationOutbound.api.ts'

export function mockChannelEmailValidateConfigurationOutboundMutation(defaults: Mocks.MockDefaultsValue<Types.ChannelEmailValidateConfigurationOutboundMutation, Types.ChannelEmailValidateConfigurationOutboundMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChannelEmailValidateConfigurationOutboundDocument, defaults)
}

export function waitForChannelEmailValidateConfigurationOutboundMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChannelEmailValidateConfigurationOutboundMutation>(Operations.ChannelEmailValidateConfigurationOutboundDocument)
}
