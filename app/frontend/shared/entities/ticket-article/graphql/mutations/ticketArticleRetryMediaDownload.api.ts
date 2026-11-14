import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketArticleRetryMediaDownloadDocument = gql`
    mutation ticketArticleRetryMediaDownload($articleId: ID!) {
  ticketArticleRetryMediaDownload(articleId: $articleId) {
    success
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketArticleRetryMediaDownloadMutation(options: VueApolloComposable.useMutation.Options<Types.TicketArticleRetryMediaDownloadMutation, Types.TicketArticleRetryMediaDownloadMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketArticleRetryMediaDownloadMutation, Types.TicketArticleRetryMediaDownloadMutationVariables>(TicketArticleRetryMediaDownloadDocument, options);
}
export type TicketArticleRetryMediaDownloadMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketArticleRetryMediaDownloadMutation, Types.TicketArticleRetryMediaDownloadMutationVariables>;