import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketArticleTranslationAvailabilityFragmentDoc } from '../fragments/ticketArticleTranslationAvailability.api';
import { TicketArticleTranslationFragmentDoc } from '../fragments/ticketArticleTranslation.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketArticleTranslateManyDocument = gql`
    mutation ticketArticleTranslateMany($ticketId: ID!, $firstArticlesCount: Int, $loadFirstArticles: Boolean, $pageSize: Int, $beforeCursor: String, $afterCursor: String, $targetLocale: String!, $generateMissing: Boolean!) {
  ticketArticleTranslateMany(
    ticketId: $ticketId
    firstArticlesCount: $firstArticlesCount
    loadFirstArticles: $loadFirstArticles
    pageSize: $pageSize
    beforeCursor: $beforeCursor
    afterCursor: $afterCursor
    targetLocale: $targetLocale
    generateMissing: $generateMissing
  ) {
    pendingArticleIds @include(if: $generateMissing)
    results {
      article {
        ...ticketArticleTranslationAvailability
        ...ticketArticleTranslation @include(if: $generateMissing)
      }
      translated @include(if: $generateMissing)
    }
  }
}
    ${TicketArticleTranslationAvailabilityFragmentDoc}
${TicketArticleTranslationFragmentDoc}`;
export function useTicketArticleTranslateManyMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketArticleTranslateManyMutation, Types.TicketArticleTranslateManyMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketArticleTranslateManyMutation, Types.TicketArticleTranslateManyMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketArticleTranslateManyMutation, Types.TicketArticleTranslateManyMutationVariables>(TicketArticleTranslateManyDocument, options);
}
export type TicketArticleTranslateManyMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketArticleTranslateManyMutation, Types.TicketArticleTranslateManyMutationVariables>;