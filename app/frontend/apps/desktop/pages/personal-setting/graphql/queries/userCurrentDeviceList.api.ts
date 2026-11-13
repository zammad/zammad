import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserDeviceAttributesFragmentDoc } from '../fragments/userDeviceAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentDeviceListDocument = gql`
    query userCurrentDeviceList {
  userCurrentDeviceList {
    ...userDeviceAttributes
  }
}
    ${UserDeviceAttributesFragmentDoc}`;
export function useUserCurrentDeviceListQuery(options: VueApolloComposable.useQuery.Options<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables>(UserCurrentDeviceListDocument, options);
}
export function useUserCurrentDeviceListLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables>(UserCurrentDeviceListDocument, options);
}
export type UserCurrentDeviceListQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserCurrentDeviceListQuery, Types.UserCurrentDeviceListQueryVariables>;