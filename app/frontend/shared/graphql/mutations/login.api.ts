import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SessionFragmentDoc } from '../fragments/session.api';
import { ErrorsFragmentDoc } from '../fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useLoginMutation(options: VueApolloComposable.UseMutationOptions<Types.LoginMutation, Types.LoginMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.LoginMutation, Types.LoginMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.LoginMutation, Types.LoginMutationVariables>(LoginDocument, options);
}
export type LoginMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.LoginMutation, Types.LoginMutationVariables>;