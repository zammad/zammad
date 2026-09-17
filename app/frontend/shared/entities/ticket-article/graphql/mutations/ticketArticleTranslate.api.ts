import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketArticleTranslateDocument = gql`
    mutation ticketArticleTranslate($articleId: ID!, $targetLocale: String!, $force: Boolean) {
  ticketArticleTranslate(
    articleId: $articleId
    targetLocale: $targetLocale
    force: $force
  ) {
    translation {
      content
      backend
      translated
    }
  }
}
    `;
export function useTicketArticleTranslateMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketArticleTranslateMutation, Types.TicketArticleTranslateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketArticleTranslateMutation, Types.TicketArticleTranslateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketArticleTranslateMutation, Types.TicketArticleTranslateMutationVariables>(TicketArticleTranslateDocument, options);
}
export type TicketArticleTranslateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketArticleTranslateMutation, Types.TicketArticleTranslateMutationVariables>;