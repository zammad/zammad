import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const ChecklistTemplateUpdatesDocument = gql`
    subscription checklistTemplateUpdates($onlyActive: Boolean = false) {
  checklistTemplateUpdates(onlyActive: $onlyActive) {
    checklistTemplates {
      id
      name
      active
    }
  }
}
    `;
export function useChecklistTemplateUpdatesSubscription(variables: Types.ChecklistTemplateUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.ChecklistTemplateUpdatesSubscriptionVariables> | ReactiveFunction<Types.ChecklistTemplateUpdatesSubscriptionVariables> = {}, options: VueApolloComposable.UseSubscriptionOptions<Types.ChecklistTemplateUpdatesSubscription, Types.ChecklistTemplateUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.ChecklistTemplateUpdatesSubscription, Types.ChecklistTemplateUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.ChecklistTemplateUpdatesSubscription, Types.ChecklistTemplateUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.ChecklistTemplateUpdatesSubscription, Types.ChecklistTemplateUpdatesSubscriptionVariables>(ChecklistTemplateUpdatesDocument, variables, options);
}
export type ChecklistTemplateUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.ChecklistTemplateUpdatesSubscription, Types.ChecklistTemplateUpdatesSubscriptionVariables>;