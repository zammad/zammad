import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountPasswordCheckDocument = gql`
    mutation accountPasswordCheck($password: String!) {
  accountPasswordCheck(password: $password) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useAccountPasswordCheckMutation(options: VueApolloComposable.UseMutationOptions<Types.AccountPasswordCheckMutation, Types.AccountPasswordCheckMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AccountPasswordCheckMutation, Types.AccountPasswordCheckMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AccountPasswordCheckMutation, Types.AccountPasswordCheckMutationVariables>(AccountPasswordCheckDocument, options);
}
export type AccountPasswordCheckMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AccountPasswordCheckMutation, Types.AccountPasswordCheckMutationVariables>;