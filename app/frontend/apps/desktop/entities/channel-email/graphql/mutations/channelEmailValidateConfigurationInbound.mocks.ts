import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './channelEmailValidateConfigurationInbound.api.ts'

export function mockChannelEmailValidateConfigurationInboundMutation(defaults: Mocks.MockDefaultsValue<Types.ChannelEmailValidateConfigurationInboundMutation, Types.ChannelEmailValidateConfigurationInboundMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChannelEmailValidateConfigurationInboundDocument, defaults)
}

export function waitForChannelEmailValidateConfigurationInboundMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChannelEmailValidateConfigurationInboundMutation>(Operations.ChannelEmailValidateConfigurationInboundDocument)
}
