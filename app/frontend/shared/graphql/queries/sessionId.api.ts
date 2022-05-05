import * as Types from '../types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const SessionIdDocument = gql`
    query sessionId {
  sessionId
}
    `;
export function useSessionIdQuery(options: VueApolloComposable.UseQueryOptions<Types.SessionIdQuery, Types.SessionIdQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.SessionIdQuery, Types.SessionIdQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.SessionIdQuery, Types.SessionIdQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.SessionIdQuery, Types.SessionIdQueryVariables>(SessionIdDocument, {}, options);
}
export function useSessionIdLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.SessionIdQuery, Types.SessionIdQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.SessionIdQuery, Types.SessionIdQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.SessionIdQuery, Types.SessionIdQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.SessionIdQuery, Types.SessionIdQueryVariables>(SessionIdDocument, {}, options);
}
export type SessionIdQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.SessionIdQuery, Types.SessionIdQueryVariables>;