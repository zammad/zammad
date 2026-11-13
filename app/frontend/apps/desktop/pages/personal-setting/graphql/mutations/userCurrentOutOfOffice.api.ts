import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentOutOfOfficeDocument = gql`
    mutation userCurrentOutOfOffice($input: OutOfOfficeInput!) {
  userCurrentOutOfOffice(input: $input) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentOutOfOfficeMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentOutOfOfficeMutation, Types.UserCurrentOutOfOfficeMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentOutOfOfficeMutation, Types.UserCurrentOutOfOfficeMutationVariables>(UserCurrentOutOfOfficeDocument, options);
}
export type UserCurrentOutOfOfficeMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentOutOfOfficeMutation, Types.UserCurrentOutOfOfficeMutationVariables>;