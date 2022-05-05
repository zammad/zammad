import * as Types from '../types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const ApplicationConfigDocument = gql`
    query applicationConfig {
  applicationConfig {
    key
    value
  }
}
    `;
export function useApplicationConfigQuery(options: VueApolloComposable.UseQueryOptions<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>(ApplicationConfigDocument, {}, options);
}
export function useApplicationConfigLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>(ApplicationConfigDocument, {}, options);
}
export type ApplicationConfigQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.ApplicationConfigQuery, Types.ApplicationConfigQueryVariables>;