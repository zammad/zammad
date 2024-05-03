import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useUserCurrentOutOfOfficeMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentOutOfOfficeMutation, Types.UserCurrentOutOfOfficeMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentOutOfOfficeMutation, Types.UserCurrentOutOfOfficeMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentOutOfOfficeMutation, Types.UserCurrentOutOfOfficeMutationVariables>(UserCurrentOutOfOfficeDocument, options);
}
export type UserCurrentOutOfOfficeMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentOutOfOfficeMutation, Types.UserCurrentOutOfOfficeMutationVariables>;