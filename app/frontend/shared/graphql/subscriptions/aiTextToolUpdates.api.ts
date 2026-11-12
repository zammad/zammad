import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const AiTextToolUpdatesDocument = gql`
    subscription aiTextToolUpdates {
  aiTextToolUpdates {
    textToolId
    groupIds
    removeTextToolId
  }
}
    `;
export function useAiTextToolUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.AiTextToolUpdatesSubscription, Types.AiTextToolUpdatesSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.AiTextToolUpdatesSubscription, Types.AiTextToolUpdatesSubscriptionVariables>(AiTextToolUpdatesDocument, options);
}
export type AiTextToolUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.AiTextToolUpdatesSubscription, Types.AiTextToolUpdatesSubscriptionVariables>;