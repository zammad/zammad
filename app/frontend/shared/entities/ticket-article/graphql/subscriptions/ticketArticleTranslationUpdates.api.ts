import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TicketArticleTranslationUpdatesDocument = gql`
    subscription ticketArticleTranslationUpdates($ticketId: ID!, $targetLocale: String!) {
  ticketArticleTranslationUpdates(
    ticketId: $ticketId
    targetLocale: $targetLocale
  ) {
    article {
      id
    }
    translation {
      content
      backend
      translated
    }
    error {
      message
      exception
    }
  }
}
    `;
export function useTicketArticleTranslationUpdatesSubscription(variables: Types.TicketArticleTranslationUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.TicketArticleTranslationUpdatesSubscriptionVariables> | ReactiveFunction<Types.TicketArticleTranslationUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.TicketArticleTranslationUpdatesSubscription, Types.TicketArticleTranslationUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.TicketArticleTranslationUpdatesSubscription, Types.TicketArticleTranslationUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.TicketArticleTranslationUpdatesSubscription, Types.TicketArticleTranslationUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.TicketArticleTranslationUpdatesSubscription, Types.TicketArticleTranslationUpdatesSubscriptionVariables>(TicketArticleTranslationUpdatesDocument, variables, options);
}
export type TicketArticleTranslationUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.TicketArticleTranslationUpdatesSubscription, Types.TicketArticleTranslationUpdatesSubscriptionVariables>;