import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountLocaleDocument = gql`
    mutation accountLocale($locale: String!) {
  accountLocale(locale: $locale) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useAccountLocaleMutation(options: VueApolloComposable.UseMutationOptions<Types.AccountLocaleMutation, Types.AccountLocaleMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AccountLocaleMutation, Types.AccountLocaleMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AccountLocaleMutation, Types.AccountLocaleMutationVariables>(AccountLocaleDocument, options);
}
export type AccountLocaleMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AccountLocaleMutation, Types.AccountLocaleMutationVariables>;