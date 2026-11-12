import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TwoFactorMethodInitiateAuthenticationDocument = gql`
    mutation twoFactorMethodInitiateAuthentication($login: String!, $password: String!, $twoFactorMethod: EnumTwoFactorAuthenticationMethod!) {
  twoFactorMethodInitiateAuthentication(
    login: $login
    password: $password
    twoFactorMethod: $twoFactorMethod
  ) {
    initiationData
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTwoFactorMethodInitiateAuthenticationMutation(options: VueApolloComposable.useMutation.Options<Types.TwoFactorMethodInitiateAuthenticationMutation, Types.TwoFactorMethodInitiateAuthenticationMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TwoFactorMethodInitiateAuthenticationMutation, Types.TwoFactorMethodInitiateAuthenticationMutationVariables>(TwoFactorMethodInitiateAuthenticationDocument, options);
}
export type TwoFactorMethodInitiateAuthenticationMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TwoFactorMethodInitiateAuthenticationMutation, Types.TwoFactorMethodInitiateAuthenticationMutationVariables>;