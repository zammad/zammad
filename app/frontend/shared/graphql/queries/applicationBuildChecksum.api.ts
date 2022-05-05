import * as Types from '../types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const ApplicationBuildChecksumDocument = gql`
    query applicationBuildChecksum {
  applicationBuildChecksum
}
    `;
export function useApplicationBuildChecksumQuery(options: VueApolloComposable.UseQueryOptions<Types.ApplicationBuildChecksumQuery, Types.ApplicationBuildChecksumQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.ApplicationBuildChecksumQuery, Types.ApplicationBuildChecksumQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.ApplicationBuildChecksumQuery, Types.ApplicationBuildChecksumQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.ApplicationBuildChecksumQuery, Types.ApplicationBuildChecksumQueryVariables>(ApplicationBuildChecksumDocument, {}, options);
}
export function useApplicationBuildChecksumLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.ApplicationBuildChecksumQuery, Types.ApplicationBuildChecksumQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.ApplicationBuildChecksumQuery, Types.ApplicationBuildChecksumQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.ApplicationBuildChecksumQuery, Types.ApplicationBuildChecksumQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.ApplicationBuildChecksumQuery, Types.ApplicationBuildChecksumQueryVariables>(ApplicationBuildChecksumDocument, {}, options);
}
export type ApplicationBuildChecksumQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.ApplicationBuildChecksumQuery, Types.ApplicationBuildChecksumQueryVariables>;