import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ChannelEmailGuessConfigurationDocument = gql`
    mutation channelEmailGuessConfiguration($emailAddress: String!, $password: String!) {
  channelEmailGuessConfiguration(emailAddress: $emailAddress, password: $password) {
    result {
      inboundConfiguration {
        adapter
        host
        port
        ssl
        user
        sslVerify
        folder
      }
      outboundConfiguration {
        adapter
        host
        port
        user
        sslVerify
      }
      mailboxStats {
        contentMessages
      }
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useChannelEmailGuessConfigurationMutation(options: VueApolloComposable.useMutation.Options<Types.ChannelEmailGuessConfigurationMutation, Types.ChannelEmailGuessConfigurationMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.ChannelEmailGuessConfigurationMutation, Types.ChannelEmailGuessConfigurationMutationVariables>(ChannelEmailGuessConfigurationDocument, options);
}
export type ChannelEmailGuessConfigurationMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.ChannelEmailGuessConfigurationMutation, Types.ChannelEmailGuessConfigurationMutationVariables>;