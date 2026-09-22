import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketArticleTranslateManyDocument = gql`
    mutation ticketArticleTranslateMany($ticketId: ID!, $firstArticlesCount: Int, $loadFirstArticles: Boolean, $pageSize: Int, $beforeCursor: String, $afterCursor: String, $targetLocale: String!) {
  ticketArticleTranslateMany(
    ticketId: $ticketId
    firstArticlesCount: $firstArticlesCount
    loadFirstArticles: $loadFirstArticles
    pageSize: $pageSize
    beforeCursor: $beforeCursor
    afterCursor: $afterCursor
    targetLocale: $targetLocale
  ) {
    pendingArticleIds
    translations {
      article {
        id
      }
      translation {
        content
        backend
        translated
      }
    }
  }
}
    `;
export function useTicketArticleTranslateManyMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketArticleTranslateManyMutation, Types.TicketArticleTranslateManyMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketArticleTranslateManyMutation, Types.TicketArticleTranslateManyMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketArticleTranslateManyMutation, Types.TicketArticleTranslateManyMutationVariables>(TicketArticleTranslateManyDocument, options);
}
export type TicketArticleTranslateManyMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketArticleTranslateManyMutation, Types.TicketArticleTranslateManyMutationVariables>;