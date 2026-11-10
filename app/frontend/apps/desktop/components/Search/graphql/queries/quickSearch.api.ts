import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable/compat';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
    }
  }
}
    `;
export function useQuickSearchQuery(variables: Types.QuickSearchQueryVariables | VueCompositionApi.Ref<Types.QuickSearchQueryVariables> | ReactiveFunction<Types.QuickSearchQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.QuickSearchQuery, Types.QuickSearchQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.QuickSearchQuery, Types.QuickSearchQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.QuickSearchQuery, Types.QuickSearchQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.QuickSearchQuery, Types.QuickSearchQueryVariables>(QuickSearchDocument, variables, options);
}
export function useQuickSearchLazyQuery(variables?: Types.QuickSearchQueryVariables | VueCompositionApi.Ref<Types.QuickSearchQueryVariables> | ReactiveFunction<Types.QuickSearchQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.QuickSearchQuery, Types.QuickSearchQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.QuickSearchQuery, Types.QuickSearchQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.QuickSearchQuery, Types.QuickSearchQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.QuickSearchQuery, Types.QuickSearchQueryVariables>(QuickSearchDocument, variables, options);
}
export type QuickSearchQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.QuickSearchQuery, Types.QuickSearchQueryVariables>;