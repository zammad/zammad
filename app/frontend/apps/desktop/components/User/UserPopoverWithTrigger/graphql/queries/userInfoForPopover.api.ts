import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserDetailAttributesFragmentDoc } from '../../../../../../../shared/graphql/fragments/userDetailAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserInfoForPopoverDocument = gql`
    query userInfoForPopover($userId: ID!, $secondaryOrganizationsCount: Int) {
  user(userId: $userId) {
    ...userDetailAttributes
  }
}
    ${UserDetailAttributesFragmentDoc}`;
export function useUserInfoForPopoverQuery(variables: Types.UserInfoForPopoverQueryVariables | VueCompositionApi.Ref<Types.UserInfoForPopoverQueryVariables> | ReactiveFunction<Types.UserInfoForPopoverQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.UserInfoForPopoverQuery, Types.UserInfoForPopoverQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserInfoForPopoverQuery, Types.UserInfoForPopoverQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserInfoForPopoverQuery, Types.UserInfoForPopoverQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserInfoForPopoverQuery, Types.UserInfoForPopoverQueryVariables>(UserInfoForPopoverDocument, variables, options);
}
export function useUserInfoForPopoverLazyQuery(variables?: Types.UserInfoForPopoverQueryVariables | VueCompositionApi.Ref<Types.UserInfoForPopoverQueryVariables> | ReactiveFunction<Types.UserInfoForPopoverQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.UserInfoForPopoverQuery, Types.UserInfoForPopoverQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserInfoForPopoverQuery, Types.UserInfoForPopoverQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserInfoForPopoverQuery, Types.UserInfoForPopoverQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserInfoForPopoverQuery, Types.UserInfoForPopoverQueryVariables>(UserInfoForPopoverDocument, variables, options);
}
export type UserInfoForPopoverQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserInfoForPopoverQuery, Types.UserInfoForPopoverQueryVariables>;