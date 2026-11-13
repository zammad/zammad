import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useTemplateUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.TemplateUpdatesSubscription, Types.TemplateUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.TemplateUpdatesSubscription, Types.TemplateUpdatesSubscriptionVariables>(TemplateUpdatesDocument, options);
}
export type TemplateUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.TemplateUpdatesSubscription, Types.TemplateUpdatesSubscriptionVariables>;