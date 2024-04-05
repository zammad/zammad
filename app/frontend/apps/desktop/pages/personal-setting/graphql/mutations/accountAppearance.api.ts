import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountAppearanceDocument = gql`
    mutation accountAppearance($theme: EnumAppearanceTheme!) {
  accountAppearance(theme: $theme) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useAccountAppearanceMutation(options: VueApolloComposable.UseMutationOptions<Types.AccountAppearanceMutation, Types.AccountAppearanceMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.AccountAppearanceMutation, Types.AccountAppearanceMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.AccountAppearanceMutation, Types.AccountAppearanceMutationVariables>(AccountAppearanceDocument, options);
}
export type AccountAppearanceMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.AccountAppearanceMutation, Types.AccountAppearanceMutationVariables>;