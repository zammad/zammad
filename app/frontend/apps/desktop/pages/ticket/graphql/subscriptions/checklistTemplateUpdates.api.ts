import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useChecklistTemplateUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.ChecklistTemplateUpdatesSubscription, Types.ChecklistTemplateUpdatesSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.ChecklistTemplateUpdatesSubscription, Types.ChecklistTemplateUpdatesSubscriptionVariables>(ChecklistTemplateUpdatesDocument, options);
}
export type ChecklistTemplateUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.ChecklistTemplateUpdatesSubscription, Types.ChecklistTemplateUpdatesSubscriptionVariables>;