import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const QuickSearchDocument = gql`
    query quickSearch($search: String!, $limit: Int = 10) {
  quickSearchOrganizations: search(
    search: $search
    onlyIn: Organization
    limit: $limit
  ) {
    totalCount
    items {
      ... on Organization {
        id
        internalId
        name
        active
      }
    }
  }
  quickSearchTickets: search(search: $search, onlyIn: Ticket, limit: $limit) {
    totalCount
    items {
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
    }
  }
  quickSearchUsers: search(search: $search, onlyIn: User, limit: $limit) {
    totalCount
    items {
      ... on User {
        id
        internalId
        fullname
        active
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