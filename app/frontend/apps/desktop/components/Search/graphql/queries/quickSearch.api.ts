import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const QuickSearchDocument = gql`
    query quickSearch($search: String!, $onlyIn: [EnumSearchableModels!]!, $limit: Int = 10) {
  searchGrouped(search: $search, onlyIn: $onlyIn, limit: $limit) {
    model
    totalCount
    items {
      __typename
      ... on Ticket {
        id
        internalId
        title
        number
        state {
          id
          name
        }
        stateColorCode
      }
      ... on User {
        id
        internalId
        fullname
        active
      }
      ... on Organization {
        id
        internalId
        name
        active
      }
      ... on KnowledgeBaseAnswerTranslation {
        id
        title
        visibility
        kbLocale {
          systemLocale {
            locale
          }
        }
        answer {
          id
          category {
            id
          }
        }
      }
      ... on ChatSession {
        id
        internalId
        name
      }
    }
  }
}
    `;
export function useQuickSearchQuery(options: VueApolloComposable.useQuery.Options<Types.QuickSearchQuery, Types.QuickSearchQueryVariables>) {
  return VueApolloComposable.useQuery<Types.QuickSearchQuery, Types.QuickSearchQueryVariables>(QuickSearchDocument, options);
}
export function useQuickSearchLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.QuickSearchQuery, Types.QuickSearchQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.QuickSearchQuery, Types.QuickSearchQueryVariables>(QuickSearchDocument, options);
}
export type QuickSearchQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.QuickSearchQuery, Types.QuickSearchQueryVariables>;