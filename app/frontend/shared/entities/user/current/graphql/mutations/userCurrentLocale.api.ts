import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentLocaleDocument = gql`
    mutation userCurrentLocale($locale: String!) {
  userCurrentLocale(locale: $locale) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentLocaleMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentLocaleMutation, Types.UserCurrentLocaleMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentLocaleMutation, Types.UserCurrentLocaleMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentLocaleMutation, Types.UserCurrentLocaleMutationVariables>(UserCurrentLocaleDocument, options);
}
export type UserCurrentLocaleMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentLocaleMutation, Types.UserCurrentLocaleMutationVariables>;