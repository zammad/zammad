import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserCalendarSubscriptionAttributesFragmentDoc } from '../fragments/userCalendarSubscriptionAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';

export const UserCurrentCalendarSubscriptionListDocument = gql`
    query userCurrentCalendarSubscriptionList {
  userCurrentCalendarSubscriptionList {
    ...userCalendarSubscriptionAttributes
  }
}
    ${UserCalendarSubscriptionAttributesFragmentDoc}`;
export function useUserCurrentCalendarSubscriptionListQuery(options: VueApolloComposable.useQuery.Options<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables>(UserCurrentCalendarSubscriptionListDocument, options);
}
export function useUserCurrentCalendarSubscriptionListLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables>(UserCurrentCalendarSubscriptionListDocument, options);
}
export type UserCurrentCalendarSubscriptionListQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.UserCurrentCalendarSubscriptionListQuery, Types.UserCurrentCalendarSubscriptionListQueryVariables>;