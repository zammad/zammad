import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserCurrentTaskbarItemAttributesFragmentDoc } from '../fragments/userCurrentTaskbarItemAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTaskbarItemTouchLastContactDocument = gql`
    mutation userCurrentTaskbarItemTouchLastContact($id: ID!) {
  userCurrentTaskbarItemTouchLastContact(id: $id) {
    taskbarItem {
      ...userCurrentTaskbarItemAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${UserCurrentTaskbarItemAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useUserCurrentTaskbarItemTouchLastContactMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentTaskbarItemTouchLastContactMutation, Types.UserCurrentTaskbarItemTouchLastContactMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentTaskbarItemTouchLastContactMutation, Types.UserCurrentTaskbarItemTouchLastContactMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTaskbarItemTouchLastContactMutation, Types.UserCurrentTaskbarItemTouchLastContactMutationVariables>(UserCurrentTaskbarItemTouchLastContactDocument, options);
}
export type UserCurrentTaskbarItemTouchLastContactMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentTaskbarItemTouchLastContactMutation, Types.UserCurrentTaskbarItemTouchLastContactMutationVariables>;