import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useMentionSubscribeMutation(options: VueApolloComposable.useMutation.Options<Types.MentionSubscribeMutation, Types.MentionSubscribeMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.MentionSubscribeMutation, Types.MentionSubscribeMutationVariables>(MentionSubscribeDocument, options);
}
export type MentionSubscribeMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.MentionSubscribeMutation, Types.MentionSubscribeMutationVariables>;