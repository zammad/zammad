import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTwoFactorRemoveMethodDocument = gql`
    mutation userCurrentTwoFactorRemoveMethod($methodName: String!) {
  userCurrentTwoFactorRemoveMethod(methodName: $methodName) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentTwoFactorRemoveMethodMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentTwoFactorRemoveMethodMutation, Types.UserCurrentTwoFactorRemoveMethodMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentTwoFactorRemoveMethodMutation, Types.UserCurrentTwoFactorRemoveMethodMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTwoFactorRemoveMethodMutation, Types.UserCurrentTwoFactorRemoveMethodMutationVariables>(UserCurrentTwoFactorRemoveMethodDocument, options);
}
export type UserCurrentTwoFactorRemoveMethodMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentTwoFactorRemoveMethodMutation, Types.UserCurrentTwoFactorRemoveMethodMutationVariables>;