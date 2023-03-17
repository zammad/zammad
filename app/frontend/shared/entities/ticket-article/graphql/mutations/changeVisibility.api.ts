import * as Types from '../../../../graphql/types';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useTicketArticleChangeVisibilityMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketArticleChangeVisibilityMutation, Types.TicketArticleChangeVisibilityMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketArticleChangeVisibilityMutation, Types.TicketArticleChangeVisibilityMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketArticleChangeVisibilityMutation, Types.TicketArticleChangeVisibilityMutationVariables>(TicketArticleChangeVisibilityDocument, options);
}
export type TicketArticleChangeVisibilityMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketArticleChangeVisibilityMutation, Types.TicketArticleChangeVisibilityMutationVariables>;