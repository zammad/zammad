import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useUserCurrentTwoFactorSetDefaultMethodMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentTwoFactorSetDefaultMethodMutation, Types.UserCurrentTwoFactorSetDefaultMethodMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTwoFactorSetDefaultMethodMutation, Types.UserCurrentTwoFactorSetDefaultMethodMutationVariables>(UserCurrentTwoFactorSetDefaultMethodDocument, options);
}
export type UserCurrentTwoFactorSetDefaultMethodMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentTwoFactorSetDefaultMethodMutation, Types.UserCurrentTwoFactorSetDefaultMethodMutationVariables>;