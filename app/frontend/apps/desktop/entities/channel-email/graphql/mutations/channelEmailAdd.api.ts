import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const ChannelEmailAddDocument = gql`
    mutation channelEmailAdd($input: ChannelEmailAddInput!) {
  channelEmailAdd(input: $input) {
    channel {
      options
      group {
        id
      }
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useChannelEmailAddMutation(options: VueApolloComposable.UseMutationOptions<Types.ChannelEmailAddMutation, Types.ChannelEmailAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.ChannelEmailAddMutation, Types.ChannelEmailAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.ChannelEmailAddMutation, Types.ChannelEmailAddMutationVariables>(ChannelEmailAddDocument, options);
}
export type ChannelEmailAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.ChannelEmailAddMutation, Types.ChannelEmailAddMutationVariables>;