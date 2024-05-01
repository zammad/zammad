import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountTwoFactorRemoveMethodDocument = gql`
    mutation accountTwoFactorRemoveMethod($methodName: String!) {
  accountTwoFactorRemoveMethod(methodName: $methodName) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useAccountTwoFactorRemoveMethodMutation(options: VueApolloComposable.UseMutationOptions<Types.AccountTwoFactorRemoveMethodMutation, Types.AccountTwoFactorRemoveMethodMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AccountTwoFactorRemoveMethodMutation, Types.AccountTwoFactorRemoveMethodMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AccountTwoFactorRemoveMethodMutation, Types.AccountTwoFactorRemoveMethodMutationVariables>(AccountTwoFactorRemoveMethodDocument, options);
}
export type AccountTwoFactorRemoveMethodMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AccountTwoFactorRemoveMethodMutation, Types.AccountTwoFactorRemoveMethodMutationVariables>;