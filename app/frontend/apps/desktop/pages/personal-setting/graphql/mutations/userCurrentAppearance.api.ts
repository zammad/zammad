import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentAppearanceDocument = gql`
    mutation userCurrentAppearance($theme: EnumAppearanceTheme!) {
  userCurrentAppearance(theme: $theme) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentAppearanceMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentAppearanceMutation, Types.UserCurrentAppearanceMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentAppearanceMutation, Types.UserCurrentAppearanceMutationVariables>(UserCurrentAppearanceDocument, options);
}
export type UserCurrentAppearanceMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentAppearanceMutation, Types.UserCurrentAppearanceMutationVariables>;