import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './channelEmailSetNotificationConfiguration.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockChannelEmailSetNotificationConfigurationMutation(defaults: Mocks.MockDefaultsValue<Types.ChannelEmailSetNotificationConfigurationMutation, Types.ChannelEmailSetNotificationConfigurationMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChannelEmailSetNotificationConfigurationDocument, defaults)
}

export function waitForChannelEmailSetNotificationConfigurationMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChannelEmailSetNotificationConfigurationMutation>(Operations.ChannelEmailSetNotificationConfigurationDocument)
}

export function mockChannelEmailSetNotificationConfigurationMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.ChannelEmailSetNotificationConfigurationDocument, message, extensions);
}
