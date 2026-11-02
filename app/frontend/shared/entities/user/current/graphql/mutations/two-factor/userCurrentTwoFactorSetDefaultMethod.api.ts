import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '#shared/server/apollo/vueApollo.ts';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTwoFactorSetDefaultMethodDocument = gql`
    mutation userCurrentTwoFactorSetDefaultMethod($methodName: String!) {
  userCurrentTwoFactorSetDefaultMethod(methodName: $methodName) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentTwoFactorSetDefaultMethodMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentTwoFactorSetDefaultMethodMutation, Types.UserCurrentTwoFactorSetDefaultMethodMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentTwoFactorSetDefaultMethodMutation, Types.UserCurrentTwoFactorSetDefaultMethodMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTwoFactorSetDefaultMethodMutation, Types.UserCurrentTwoFactorSetDefaultMethodMutationVariables>(UserCurrentTwoFactorSetDefaultMethodDocument, options);
}
export type UserCurrentTwoFactorSetDefaultMethodMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentTwoFactorSetDefaultMethodMutation, Types.UserCurrentTwoFactorSetDefaultMethodMutationVariables>;