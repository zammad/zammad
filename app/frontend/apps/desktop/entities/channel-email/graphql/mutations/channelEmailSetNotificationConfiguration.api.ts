import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useChannelEmailSetNotificationConfigurationMutation(options: VueApolloComposable.UseMutationOptions<Types.ChannelEmailSetNotificationConfigurationMutation, Types.ChannelEmailSetNotificationConfigurationMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.ChannelEmailSetNotificationConfigurationMutation, Types.ChannelEmailSetNotificationConfigurationMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.ChannelEmailSetNotificationConfigurationMutation, Types.ChannelEmailSetNotificationConfigurationMutationVariables>(ChannelEmailSetNotificationConfigurationDocument, options);
}
export type ChannelEmailSetNotificationConfigurationMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.ChannelEmailSetNotificationConfigurationMutation, Types.ChannelEmailSetNotificationConfigurationMutationVariables>;