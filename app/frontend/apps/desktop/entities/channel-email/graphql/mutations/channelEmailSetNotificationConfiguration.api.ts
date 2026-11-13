import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ChannelEmailSetNotificationConfigurationDocument = gql`
    mutation channelEmailSetNotificationConfiguration($outboundConfiguration: ChannelEmailOutboundConfigurationInput!) {
  channelEmailSetNotificationConfiguration(
    outboundConfiguration: $outboundConfiguration
  ) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useChannelEmailSetNotificationConfigurationMutation(options: VueApolloComposable.useMutation.Options<Types.ChannelEmailSetNotificationConfigurationMutation, Types.ChannelEmailSetNotificationConfigurationMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.ChannelEmailSetNotificationConfigurationMutation, Types.ChannelEmailSetNotificationConfigurationMutationVariables>(ChannelEmailSetNotificationConfigurationDocument, options);
}
export type ChannelEmailSetNotificationConfigurationMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.ChannelEmailSetNotificationConfigurationMutation, Types.ChannelEmailSetNotificationConfigurationMutationVariables>;