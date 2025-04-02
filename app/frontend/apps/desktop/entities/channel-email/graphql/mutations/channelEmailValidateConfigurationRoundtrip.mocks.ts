import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './channelEmailValidateConfigurationRoundtrip.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChannelEmailValidateConfigurationRoundtripMutation(defaults: Mocks.MockDefaultsValue<Types.ChannelEmailValidateConfigurationRoundtripMutation, Types.ChannelEmailValidateConfigurationRoundtripMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChannelEmailValidateConfigurationRoundtripDocument, defaults)
}

export function waitForChannelEmailValidateConfigurationRoundtripMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChannelEmailValidateConfigurationRoundtripMutation>(Operations.ChannelEmailValidateConfigurationRoundtripDocument)
}

export function mockChannelEmailValidateConfigurationRoundtripMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChannelEmailValidateConfigurationRoundtripDocument, message, extensions);
}
