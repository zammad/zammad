import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentPushSubscriptionAddDocument = gql`
    mutation userCurrentPushSubscriptionAdd($input: UserPushSubscriptionInput!) {
  userCurrentPushSubscriptionAdd(input: $input) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentPushSubscriptionAddMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentPushSubscriptionAddMutation, Types.UserCurrentPushSubscriptionAddMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentPushSubscriptionAddMutation, Types.UserCurrentPushSubscriptionAddMutationVariables>(UserCurrentPushSubscriptionAddDocument, options);
}
export type UserCurrentPushSubscriptionAddMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentPushSubscriptionAddMutation, Types.UserCurrentPushSubscriptionAddMutationVariables>;