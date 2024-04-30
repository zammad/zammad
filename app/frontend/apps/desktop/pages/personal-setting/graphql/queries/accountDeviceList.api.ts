import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserDeviceAttributesFragmentDoc } from '../fragments/userDeviceAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AccountDeviceListDocument = gql`
    query accountDeviceList {
  accountDeviceList {
    ...userDeviceAttributes
  }
}
    ${UserDeviceAttributesFragmentDoc}`;
export function useAccountDeviceListQuery(options: VueApolloComposable.UseQueryOptions<Types.AccountDeviceListQuery, Types.AccountDeviceListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AccountDeviceListQuery, Types.AccountDeviceListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AccountDeviceListQuery, Types.AccountDeviceListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AccountDeviceListQuery, Types.AccountDeviceListQueryVariables>(AccountDeviceListDocument, {}, options);
}
export function useAccountDeviceListLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.AccountDeviceListQuery, Types.AccountDeviceListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AccountDeviceListQuery, Types.AccountDeviceListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AccountDeviceListQuery, Types.AccountDeviceListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AccountDeviceListQuery, Types.AccountDeviceListQueryVariables>(AccountDeviceListDocument, {}, options);
}
export type AccountDeviceListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AccountDeviceListQuery, Types.AccountDeviceListQueryVariables>;