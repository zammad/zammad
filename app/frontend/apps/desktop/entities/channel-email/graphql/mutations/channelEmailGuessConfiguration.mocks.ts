import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './channelEmailGuessConfiguration.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChannelEmailGuessConfigurationMutation(defaults: Mocks.MockDefaultsValue<Types.ChannelEmailGuessConfigurationMutation, Types.ChannelEmailGuessConfigurationMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChannelEmailGuessConfigurationDocument, defaults)
}

export function waitForChannelEmailGuessConfigurationMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChannelEmailGuessConfigurationMutation>(Operations.ChannelEmailGuessConfigurationDocument)
}

export function mockChannelEmailGuessConfigurationMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChannelEmailGuessConfigurationDocument, message, extensions);
}
