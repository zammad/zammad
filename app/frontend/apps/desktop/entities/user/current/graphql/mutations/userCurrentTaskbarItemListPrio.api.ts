import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTaskbarItemListPrioDocument = gql`
    mutation userCurrentTaskbarItemListPrio($list: [UserTaskbarItemListPrioInput!]!) {
  userCurrentTaskbarItemListPrio(list: $list) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentTaskbarItemListPrioMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentTaskbarItemListPrioMutation, Types.UserCurrentTaskbarItemListPrioMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentTaskbarItemListPrioMutation, Types.UserCurrentTaskbarItemListPrioMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTaskbarItemListPrioMutation, Types.UserCurrentTaskbarItemListPrioMutationVariables>(UserCurrentTaskbarItemListPrioDocument, options);
}
export type UserCurrentTaskbarItemListPrioMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentTaskbarItemListPrioMutation, Types.UserCurrentTaskbarItemListPrioMutationVariables>;