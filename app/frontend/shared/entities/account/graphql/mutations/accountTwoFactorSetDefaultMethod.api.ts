import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountTwoFactorSetDefaultMethodDocument = gql`
    mutation accountTwoFactorSetDefaultMethod($methodName: String!) {
  accountTwoFactorSetDefaultMethod(methodName: $methodName) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useAccountTwoFactorSetDefaultMethodMutation(options: VueApolloComposable.UseMutationOptions<Types.AccountTwoFactorSetDefaultMethodMutation, Types.AccountTwoFactorSetDefaultMethodMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AccountTwoFactorSetDefaultMethodMutation, Types.AccountTwoFactorSetDefaultMethodMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AccountTwoFactorSetDefaultMethodMutation, Types.AccountTwoFactorSetDefaultMethodMutationVariables>(AccountTwoFactorSetDefaultMethodDocument, options);
}
export type AccountTwoFactorSetDefaultMethodMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AccountTwoFactorSetDefaultMethodMutation, Types.AccountTwoFactorSetDefaultMethodMutationVariables>;