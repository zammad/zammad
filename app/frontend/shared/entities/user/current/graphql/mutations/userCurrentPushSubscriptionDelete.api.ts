import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentPushSubscriptionDeleteDocument = gql`
    mutation userCurrentPushSubscriptionDelete($endpoint: String!) {
  userCurrentPushSubscriptionDelete(endpoint: $endpoint) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentPushSubscriptionDeleteMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentPushSubscriptionDeleteMutation, Types.UserCurrentPushSubscriptionDeleteMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentPushSubscriptionDeleteMutation, Types.UserCurrentPushSubscriptionDeleteMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentPushSubscriptionDeleteMutation, Types.UserCurrentPushSubscriptionDeleteMutationVariables>(UserCurrentPushSubscriptionDeleteDocument, options);
}
export type UserCurrentPushSubscriptionDeleteMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentPushSubscriptionDeleteMutation, Types.UserCurrentPushSubscriptionDeleteMutationVariables>;