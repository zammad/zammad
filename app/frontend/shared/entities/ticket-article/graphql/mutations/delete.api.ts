import * as Types from '../../../../graphql/types';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useTicketArticleDeleteMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketArticleDeleteMutation, Types.TicketArticleDeleteMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketArticleDeleteMutation, Types.TicketArticleDeleteMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketArticleDeleteMutation, Types.TicketArticleDeleteMutationVariables>(TicketArticleDeleteDocument, options);
}
export type TicketArticleDeleteMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketArticleDeleteMutation, Types.TicketArticleDeleteMutationVariables>;