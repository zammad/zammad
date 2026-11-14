import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentContentTranslationExcludedLanguagesDocument = gql`
    mutation userCurrentContentTranslationExcludedLanguages($languages: [String!]!) {
  userCurrentContentTranslationExcludedLanguages(languages: $languages) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentContentTranslationExcludedLanguagesMutation(options: VueApolloComposable.useMutation.Options<Types.UserCurrentContentTranslationExcludedLanguagesMutation, Types.UserCurrentContentTranslationExcludedLanguagesMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentContentTranslationExcludedLanguagesMutation, Types.UserCurrentContentTranslationExcludedLanguagesMutationVariables>(UserCurrentContentTranslationExcludedLanguagesDocument, options);
}
export type UserCurrentContentTranslationExcludedLanguagesMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.UserCurrentContentTranslationExcludedLanguagesMutation, Types.UserCurrentContentTranslationExcludedLanguagesMutationVariables>;