import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import { UserDetailAttributesFragmentDoc } from '../../../../../../shared/graphql/fragments/userDetailAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserDocument = gql`
    query user($userId: ID, $userInternalId: Int, $secondaryOrganizationsCount: Int) {
  user(user: {userId: $userId, userInternalId: $userInternalId}) {
    ...userDetailAttributes
    secondaryOrganizations(first: $secondaryOrganizationsCount) {
      edges {
        node {
          id
          internalId
          active
          name
        }
      }
      totalCount
    }
    policy {
      update
    }
  }
}
    ${UserDetailAttributesFragmentDoc}`;
export function useUserQuery(variables: Types.UserQueryVariables | VueCompositionApi.Ref<Types.UserQueryVariables> | ReactiveFunction<Types.UserQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.UserQuery, Types.UserQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserQuery, Types.UserQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserQuery, Types.UserQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserQuery, Types.UserQueryVariables>(UserDocument, variables, options);
}
export function useUserLazyQuery(variables: Types.UserQueryVariables | VueCompositionApi.Ref<Types.UserQueryVariables> | ReactiveFunction<Types.UserQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.UserQuery, Types.UserQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserQuery, Types.UserQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserQuery, Types.UserQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserQuery, Types.UserQueryVariables>(UserDocument, variables, options);
}
export type UserQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserQuery, Types.UserQueryVariables>;