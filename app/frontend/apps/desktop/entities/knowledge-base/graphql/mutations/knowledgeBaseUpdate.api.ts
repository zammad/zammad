import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseUpdateDocument = gql`
    mutation knowledgeBaseUpdate($input: KnowledgeBaseInput!, $locale: String!) {
  knowledgeBaseUpdate(input: $input, locale: $locale) {
    knowledgeBase {
      id
      title
      footerNote
      policy {
        update
      }
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useKnowledgeBaseUpdateMutation(options: VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseUpdateMutation, Types.KnowledgeBaseUpdateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.KnowledgeBaseUpdateMutation, Types.KnowledgeBaseUpdateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseUpdateMutation, Types.KnowledgeBaseUpdateMutationVariables>(KnowledgeBaseUpdateDocument, options);
}
export type KnowledgeBaseUpdateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.KnowledgeBaseUpdateMutation, Types.KnowledgeBaseUpdateMutationVariables>;