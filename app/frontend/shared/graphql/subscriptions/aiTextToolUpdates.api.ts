import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AiTextToolUpdatesDocument = gql`
    subscription aiTextToolUpdates {
  aiTextToolUpdates {
    textToolId
    groupIds
    removeTextToolId
  }
}
    `;
export function useAiTextToolUpdatesSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.AiTextToolUpdatesSubscription, Types.AiTextToolUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.AiTextToolUpdatesSubscription, Types.AiTextToolUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.AiTextToolUpdatesSubscription, Types.AiTextToolUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.AiTextToolUpdatesSubscription, Types.AiTextToolUpdatesSubscriptionVariables>(AiTextToolUpdatesDocument, {}, options);
}
export type AiTextToolUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.AiTextToolUpdatesSubscription, Types.AiTextToolUpdatesSubscriptionVariables>;