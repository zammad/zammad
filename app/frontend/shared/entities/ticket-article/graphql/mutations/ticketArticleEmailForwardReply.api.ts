import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketArticleEmailForwardReplyDocument = gql`
    mutation ticketArticleEmailForwardReply($articleId: ID!, $formId: FormId!) {
  ticketArticleEmailForwardReply(articleId: $articleId, formId: $formId) {
    quotableFrom
    quotableTo
    quotableCc
    attachments {
      id
      internalId
      name
      size
      type
    }
    errors {
      ...errors
    }
  }
}
    ${ErrorsFragmentDoc}`;
export function useTicketArticleEmailForwardReplyMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketArticleEmailForwardReplyMutation, Types.TicketArticleEmailForwardReplyMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketArticleEmailForwardReplyMutation, Types.TicketArticleEmailForwardReplyMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketArticleEmailForwardReplyMutation, Types.TicketArticleEmailForwardReplyMutationVariables>(TicketArticleEmailForwardReplyDocument, options);
}
export type TicketArticleEmailForwardReplyMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketArticleEmailForwardReplyMutation, Types.TicketArticleEmailForwardReplyMutationVariables>;