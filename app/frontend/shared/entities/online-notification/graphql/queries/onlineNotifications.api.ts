import * as Types from '../../../../graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const OnlineNotificationsDocument = gql`
    query onlineNotifications {
  onlineNotifications {
    edges {
      node {
        id
        seen
        createdAt
        createdBy {
          id
          fullname
          lastname
          firstname
          email
          vip
          outOfOffice
          active
          image
        }
        typeName
        objectName
        objectId
        metaObject {
          ... on Ticket {
            id
            internalId
            title
          }
        }
      }
      cursor
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
    `;
export function useOnlineNotificationsQuery(options: VueApolloComposable.UseQueryOptions<Types.OnlineNotificationsQuery, Types.OnlineNotificationsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.OnlineNotificationsQuery, Types.OnlineNotificationsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.OnlineNotificationsQuery, Types.OnlineNotificationsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.OnlineNotificationsQuery, Types.OnlineNotificationsQueryVariables>(OnlineNotificationsDocument, {}, options);
}
export function useOnlineNotificationsLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.OnlineNotificationsQuery, Types.OnlineNotificationsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.OnlineNotificationsQuery, Types.OnlineNotificationsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.OnlineNotificationsQuery, Types.OnlineNotificationsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.OnlineNotificationsQuery, Types.OnlineNotificationsQueryVariables>(OnlineNotificationsDocument, {}, options);
}
export type OnlineNotificationsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.OnlineNotificationsQuery, Types.OnlineNotificationsQueryVariables>;