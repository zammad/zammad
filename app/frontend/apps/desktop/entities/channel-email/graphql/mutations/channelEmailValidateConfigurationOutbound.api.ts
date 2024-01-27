import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const ChannelEmailValidateConfigurationOutboundDocument = gql`
    mutation channelEmailValidateConfigurationOutbound($outboundConfiguration: ChannelEmailOutboundConfigurationInput!, $emailAddress: String!) {
  channelEmailValidateConfigurationOutbound(
    outboundConfiguration: $outboundConfiguration
    emailAddress: $emailAddress
  ) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useChannelEmailValidateConfigurationOutboundMutation(options: VueApolloComposable.UseMutationOptions<Types.ChannelEmailValidateConfigurationOutboundMutation, Types.ChannelEmailValidateConfigurationOutboundMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.ChannelEmailValidateConfigurationOutboundMutation, Types.ChannelEmailValidateConfigurationOutboundMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.ChannelEmailValidateConfigurationOutboundMutation, Types.ChannelEmailValidateConfigurationOutboundMutationVariables>(ChannelEmailValidateConfigurationOutboundDocument, options);
}
export type ChannelEmailValidateConfigurationOutboundMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.ChannelEmailValidateConfigurationOutboundMutation, Types.ChannelEmailValidateConfigurationOutboundMutationVariables>;