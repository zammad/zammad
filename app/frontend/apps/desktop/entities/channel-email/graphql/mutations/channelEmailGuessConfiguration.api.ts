import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
        password
        sslVerify
        folder
      }
      outboundConfiguration {
        adapter
        host
        port
        user
        password
        sslVerify
      }
      mailboxStats {
        contentMessages
        archivePossible
        archivePossibleIsFallback
        archiveWeekRange
      }
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useChannelEmailGuessConfigurationMutation(options: VueApolloComposable.UseMutationOptions<Types.ChannelEmailGuessConfigurationMutation, Types.ChannelEmailGuessConfigurationMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.ChannelEmailGuessConfigurationMutation, Types.ChannelEmailGuessConfigurationMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.ChannelEmailGuessConfigurationMutation, Types.ChannelEmailGuessConfigurationMutationVariables>(ChannelEmailGuessConfigurationDocument, options);
}
export type ChannelEmailGuessConfigurationMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.ChannelEmailGuessConfigurationMutation, Types.ChannelEmailGuessConfigurationMutationVariables>;