import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseAnswerAddDocument = gql`
    mutation knowledgeBaseAnswerAdd($input: KnowledgeBaseCreateAnswerInput!, $locale: String!) {
  knowledgeBaseAnswerAdd(input: $input, locale: $locale) {
    answer {
      id
      visibility
      position
      translation(locale: $locale) {
        id
        title
        kbLocale {
          id
          systemLocale {
            locale
          }
        }
      }
      category {
        id
      }
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useKnowledgeBaseAnswerAddMutation(options: VueApolloComposable.useMutation.Options<Types.KnowledgeBaseAnswerAddMutation, Types.KnowledgeBaseAnswerAddMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.KnowledgeBaseAnswerAddMutation, Types.KnowledgeBaseAnswerAddMutationVariables>(KnowledgeBaseAnswerAddDocument, options);
}
export type KnowledgeBaseAnswerAddMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.KnowledgeBaseAnswerAddMutation, Types.KnowledgeBaseAnswerAddMutationVariables>;