import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const LinkUpdatesDocument = gql`
    subscription linkUpdates($objectId: ID!, $targetType: String!) {
  linkUpdates(objectId: $objectId, targetType: $targetType) {
    links {
      item {
        ... on Ticket {
          id
          internalId
          title
          state {
            id
            name
          }
          stateColorCode
        }
        ... on KnowledgeBaseAnswerTranslation {
          id
        }
      }
      type
    }
  }
}
    `;
export function useLinkUpdatesSubscription(variables: Types.LinkUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.LinkUpdatesSubscriptionVariables> | ReactiveFunction<Types.LinkUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.LinkUpdatesSubscription, Types.LinkUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.LinkUpdatesSubscription, Types.LinkUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.LinkUpdatesSubscription, Types.LinkUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.LinkUpdatesSubscription, Types.LinkUpdatesSubscriptionVariables>(LinkUpdatesDocument, variables, options);
}
export type LinkUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.LinkUpdatesSubscription, Types.LinkUpdatesSubscriptionVariables>;