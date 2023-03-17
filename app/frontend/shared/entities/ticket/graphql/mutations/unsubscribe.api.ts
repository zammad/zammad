import * as Types from '../../../../graphql/types';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const MentionUnsubscribeDocument = gql`
    mutation mentionUnsubscribe($ticketId: ID!) {
  mentionUnsubscribe(objectId: $ticketId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useMentionUnsubscribeMutation(options: VueApolloComposable.UseMutationOptions<Types.MentionUnsubscribeMutation, Types.MentionUnsubscribeMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.MentionUnsubscribeMutation, Types.MentionUnsubscribeMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.MentionUnsubscribeMutation, Types.MentionUnsubscribeMutationVariables>(MentionUnsubscribeDocument, options);
}
export type MentionUnsubscribeMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.MentionUnsubscribeMutation, Types.MentionUnsubscribeMutationVariables>;