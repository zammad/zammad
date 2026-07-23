import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const KnowledgeBaseDocument = gql`
    query knowledgeBase($locale: String) {
  knowledgeBase(locale: $locale) {
    id
    title
    iconset
    isPubliclyAvailable
    isVisiblePublicly
    kbLocales {
      id
      primary
      systemLocale {
        id
        locale
        name
      }
    }
    currentLocale {
      id
      systemLocale {
        id
        locale
      }
    }
  }
}
    `;
export function useKnowledgeBaseQuery(variables: Types.KnowledgeBaseQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseQueryVariables> | ReactiveFunction<Types.KnowledgeBaseQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseQuery, Types.KnowledgeBaseQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseQuery, Types.KnowledgeBaseQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseQuery, Types.KnowledgeBaseQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseQuery, Types.KnowledgeBaseQueryVariables>(KnowledgeBaseDocument, variables, options);
}
export function useKnowledgeBaseLazyQuery(variables: Types.KnowledgeBaseQueryVariables | VueCompositionApi.Ref<Types.KnowledgeBaseQueryVariables> | ReactiveFunction<Types.KnowledgeBaseQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseQuery, Types.KnowledgeBaseQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseQuery, Types.KnowledgeBaseQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.KnowledgeBaseQuery, Types.KnowledgeBaseQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseQuery, Types.KnowledgeBaseQueryVariables>(KnowledgeBaseDocument, variables, options);
}
export type KnowledgeBaseQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.KnowledgeBaseQuery, Types.KnowledgeBaseQueryVariables>;