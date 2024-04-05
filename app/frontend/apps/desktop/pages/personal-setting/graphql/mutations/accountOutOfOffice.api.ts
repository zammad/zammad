import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountOutOfOfficeDocument = gql`
    mutation accountOutOfOffice($settings: OutOfOfficeInput!) {
  accountOutOfOffice(settings: $settings) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useAccountOutOfOfficeMutation(options: VueApolloComposable.UseMutationOptions<Types.AccountOutOfOfficeMutation, Types.AccountOutOfOfficeMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AccountOutOfOfficeMutation, Types.AccountOutOfOfficeMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AccountOutOfOfficeMutation, Types.AccountOutOfOfficeMutationVariables>(AccountOutOfOfficeDocument, options);
}
export type AccountOutOfOfficeMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AccountOutOfOfficeMutation, Types.AccountOutOfOfficeMutationVariables>;