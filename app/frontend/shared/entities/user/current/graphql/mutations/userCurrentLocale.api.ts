import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useUserCurrentLocaleMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentLocaleMutation, Types.UserCurrentLocaleMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentLocaleMutation, Types.UserCurrentLocaleMutationVariables>(UserCurrentLocaleDocument, options);
}
export type UserCurrentLocaleMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentLocaleMutation, Types.UserCurrentLocaleMutationVariables>;