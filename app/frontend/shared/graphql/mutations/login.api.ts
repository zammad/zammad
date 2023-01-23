import * as Types from '../types';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const LoginDocument = gql`
    mutation login($input: LoginInput!) {
  login(input: $input) {
    sessionId
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useLoginMutation(options: VueApolloComposable.UseMutationOptions<Types.LoginMutation, Types.LoginMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.LoginMutation, Types.LoginMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.LoginMutation, Types.LoginMutationVariables>(LoginDocument, options);
}
export type LoginMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.LoginMutation, Types.LoginMutationVariables>;