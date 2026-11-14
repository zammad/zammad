import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useMentionUnsubscribeMutation(options: VueApolloComposable.useMutation.Options<Types.MentionUnsubscribeMutation, Types.MentionUnsubscribeMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.MentionUnsubscribeMutation, Types.MentionUnsubscribeMutationVariables>(MentionUnsubscribeDocument, options);
}
export type MentionUnsubscribeMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.MentionUnsubscribeMutation, Types.MentionUnsubscribeMutationVariables>;