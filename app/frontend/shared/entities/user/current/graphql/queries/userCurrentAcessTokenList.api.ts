import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { TokenAttributesFragmentDoc } from '../fragments/tokenAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentAccessTokenListDocument = gql`
    query userCurrentAccessTokenList {
  userCurrentAccessTokenList {
    ...tokenAttributes
  }
}
    ${TokenAttributesFragmentDoc}`;
export function useUserCurrentAccessTokenListQuery(options: VueApolloComposable.UseQueryOptions<Types.UserCurrentAccessTokenListQuery, Types.UserCurrentAccessTokenListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentAccessTokenListQuery, Types.UserCurrentAccessTokenListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentAccessTokenListQuery, Types.UserCurrentAccessTokenListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentAccessTokenListQuery, Types.UserCurrentAccessTokenListQueryVariables>(UserCurrentAccessTokenListDocument, {}, options);
}
export function useUserCurrentAccessTokenListLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.UserCurrentAccessTokenListQuery, Types.UserCurrentAccessTokenListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentAccessTokenListQuery, Types.UserCurrentAccessTokenListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentAccessTokenListQuery, Types.UserCurrentAccessTokenListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentAccessTokenListQuery, Types.UserCurrentAccessTokenListQueryVariables>(UserCurrentAccessTokenListDocument, {}, options);
}
export type UserCurrentAccessTokenListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserCurrentAccessTokenListQuery, Types.UserCurrentAccessTokenListQueryVariables>;