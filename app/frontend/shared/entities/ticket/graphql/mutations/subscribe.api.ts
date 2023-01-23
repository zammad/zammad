import * as Types from '../../../../graphql/types';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const MentionSubscribeDocument = gql`
    mutation mentionSubscribe($ticketId: ID!) {
  mentionSubscribe(objectId: $ticketId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useMentionSubscribeMutation(options: VueApolloComposable.UseMutationOptions<Types.MentionSubscribeMutation, Types.MentionSubscribeMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.MentionSubscribeMutation, Types.MentionSubscribeMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.MentionSubscribeMutation, Types.MentionSubscribeMutationVariables>(MentionSubscribeDocument, options);
}
export type MentionSubscribeMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.MentionSubscribeMutation, Types.MentionSubscribeMutationVariables>;