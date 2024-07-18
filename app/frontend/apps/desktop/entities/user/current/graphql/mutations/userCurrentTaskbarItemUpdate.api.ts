import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserCurrentTaskbarItemAttributesFragmentDoc } from '../fragments/userCurrentTaskbarItemAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTaskbarItemUpdateDocument = gql`
    mutation userCurrentTaskbarItemUpdate($id: ID!, $input: UserTaskbarItemInput!) {
  userCurrentTaskbarItemUpdate(id: $id, input: $input) {
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
export function useUserCurrentTaskbarItemUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentTaskbarItemUpdateMutation, Types.UserCurrentTaskbarItemUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentTaskbarItemUpdateMutation, Types.UserCurrentTaskbarItemUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTaskbarItemUpdateMutation, Types.UserCurrentTaskbarItemUpdateMutationVariables>(UserCurrentTaskbarItemUpdateDocument, options);
}
export type UserCurrentTaskbarItemUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentTaskbarItemUpdateMutation, Types.UserCurrentTaskbarItemUpdateMutationVariables>;