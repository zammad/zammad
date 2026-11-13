import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const SystemImportStateDocument = gql`
    query systemImportState {
  systemImportState {
    name
    result
    startedAt
    finishedAt
  }
}
    `;
export function useSystemImportStateQuery(options: VueApolloComposable.useQuery.Options<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables>(SystemImportStateDocument, options);
}
export function useSystemImportStateLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables>(SystemImportStateDocument, options);
}
export type SystemImportStateQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables>;