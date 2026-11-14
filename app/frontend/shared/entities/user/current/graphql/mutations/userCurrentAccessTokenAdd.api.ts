import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TokenAttributesFragmentDoc } from '../fragments/tokenAttributes.api';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useUserCurrentAccessTokenAddMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentAccessTokenAddMutation, Types.UserCurrentAccessTokenAddMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentAccessTokenAddMutation, Types.UserCurrentAccessTokenAddMutationVariables>(UserCurrentAccessTokenAddDocument, options);
}
export type UserCurrentAccessTokenAddMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentAccessTokenAddMutation, Types.UserCurrentAccessTokenAddMutationVariables>;