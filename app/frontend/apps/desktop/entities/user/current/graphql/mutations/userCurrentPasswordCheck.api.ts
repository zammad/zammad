import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentPasswordCheckDocument = gql`
    mutation userCurrentPasswordCheck($password: String!) {
  userCurrentPasswordCheck(password: $password) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentPasswordCheckMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentPasswordCheckMutation, Types.UserCurrentPasswordCheckMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentPasswordCheckMutation, Types.UserCurrentPasswordCheckMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentPasswordCheckMutation, Types.UserCurrentPasswordCheckMutationVariables>(UserCurrentPasswordCheckDocument, options);
}
export type UserCurrentPasswordCheckMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentPasswordCheckMutation, Types.UserCurrentPasswordCheckMutationVariables>;