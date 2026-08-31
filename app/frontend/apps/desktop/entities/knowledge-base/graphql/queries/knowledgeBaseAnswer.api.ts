import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { KnowledgeBaseAnswerAttributesFragmentDoc } from '../fragments/knowledgeBaseAnswerAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseAnswerDocument = gql`
    query knowledgeBaseAnswer($answerId: ID!, $locale: String, $withBodyForEditing: Boolean = false, $withNavigation: Boolean = true) {
  knowledgeBaseAnswer(answerId: $answerId, locale: $locale) {
    id
    ...knowledgeBaseAnswerAttributes
    navigation @include(if: $withNavigation) {
      index
      totalCount
      previousAnswer {
        id
        title
      }
      nextAnswer {
        id
        title
      }
    }
  }
}
    ${KnowledgeBaseAnswerAttributesFragmentDoc}`;
export function useKnowledgeBaseAnswerQuery(variables: Types.KnowledgeBaseAnswerQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseAnswerQueryVariables> | ReactiveFunction<Types.KnowledgeBaseAnswerQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerQuery, Types.KnowledgeBaseAnswerQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerQuery, Types.KnowledgeBaseAnswerQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerQuery, Types.KnowledgeBaseAnswerQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseAnswerQuery, Types.KnowledgeBaseAnswerQueryVariables>(KnowledgeBaseAnswerDocument, variables, options);
}
export function useKnowledgeBaseAnswerLazyQuery(variables?: Types.KnowledgeBaseAnswerQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseAnswerQueryVariables> | ReactiveFunction<Types.KnowledgeBaseAnswerQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerQuery, Types.KnowledgeBaseAnswerQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerQuery, Types.KnowledgeBaseAnswerQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseAnswerQuery, Types.KnowledgeBaseAnswerQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseAnswerQuery, Types.KnowledgeBaseAnswerQueryVariables>(KnowledgeBaseAnswerDocument, variables, options);
}
export type KnowledgeBaseAnswerQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.KnowledgeBaseAnswerQuery, Types.KnowledgeBaseAnswerQueryVariables>;