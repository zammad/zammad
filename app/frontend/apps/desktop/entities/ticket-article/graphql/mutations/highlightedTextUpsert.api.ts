import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../../../shared/graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useTicketArticleHighlightedTextUpsertMutation(options: VueApolloComposable.useMutation.Options<Types.TicketArticleHighlightedTextUpsertMutation, Types.TicketArticleHighlightedTextUpsertMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketArticleHighlightedTextUpsertMutation, Types.TicketArticleHighlightedTextUpsertMutationVariables>(TicketArticleHighlightedTextUpsertDocument, options);
}
export type TicketArticleHighlightedTextUpsertMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketArticleHighlightedTextUpsertMutation, Types.TicketArticleHighlightedTextUpsertMutationVariables>;