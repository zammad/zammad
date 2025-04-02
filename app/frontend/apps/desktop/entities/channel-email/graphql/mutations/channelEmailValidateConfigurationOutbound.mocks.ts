import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './channelEmailValidateConfigurationOutbound.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChannelEmailValidateConfigurationOutboundMutation(defaults: Mocks.MockDefaultsValue<Types.ChannelEmailValidateConfigurationOutboundMutation, Types.ChannelEmailValidateConfigurationOutboundMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChannelEmailValidateConfigurationOutboundDocument, defaults)
}

export function waitForChannelEmailValidateConfigurationOutboundMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChannelEmailValidateConfigurationOutboundMutation>(Operations.ChannelEmailValidateConfigurationOutboundDocument)
}

export function mockChannelEmailValidateConfigurationOutboundMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChannelEmailValidateConfigurationOutboundDocument, message, extensions);
}
