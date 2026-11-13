import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const KnowledgeBaseDocument = gql`
    query knowledgeBase($locale: String) {
  knowledgeBase(locale: $locale) {
    id
    translation(locale: $locale) {
      id
      title
      footerNote
    }
    iconset
    isPubliclyAvailable
    isVisiblePublicly(locale: $locale)
    categorySortingMode
    policy {
      update
    }
    showFeedIcon
    kbLocales {
      id
      primary
      systemLocale {
        id
        locale
        name
      }
    }
    currentLocale(locale: $locale) {
      id
      systemLocale {
        id
        locale
      }
    }
  }
}
    `;
export function useKnowledgeBaseQuery(options: VueApolloComposable.useQuery.Options<Types.KnowledgeBaseQuery, Types.KnowledgeBaseQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.KnowledgeBaseQuery, Types.KnowledgeBaseQueryVariables>(KnowledgeBaseDocument, options);
}
export function useKnowledgeBaseLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.KnowledgeBaseQuery, Types.KnowledgeBaseQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.KnowledgeBaseQuery, Types.KnowledgeBaseQueryVariables>(KnowledgeBaseDocument, options);
}
export type KnowledgeBaseQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.KnowledgeBaseQuery, Types.KnowledgeBaseQueryVariables>;