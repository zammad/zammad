import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ChannelEmailValidateConfigurationInboundDocument = gql`
    mutation channelEmailValidateConfigurationInbound($inboundConfiguration: ChannelEmailInboundConfigurationInput!) {
  channelEmailValidateConfigurationInbound(
    inboundConfiguration: $inboundConfiguration
  ) {
    success
    mailboxStats {
      contentMessages
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useChannelEmailValidateConfigurationInboundMutation(options: VueApolloComposable.useMutation.Options<Types.ChannelEmailValidateConfigurationInboundMutation, Types.ChannelEmailValidateConfigurationInboundMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.ChannelEmailValidateConfigurationInboundMutation, Types.ChannelEmailValidateConfigurationInboundMutationVariables>(ChannelEmailValidateConfigurationInboundDocument, options);
}
export type ChannelEmailValidateConfigurationInboundMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.ChannelEmailValidateConfigurationInboundMutation, Types.ChannelEmailValidateConfigurationInboundMutationVariables>;