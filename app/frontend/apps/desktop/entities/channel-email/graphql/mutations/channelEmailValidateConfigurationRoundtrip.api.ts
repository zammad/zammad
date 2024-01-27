import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const ChannelEmailValidateConfigurationRoundtripDocument = gql`
    mutation channelEmailValidateConfigurationRoundtrip($inboundConfiguration: ChannelEmailInboundConfigurationInput!, $outboundConfiguration: ChannelEmailOutboundConfigurationInput!, $emailAddress: String!) {
  channelEmailValidateConfigurationRoundtrip(
    inboundConfiguration: $inboundConfiguration
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
export function useChannelEmailValidateConfigurationRoundtripMutation(options: VueApolloComposable.UseMutationOptions<Types.ChannelEmailValidateConfigurationRoundtripMutation, Types.ChannelEmailValidateConfigurationRoundtripMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.ChannelEmailValidateConfigurationRoundtripMutation, Types.ChannelEmailValidateConfigurationRoundtripMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.ChannelEmailValidateConfigurationRoundtripMutation, Types.ChannelEmailValidateConfigurationRoundtripMutationVariables>(ChannelEmailValidateConfigurationRoundtripDocument, options);
}
export type ChannelEmailValidateConfigurationRoundtripMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.ChannelEmailValidateConfigurationRoundtripMutation, Types.ChannelEmailValidateConfigurationRoundtripMutationVariables>;