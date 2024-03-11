import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useTicketArticleRetryMediaDownloadMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketArticleRetryMediaDownloadMutation, Types.TicketArticleRetryMediaDownloadMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketArticleRetryMediaDownloadMutation, Types.TicketArticleRetryMediaDownloadMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketArticleRetryMediaDownloadMutation, Types.TicketArticleRetryMediaDownloadMutationVariables>(TicketArticleRetryMediaDownloadDocument, options);
}
export type TicketArticleRetryMediaDownloadMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketArticleRetryMediaDownloadMutation, Types.TicketArticleRetryMediaDownloadMutationVariables>;