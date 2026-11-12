import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SessionFragmentDoc } from '../fragments/session.api';
import { ErrorsFragmentDoc } from '../fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const LoginDocument = gql`
    mutation login($input: LoginInput!) {
  login(input: $input) {
    session {
      ...session
    }
    errors {
      ...errors
    }
    twoFactorRequired {
      availableTwoFactorAuthenticationMethods
      defaultTwoFactorAuthenticationMethod
      recoveryCodesAvailable
    }
  }
}
    ${SessionFragmentDoc}
${ErrorsFragmentDoc}`;
export function useLoginMutation(options: VueApolloComposable.useMutation.Options<Types.LoginMutation, Types.LoginMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.LoginMutation, Types.LoginMutationVariables>(LoginDocument, options);
}
export type LoginMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.LoginMutation, Types.LoginMutationVariables>;