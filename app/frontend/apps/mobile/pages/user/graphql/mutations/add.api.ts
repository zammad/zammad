import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { UserAttributesFragmentDoc } from '../../../../../../shared/graphql/fragments/userAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserAddDocument = gql`
    mutation userAdd($input: UserInput!) {
  userAdd(input: $input) {
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
export function useUserAddMutation(options: VueApolloComposable.UseMutationOptions<Types.UserAddMutation, Types.UserAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserAddMutation, Types.UserAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserAddMutation, Types.UserAddMutationVariables>(UserAddDocument, options);
}
export type UserAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserAddMutation, Types.UserAddMutationVariables>;