import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const SystemSetupInfoDocument = gql`
    query systemSetupInfo {
  systemSetupInfo {
    status
    type
  }
}
    `;
export function useSystemSetupInfoQuery(options: VueApolloComposable.UseQueryOptions<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables>(SystemSetupInfoDocument, {}, options);
}
export function useSystemSetupInfoLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables>(SystemSetupInfoDocument, {}, options);
}
export type SystemSetupInfoQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.SystemSetupInfoQuery, Types.SystemSetupInfoQueryVariables>;