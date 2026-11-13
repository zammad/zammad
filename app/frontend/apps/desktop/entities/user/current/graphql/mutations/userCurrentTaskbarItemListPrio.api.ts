import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useUserCurrentTaskbarItemListPrioMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentTaskbarItemListPrioMutation, Types.UserCurrentTaskbarItemListPrioMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTaskbarItemListPrioMutation, Types.UserCurrentTaskbarItemListPrioMutationVariables>(UserCurrentTaskbarItemListPrioDocument, options);
}
export type UserCurrentTaskbarItemListPrioMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentTaskbarItemListPrioMutation, Types.UserCurrentTaskbarItemListPrioMutationVariables>;