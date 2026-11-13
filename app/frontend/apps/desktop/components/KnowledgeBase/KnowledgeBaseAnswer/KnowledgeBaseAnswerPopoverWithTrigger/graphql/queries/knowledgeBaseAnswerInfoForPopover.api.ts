import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerTranslationFragmentDoc } from '../../../../../../entities/knowledge-base/graphql/fragments/knowledgeBaseAnswerTranslation.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseAnswerInfoForPopoverDocument = gql`
    query knowledgeBaseAnswerInfoForPopover($answerId: ID!, $locale: String) {
  knowledgeBaseAnswer(answerId: $answerId, locale: $locale) {
    id
    translation(locale: $locale) {
      ...knowledgeBaseAnswerTranslation
    }
  }
}
    ${KnowledgeBaseAnswerTranslationFragmentDoc}`;
export function useKnowledgeBaseAnswerInfoForPopoverQuery(options: VueApolloComposable.useQuery.Options<Types.KnowledgeBaseAnswerInfoForPopoverQuery, Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables>) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseAnswerInfoForPopoverQuery, Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables>(KnowledgeBaseAnswerInfoForPopoverDocument, options);
}
export function useKnowledgeBaseAnswerInfoForPopoverLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.KnowledgeBaseAnswerInfoForPopoverQuery, Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseAnswerInfoForPopoverQuery, Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables>(KnowledgeBaseAnswerInfoForPopoverDocument, options);
}
export type KnowledgeBaseAnswerInfoForPopoverQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.KnowledgeBaseAnswerInfoForPopoverQuery, Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables>;