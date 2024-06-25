import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TemplateUpdatesDocument = gql`
    subscription templateUpdates($onlyActive: Boolean!) {
  templateUpdates(onlyActive: $onlyActive) {
    templates {
      id
      name
    }
  }
}
    `;
export function useTemplateUpdatesSubscription(variables: Types.TemplateUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.TemplateUpdatesSubscriptionVariables> | ReactiveFunction<Types.TemplateUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.TemplateUpdatesSubscription, Types.TemplateUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.TemplateUpdatesSubscription, Types.TemplateUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.TemplateUpdatesSubscription, Types.TemplateUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.TemplateUpdatesSubscription, Types.TemplateUpdatesSubscriptionVariables>(TemplateUpdatesDocument, variables, options);
}
export type TemplateUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.TemplateUpdatesSubscription, Types.TemplateUpdatesSubscriptionVariables>;