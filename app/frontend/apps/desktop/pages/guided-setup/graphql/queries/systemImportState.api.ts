import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useSystemImportStateQuery(options: VueApolloComposable.UseQueryOptions<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables>(SystemImportStateDocument, {}, options);
}
export function useSystemImportStateLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables>(SystemImportStateDocument, {}, options);
}
export type SystemImportStateQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.SystemImportStateQuery, Types.SystemImportStateQueryVariables>;