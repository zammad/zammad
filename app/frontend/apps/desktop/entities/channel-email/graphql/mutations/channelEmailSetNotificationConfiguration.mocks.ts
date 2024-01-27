import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './channelEmailSetNotificationConfiguration.api.ts'

export function mockChannelEmailSetNotificationConfigurationMutation(defaults: Mocks.MockDefaultsValue<Types.ChannelEmailSetNotificationConfigurationMutation, Types.ChannelEmailSetNotificationConfigurationMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.ChannelEmailSetNotificationConfigurationDocument, defaults)
}

export function waitForChannelEmailSetNotificationConfigurationMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.ChannelEmailSetNotificationConfigurationMutation>(Operations.ChannelEmailSetNotificationConfigurationDocument)
}
