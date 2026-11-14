import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentContentTranslationAutoDocument = gql`
    mutation userCurrentContentTranslationAuto($enabled: Boolean!) {
  userCurrentContentTranslationAuto(enabled: $enabled) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentContentTranslationAutoMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentContentTranslationAutoMutation, Types.UserCurrentContentTranslationAutoMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentContentTranslationAutoMutation, Types.UserCurrentContentTranslationAutoMutationVariables>(UserCurrentContentTranslationAutoDocument, options);
}
export type UserCurrentContentTranslationAutoMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentContentTranslationAutoMutation, Types.UserCurrentContentTranslationAutoMutationVariables>;