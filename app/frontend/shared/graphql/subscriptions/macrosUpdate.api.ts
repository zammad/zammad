import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const MacrosUpdateDocument = gql`
    subscription macrosUpdate {
  macrosUpdate {
    macroId
    groupIds
    removeMacroId
  }
}
    `;
export function useMacrosUpdateSubscription(options: VueApolloComposable.useSubscription.Options<Types.MacrosUpdateSubscription, Types.MacrosUpdateSubscriptionVariables> = {}) {
  return VueApolloComposable.useSubscription<Types.MacrosUpdateSubscription, Types.MacrosUpdateSubscriptionVariables>(MacrosUpdateDocument, options);
}
export type MacrosUpdateSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.MacrosUpdateSubscription, Types.MacrosUpdateSubscriptionVariables>;