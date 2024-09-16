import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const MacrosUpdateDocument = gql`
    subscription macrosUpdate {
  macrosUpdate {
    macroUpdated
  }
}
    `;
export function useMacrosUpdateSubscription(options: VueApolloComposable.UseSubscriptionOptions<Types.MacrosUpdateSubscription, Types.MacrosUpdateSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.MacrosUpdateSubscription, Types.MacrosUpdateSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.MacrosUpdateSubscription, Types.MacrosUpdateSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.MacrosUpdateSubscription, Types.MacrosUpdateSubscriptionVariables>(MacrosUpdateDocument, {}, options);
}
export type MacrosUpdateSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.MacrosUpdateSubscription, Types.MacrosUpdateSubscriptionVariables>;