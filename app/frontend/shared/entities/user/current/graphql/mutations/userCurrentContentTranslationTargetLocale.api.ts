import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentContentTranslationTargetLocaleDocument = gql`
    mutation userCurrentContentTranslationTargetLocale($targetLocale: String!) {
  userCurrentContentTranslationTargetLocale(targetLocale: $targetLocale) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useUserCurrentContentTranslationTargetLocaleMutation(options: VueApolloComposable.UseMutationOptions<Types.UserCurrentContentTranslationTargetLocaleMutation, Types.UserCurrentContentTranslationTargetLocaleMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.UserCurrentContentTranslationTargetLocaleMutation, Types.UserCurrentContentTranslationTargetLocaleMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.UserCurrentContentTranslationTargetLocaleMutation, Types.UserCurrentContentTranslationTargetLocaleMutationVariables>(UserCurrentContentTranslationTargetLocaleDocument, options);
}
export type UserCurrentContentTranslationTargetLocaleMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.UserCurrentContentTranslationTargetLocaleMutation, Types.UserCurrentContentTranslationTargetLocaleMutationVariables>;