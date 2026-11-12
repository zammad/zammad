import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const MacrosDocument = gql`
    query macros($selector: TicketMacrosSelectorInput!) {
  macros(selector: $selector) {
    id
    internalId
    active
    name
    uxFlowNextUp
  }
}
    `;
export function useMacrosQuery(options: VueApolloComposable.useQuery.Options<Types.MacrosQuery, Types.MacrosQueryVariables>) {
  return VueApolloComposable.useQuery<Types.MacrosQuery, Types.MacrosQueryVariables>(MacrosDocument, options);
}
export function useMacrosLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.MacrosQuery, Types.MacrosQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.MacrosQuery, Types.MacrosQueryVariables>(MacrosDocument, options);
}
export type MacrosQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.MacrosQuery, Types.MacrosQueryVariables>;