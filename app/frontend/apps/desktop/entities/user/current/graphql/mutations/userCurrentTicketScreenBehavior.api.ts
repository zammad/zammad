import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTicketScreenBehaviorDocument = gql`
    mutation userCurrentTicketScreenBehavior($behavior: EnumTicketScreenBehavior!) {
  userCurrentTicketScreenBehavior(behavior: $behavior) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentTicketScreenBehaviorMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentTicketScreenBehaviorMutation, Types.UserCurrentTicketScreenBehaviorMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentTicketScreenBehaviorMutation, Types.UserCurrentTicketScreenBehaviorMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTicketScreenBehaviorMutation, Types.UserCurrentTicketScreenBehaviorMutationVariables>(UserCurrentTicketScreenBehaviorDocument, options);
}
export type UserCurrentTicketScreenBehaviorMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentTicketScreenBehaviorMutation, Types.UserCurrentTicketScreenBehaviorMutationVariables>;