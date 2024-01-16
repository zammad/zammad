import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { SessionFragmentDoc } from '../fragments/session.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const SessionDocument = gql`
    query session {
  session {
    ...session
  }
}
    ${SessionFragmentDoc}`;
export function useSessionQuery(options: VueApolloComposable.UseQueryOptions<Types.SessionQuery, Types.SessionQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.SessionQuery, Types.SessionQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.SessionQuery, Types.SessionQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.SessionQuery, Types.SessionQueryVariables>(SessionDocument, {}, options);
}
export function useSessionLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.SessionQuery, Types.SessionQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.SessionQuery, Types.SessionQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.SessionQuery, Types.SessionQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.SessionQuery, Types.SessionQueryVariables>(SessionDocument, {}, options);
}
export type SessionQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.SessionQuery, Types.SessionQueryVariables>;