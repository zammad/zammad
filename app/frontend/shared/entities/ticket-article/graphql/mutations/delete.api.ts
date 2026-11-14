import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketArticleDeleteDocument = gql`
    mutation ticketArticleDelete($articleId: ID!) {
  ticketArticleDelete(articleId: $articleId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketArticleDeleteMutation(options: VueApolloComposable.useMutation.Options<Types.TicketArticleDeleteMutation, Types.TicketArticleDeleteMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketArticleDeleteMutation, Types.TicketArticleDeleteMutationVariables>(TicketArticleDeleteDocument, options);
}
export type TicketArticleDeleteMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketArticleDeleteMutation, Types.TicketArticleDeleteMutationVariables>;