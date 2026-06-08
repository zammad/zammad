import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketArticleHighlightedTextUpsertDocument = gql`
    mutation ticketArticleHighlightedTextUpsert($articleId: ID!, $highlight: [TicketArticleHighlightedTextInput!]) {
  ticketArticleHighlightedTextUpsert(articleId: $articleId, highlight: $highlight) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketArticleHighlightedTextUpsertMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketArticleHighlightedTextUpsertMutation, Types.TicketArticleHighlightedTextUpsertMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketArticleHighlightedTextUpsertMutation, Types.TicketArticleHighlightedTextUpsertMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketArticleHighlightedTextUpsertMutation, Types.TicketArticleHighlightedTextUpsertMutationVariables>(TicketArticleHighlightedTextUpsertDocument, options);
}
export type TicketArticleHighlightedTextUpsertMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketArticleHighlightedTextUpsertMutation, Types.TicketArticleHighlightedTextUpsertMutationVariables>;