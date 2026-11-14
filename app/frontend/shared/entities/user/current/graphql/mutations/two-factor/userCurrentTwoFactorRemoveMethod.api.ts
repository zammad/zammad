import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentTwoFactorRemoveMethodDocument = gql`
    mutation userCurrentTwoFactorRemoveMethod($methodName: String!, $token: String!) {
  userCurrentTwoFactorRemoveMethod(methodName: $methodName, token: $token) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentTwoFactorRemoveMethodMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentTwoFactorRemoveMethodMutation, Types.UserCurrentTwoFactorRemoveMethodMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentTwoFactorRemoveMethodMutation, Types.UserCurrentTwoFactorRemoveMethodMutationVariables>(UserCurrentTwoFactorRemoveMethodDocument, options);
}
export type UserCurrentTwoFactorRemoveMethodMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentTwoFactorRemoveMethodMutation, Types.UserCurrentTwoFactorRemoveMethodMutationVariables>;