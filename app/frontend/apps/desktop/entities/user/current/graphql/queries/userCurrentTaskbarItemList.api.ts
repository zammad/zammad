import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserCurrentTaskbarItemAttributesFragmentDoc } from '../fragments/userCurrentTaskbarItemAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentTaskbarItemListDocument = gql`
    query userCurrentTaskbarItemList($app: EnumTaskbarApp!) {
  userCurrentTaskbarItemList(app: $app) {
    ...userCurrentTaskbarItemAttributes
  }
}
    ${UserCurrentTaskbarItemAttributesFragmentDoc}`;
export function useUserCurrentTaskbarItemListQuery(variables: Types.UserCurrentTaskbarItemListQueryVariables | VueCompositionApi.Ref<Types.UserCurrentTaskbarItemListQueryVariables> | ReactiveFunction<Types.UserCurrentTaskbarItemListQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables>(UserCurrentTaskbarItemListDocument, variables, options);
}
export function useUserCurrentTaskbarItemListLazyQuery(variables?: Types.UserCurrentTaskbarItemListQueryVariables | VueCompositionApi.Ref<Types.UserCurrentTaskbarItemListQueryVariables> | ReactiveFunction<Types.UserCurrentTaskbarItemListQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables>(UserCurrentTaskbarItemListDocument, variables, options);
}
export type UserCurrentTaskbarItemListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserCurrentTaskbarItemListQuery, Types.UserCurrentTaskbarItemListQueryVariables>;