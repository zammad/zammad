import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const ChannelEmailValidateConfigurationInboundDocument = gql`
    mutation channelEmailValidateConfigurationInbound($inboundConfiguration: ChannelEmailInboundConfigurationInput!) {
  channelEmailValidateConfigurationInbound(
    inboundConfiguration: $inboundConfiguration
  ) {
    success
    mailboxStats {
      contentMessages
      archivePossible
      archivePossibleIsFallback
      archiveWeekRange
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useChannelEmailValidateConfigurationInboundMutation(options: VueApolloComposable.UseMutationOptions<Types.ChannelEmailValidateConfigurationInboundMutation, Types.ChannelEmailValidateConfigurationInboundMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.ChannelEmailValidateConfigurationInboundMutation, Types.ChannelEmailValidateConfigurationInboundMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.ChannelEmailValidateConfigurationInboundMutation, Types.ChannelEmailValidateConfigurationInboundMutationVariables>(ChannelEmailValidateConfigurationInboundDocument, options);
}
export type ChannelEmailValidateConfigurationInboundMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.ChannelEmailValidateConfigurationInboundMutation, Types.ChannelEmailValidateConfigurationInboundMutationVariables>;