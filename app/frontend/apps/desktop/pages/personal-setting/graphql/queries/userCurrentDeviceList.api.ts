import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserDeviceAttributesFragmentDoc } from '../fragments/userDeviceAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentDeviceListDocument = gql`
    query userCurrentDeviceList {
  userCurrentDeviceList {
    ...userDeviceAttributes
  }
}
    ${UserDeviceAttributesFragmentDoc}`;
export function useUserCurrentDeviceListQuery(options: VueApolloComposable.UseQueryOptions<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables>(UserCurrentDeviceListDocument, {}, options);
}
export function useUserCurrentDeviceListLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables>(UserCurrentDeviceListDocument, {}, options);
}
export type UserCurrentDeviceListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables>;