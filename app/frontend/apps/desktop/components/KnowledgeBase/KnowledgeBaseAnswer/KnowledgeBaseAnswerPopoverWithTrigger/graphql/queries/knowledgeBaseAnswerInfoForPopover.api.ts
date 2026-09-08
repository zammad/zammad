import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerTranslationFragmentDoc } from '../../../../../../entities/knowledge-base/graphql/fragments/knowledgeBaseAnswerTranslation.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useKnowledgeBaseAnswerInfoForPopoverQuery(variables: Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables> | ReactiveFunction<Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerInfoForPopoverQuery, Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerInfoForPopoverQuery, Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerInfoForPopoverQuery, Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseAnswerInfoForPopoverQuery, Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables>(KnowledgeBaseAnswerInfoForPopoverDocument, variables, options);
}
export function useKnowledgeBaseAnswerInfoForPopoverLazyQuery(variables?: Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables> | ReactiveFunction<Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerInfoForPopoverQuery, Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerInfoForPopoverQuery, Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerInfoForPopoverQuery, Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseAnswerInfoForPopoverQuery, Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables>(KnowledgeBaseAnswerInfoForPopoverDocument, variables, options);
}
export type KnowledgeBaseAnswerInfoForPopoverQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.KnowledgeBaseAnswerInfoForPopoverQuery, Types.KnowledgeBaseAnswerInfoForPopoverQueryVariables>;