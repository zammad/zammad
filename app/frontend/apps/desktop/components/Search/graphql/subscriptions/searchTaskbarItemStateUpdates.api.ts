import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const SearchTaskbarItemStateUpdatesDocument = gql`
    subscription searchTaskbarItemStateUpdates($taskbarItemId: ID!) {
  userCurrentTaskbarItemStateUpdates(taskbarItemId: $taskbarItemId) {
    stateUpdateType
    taskbarItem {
      id
      entity {
        ... on UserTaskbarItemEntitySearch {
          query
          model
          filters
          filterCount
        }
      }
    }
  }
}
    `;
export function useSearchTaskbarItemStateUpdatesSubscription(variables: Types.SearchTaskbarItemStateUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.SearchTaskbarItemStateUpdatesSubscriptionVariables> | ReactiveFunction<Types.SearchTaskbarItemStateUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.SearchTaskbarItemStateUpdatesSubscription, Types.SearchTaskbarItemStateUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.SearchTaskbarItemStateUpdatesSubscription, Types.SearchTaskbarItemStateUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.SearchTaskbarItemStateUpdatesSubscription, Types.SearchTaskbarItemStateUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.SearchTaskbarItemStateUpdatesSubscription, Types.SearchTaskbarItemStateUpdatesSubscriptionVariables>(SearchTaskbarItemStateUpdatesDocument, variables, options);
}
export type SearchTaskbarItemStateUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.SearchTaskbarItemStateUpdatesSubscription, Types.SearchTaskbarItemStateUpdatesSubscriptionVariables>;