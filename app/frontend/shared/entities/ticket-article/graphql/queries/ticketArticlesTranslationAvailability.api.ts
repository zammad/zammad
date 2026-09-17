import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketArticlesTranslationAvailabilityDocument = gql`
    query ticketArticlesTranslationAvailability($ticketId: ID!, $pageSize: Int, $loadFirstArticles: Boolean = true, $firstArticlesCount: Int = 1, $translationTargetLocale: String!) {
  firstArticles: ticketArticles(ticketId: $ticketId, first: $firstArticlesCount) @include(if: $loadFirstArticles) {
    edges {
      node {
        id
        translationAvailable(targetLocale: $translationTargetLocale)
      }
    }
  }
  articles: ticketArticles(ticketId: $ticketId, last: $pageSize) {
    edges {
      node {
        id
        translationAvailable(targetLocale: $translationTargetLocale)
      }
    }
  }
}
    `;
export function useTicketArticlesTranslationAvailabilityQuery(variables: Types.TicketArticlesTranslationAvailabilityQueryVariables | VueCompositionApi.Ref<Types.TicketArticlesTranslationAvailabilityQueryVariables> | ReactiveFunction<Types.TicketArticlesTranslationAvailabilityQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketArticlesTranslationAvailabilityQuery, Types.TicketArticlesTranslationAvailabilityQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketArticlesTranslationAvailabilityQuery, Types.TicketArticlesTranslationAvailabilityQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketArticlesTranslationAvailabilityQuery, Types.TicketArticlesTranslationAvailabilityQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketArticlesTranslationAvailabilityQuery, Types.TicketArticlesTranslationAvailabilityQueryVariables>(TicketArticlesTranslationAvailabilityDocument, variables, options);
}
export function useTicketArticlesTranslationAvailabilityLazyQuery(variables?: Types.TicketArticlesTranslationAvailabilityQueryVariables | VueCompositionApi.Ref<Types.TicketArticlesTranslationAvailabilityQueryVariables> | ReactiveFunction<Types.TicketArticlesTranslationAvailabilityQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.TicketArticlesTranslationAvailabilityQuery, Types.TicketArticlesTranslationAvailabilityQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketArticlesTranslationAvailabilityQuery, Types.TicketArticlesTranslationAvailabilityQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketArticlesTranslationAvailabilityQuery, Types.TicketArticlesTranslationAvailabilityQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketArticlesTranslationAvailabilityQuery, Types.TicketArticlesTranslationAvailabilityQueryVariables>(TicketArticlesTranslationAvailabilityDocument, variables, options);
}
export type TicketArticlesTranslationAvailabilityQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketArticlesTranslationAvailabilityQuery, Types.TicketArticlesTranslationAvailabilityQueryVariables>;