import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketArticleTranslationTargetLocalesDocument = gql`
    query ticketArticleTranslationTargetLocales {
  ticketArticleTranslationTargetLocales {
    locale
    alias
    name
    dir
  }
}
    `;
export function useTicketArticleTranslationTargetLocalesQuery(options: VueApolloComposable.UseQueryOptions<Types.TicketArticleTranslationTargetLocalesQuery, Types.TicketArticleTranslationTargetLocalesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketArticleTranslationTargetLocalesQuery, Types.TicketArticleTranslationTargetLocalesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketArticleTranslationTargetLocalesQuery, Types.TicketArticleTranslationTargetLocalesQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TicketArticleTranslationTargetLocalesQuery, Types.TicketArticleTranslationTargetLocalesQueryVariables>(TicketArticleTranslationTargetLocalesDocument, {}, options);
}
export function useTicketArticleTranslationTargetLocalesLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.TicketArticleTranslationTargetLocalesQuery, Types.TicketArticleTranslationTargetLocalesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TicketArticleTranslationTargetLocalesQuery, Types.TicketArticleTranslationTargetLocalesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TicketArticleTranslationTargetLocalesQuery, Types.TicketArticleTranslationTargetLocalesQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TicketArticleTranslationTargetLocalesQuery, Types.TicketArticleTranslationTargetLocalesQueryVariables>(TicketArticleTranslationTargetLocalesDocument, {}, options);
}
export type TicketArticleTranslationTargetLocalesQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TicketArticleTranslationTargetLocalesQuery, Types.TicketArticleTranslationTargetLocalesQueryVariables>;