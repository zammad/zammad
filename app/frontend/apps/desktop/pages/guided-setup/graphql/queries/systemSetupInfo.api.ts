import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const SystemSetupInfoDocument = gql`
    query systemSetupInfo {
  systemSetupInfo {
    status
    type
  }
}
    `;
export function useSystemSetupInfoQuery(options: VueApolloComposable.useQuery.Options<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables>(SystemSetupInfoDocument, options);
}
export function useSystemSetupInfoLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables>(SystemSetupInfoDocument, options);
}
export type SystemSetupInfoQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables>;