import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserSignupDocument = gql`
    mutation userSignup($input: UserSignupInput!) {
  userSignup(input: $input) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserSignupMutation(options: VueApolloComposable.UseMutationOptions<Types.UserSignupMutation, Types.UserSignupMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserSignupMutation, Types.UserSignupMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserSignupMutation, Types.UserSignupMutationVariables>(UserSignupDocument, options);
}
export type UserSignupMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserSignupMutation, Types.UserSignupMutationVariables>;