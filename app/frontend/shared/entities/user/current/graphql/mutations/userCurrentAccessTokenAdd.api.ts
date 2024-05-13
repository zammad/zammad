import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TokenAttributesFragmentDoc } from '../fragments/tokenAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentAccessTokenAddDocument = gql`
    mutation userCurrentAccessTokenAdd($input: UserAccessTokenInput!) {
  userCurrentAccessTokenAdd(input: $input) {
    token {
      ...tokenAttributes
    }
    tokenValue
    errors {
      ...errors
    }
  }
}
    ${TokenAttributesFragmentDoc}
${ErrorsFragmentDoc}`;
export function useUserCurrentAccessTokenAddMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentAccessTokenAddMutation, Types.UserCurrentAccessTokenAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentAccessTokenAddMutation, Types.UserCurrentAccessTokenAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentAccessTokenAddMutation, Types.UserCurrentAccessTokenAddMutationVariables>(UserCurrentAccessTokenAddDocument, options);
}
export type UserCurrentAccessTokenAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentAccessTokenAddMutation, Types.UserCurrentAccessTokenAddMutationVariables>;