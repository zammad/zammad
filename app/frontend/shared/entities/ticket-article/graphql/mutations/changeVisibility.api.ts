import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketArticleChangeVisibilityDocument = gql`
    mutation ticketArticleChangeVisibility($articleId: ID!, $internal: Boolean!) {
  ticketArticleChangeVisibility(articleId: $articleId, internal: $internal) {
    article {
      id
      internal
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketArticleChangeVisibilityMutation(options: VueApolloComposable.useMutation.Options<Types.TicketArticleChangeVisibilityMutation, Types.TicketArticleChangeVisibilityMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketArticleChangeVisibilityMutation, Types.TicketArticleChangeVisibilityMutationVariables>(TicketArticleChangeVisibilityDocument, options);
}
export type TicketArticleChangeVisibilityMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketArticleChangeVisibilityMutation, Types.TicketArticleChangeVisibilityMutationVariables>;