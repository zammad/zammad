import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserCurrentTaskbarItemAttributesFragmentDoc } from '../fragments/userCurrentTaskbarItemAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTaskbarItemAddDocument = gql`
    mutation userCurrentTaskbarItemAdd($input: UserTaskbarItemInput!) {
  userCurrentTaskbarItemAdd(input: $input) {
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
export function useUserCurrentTaskbarItemAddMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentTaskbarItemAddMutation, Types.UserCurrentTaskbarItemAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentTaskbarItemAddMutation, Types.UserCurrentTaskbarItemAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTaskbarItemAddMutation, Types.UserCurrentTaskbarItemAddMutationVariables>(UserCurrentTaskbarItemAddDocument, options);
}
export type UserCurrentTaskbarItemAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentTaskbarItemAddMutation, Types.UserCurrentTaskbarItemAddMutationVariables>;