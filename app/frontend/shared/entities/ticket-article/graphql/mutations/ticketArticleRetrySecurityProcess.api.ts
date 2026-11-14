import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SecurityStateFragmentDoc } from '../fragments/securityState.api';
import { ErrorsFragmentDoc } from '../../../../graphql/fragments/errors.api';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useTicketArticleRetrySecurityProcessMutation(options: VueApolloComposable.useMutation.Options<Types.TicketArticleRetrySecurityProcessMutation, Types.TicketArticleRetrySecurityProcessMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketArticleRetrySecurityProcessMutation, Types.TicketArticleRetrySecurityProcessMutationVariables>(TicketArticleRetrySecurityProcessDocument, options);
}
export type TicketArticleRetrySecurityProcessMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketArticleRetrySecurityProcessMutation, Types.TicketArticleRetrySecurityProcessMutationVariables>;