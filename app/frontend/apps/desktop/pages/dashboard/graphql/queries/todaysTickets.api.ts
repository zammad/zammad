import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const TodaysTicketsDocument = gql`
    query todaysTickets {
  todaysTickets {
    id
    number
    title
    stateColorCode
    state {
      id
      name
    }
    priority {
      id
      name
      uiColor
    }
    customer {
      id
      fullname
      email
    }
    owner {
      id
      fullname
    }
    group {
      id
      name
    }
    createdAt
    updatedAt
  }
}
    `;
export function useTodaysTicketsQuery(options: VueApolloComposable.UseQueryOptions<Types.TodaysTicketsQuery, Types.TodaysTicketsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TodaysTicketsQuery, Types.TodaysTicketsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TodaysTicketsQuery, Types.TodaysTicketsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.TodaysTicketsQuery, Types.TodaysTicketsQueryVariables>(TodaysTicketsDocument, {}, options);
}
export function useTodaysTicketsLazyQuery(options: VueApolloComposable.UseQueryOptions<Types.TodaysTicketsQuery, Types.TodaysTicketsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.TodaysTicketsQuery, Types.TodaysTicketsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.TodaysTicketsQuery, Types.TodaysTicketsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.TodaysTicketsQuery, Types.TodaysTicketsQueryVariables>(TodaysTicketsDocument, {}, options);
}
export type TodaysTicketsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.TodaysTicketsQuery, Types.TodaysTicketsQueryVariables>;