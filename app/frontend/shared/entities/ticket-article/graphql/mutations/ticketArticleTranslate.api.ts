import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TicketArticleTranslationFragmentDoc } from '../fragments/ticketArticleTranslation.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TicketArticleTranslateDocument = gql`
    mutation ticketArticleTranslate($articleId: ID!, $targetLocale: String!, $force: Boolean, $regenerationOfId: ID) {
  ticketArticleTranslate(
    articleId: $articleId
    targetLocale: $targetLocale
    force: $force
    regenerationOfId: $regenerationOfId
  ) {
    article {
      ...ticketArticleTranslation
    }
    translation {
      translated
    }
    analytics {
      run {
        id
      }
      usage {
        userHasProvidedFeedback
      }
    }
    pendingBackend
  }
}
    ${TicketArticleTranslationFragmentDoc}`;
export function useTicketArticleTranslateMutation(options: VueApolloComposable.useMutation.Options<Types.TicketArticleTranslateMutation, Types.TicketArticleTranslateMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.TicketArticleTranslateMutation, Types.TicketArticleTranslateMutationVariables>(TicketArticleTranslateDocument, options);
}
export type TicketArticleTranslateMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.TicketArticleTranslateMutation, Types.TicketArticleTranslateMutationVariables>;