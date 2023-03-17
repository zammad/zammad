import * as Types from '../../../../graphql/types';

import gql from 'graphql-tag';
import { SecurityStateFragmentDoc } from '../fragments/securityState.api';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketArticleRetrySecurityProcessDocument = gql`
    mutation ticketArticleRetrySecurityProcess($articleId: ID!) {
  ticketArticleRetrySecurityProcess(articleId: $articleId) {
    retryResult {
      ...securityState
    }
    article {
      id
      securityState {
        ...securityState
      }
    }
    errors {
      ...errors
    }
  }
}
    ${SecurityStateFragmentDoc}
${ErrorsFragmentDoc}`;
export function useTicketArticleRetrySecurityProcessMutation(options: VueApolloComposable.UseMutationOptions<Types.TicketArticleRetrySecurityProcessMutation, Types.TicketArticleRetrySecurityProcessMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.TicketArticleRetrySecurityProcessMutation, Types.TicketArticleRetrySecurityProcessMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.TicketArticleRetrySecurityProcessMutation, Types.TicketArticleRetrySecurityProcessMutationVariables>(TicketArticleRetrySecurityProcessDocument, options);
}
export type TicketArticleRetrySecurityProcessMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.TicketArticleRetrySecurityProcessMutation, Types.TicketArticleRetrySecurityProcessMutationVariables>;