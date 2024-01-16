import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SessionFragmentDoc } from '../../../../../../shared/graphql/fragments/session.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserAddFirstAdminDocument = gql`
    mutation userAddFirstAdmin($input: UserSignupInput!) {
  userAddFirstAdmin(input: $input) {
    session {
      ...session
    }
    errors {
      ...errors
    }
  }
}
    ${SessionFragmentDoc}
${ErrorsFragmentDoc}`;
export function useUserAddFirstAdminMutation(options: VueApolloComposable.UseMutationOptions<Types.UserAddFirstAdminMutation, Types.UserAddFirstAdminMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserAddFirstAdminMutation, Types.UserAddFirstAdminMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserAddFirstAdminMutation, Types.UserAddFirstAdminMutationVariables>(UserAddFirstAdminDocument, options);
}
export type UserAddFirstAdminMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserAddFirstAdminMutation, Types.UserAddFirstAdminMutationVariables>;