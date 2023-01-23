import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { UserAttributesFragmentDoc } from '../../../../../../shared/graphql/fragments/userAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserUpdateDocument = gql`
    mutation userUpdate($id: ID!, $input: UserInput!) {
  userUpdate(id: $id, input: $input) {
    user {
      ...userAttributes
    }
    errors {
      ...errors
    }
  }
}
    ${UserAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useUserUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.UserUpdateMutation, Types.UserUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserUpdateMutation, Types.UserUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserUpdateMutation, Types.UserUpdateMutationVariables>(UserUpdateDocument, options);
}
export type UserUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserUpdateMutation, Types.UserUpdateMutationVariables>;