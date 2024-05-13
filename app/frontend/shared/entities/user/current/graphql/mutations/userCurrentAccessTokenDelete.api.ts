import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentAccessTokenDeleteDocument = gql`
    mutation userCurrentAccessTokenDelete($tokenId: ID!) {
  userCurrentAccessTokenDelete(tokenId: $tokenId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentAccessTokenDeleteMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentAccessTokenDeleteMutation, Types.UserCurrentAccessTokenDeleteMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentAccessTokenDeleteMutation, Types.UserCurrentAccessTokenDeleteMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentAccessTokenDeleteMutation, Types.UserCurrentAccessTokenDeleteMutationVariables>(UserCurrentAccessTokenDeleteDocument, options);
}
export type UserCurrentAccessTokenDeleteMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentAccessTokenDeleteMutation, Types.UserCurrentAccessTokenDeleteMutationVariables>;