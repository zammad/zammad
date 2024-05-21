import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserCalendarSubscriptionAttributesFragmentDoc } from '../fragments/userCalendarSubscriptionAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const UserCurrentCalendarSubscriptionListDocument = gql`
    query userCurrentCalendarSubscriptionList {
  userCurrentCalendarSubscriptionList {
    ...userCalendarSubscriptionAttributes
  }
}
    ${UserCalendarSubscriptionAttributesFragmentDoc}`;
export function useUserCurrentCalendarSubscriptionListQuery(options: VueApolloComposable.UseQueryOptions<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables>(UserCurrentCalendarSubscriptionListDocument, {}, options);
}
export function useUserCurrentCalendarSubscriptionListLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables>(UserCurrentCalendarSubscriptionListDocument, {}, options);
}
export type UserCurrentCalendarSubscriptionListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables>;