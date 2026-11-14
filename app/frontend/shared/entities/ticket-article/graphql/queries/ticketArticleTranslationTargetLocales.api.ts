import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useTicketArticleTranslationTargetLocalesQuery(options: VueApolloComposable.useQuery.Options<Types.TicketArticleTranslationTargetLocalesQuery, Types.TicketArticleTranslationTargetLocalesQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.TicketArticleTranslationTargetLocalesQuery, Types.TicketArticleTranslationTargetLocalesQueryVariables>(TicketArticleTranslationTargetLocalesDocument, options);
}
export function useTicketArticleTranslationTargetLocalesLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TicketArticleTranslationTargetLocalesQuery, Types.TicketArticleTranslationTargetLocalesQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TicketArticleTranslationTargetLocalesQuery, Types.TicketArticleTranslationTargetLocalesQueryVariables>(TicketArticleTranslationTargetLocalesDocument, options);
}
export type TicketArticleTranslationTargetLocalesQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TicketArticleTranslationTargetLocalesQuery, Types.TicketArticleTranslationTargetLocalesQueryVariables>;