import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const SearchTaskbarItemStateUpdatesDocument = gql`
    subscription searchTaskbarItemStateUpdates($taskbarItemId: ID!) {
  userCurrentTaskbarItemStateUpdates(taskbarItemId: $taskbarItemId) {
    stateUpdateType
    taskbarItem {
      __typename
      id
      entity {
        __typename
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
export function useSearchTaskbarItemStateUpdatesSubscription(options: VueApolloComposable.useSubscription.Options<Types.SearchTaskbarItemStateUpdatesSubscription, Types.SearchTaskbarItemStateUpdatesSubscriptionVariables>) {
  return VueApolloComposable.useSubscription<Types.SearchTaskbarItemStateUpdatesSubscription, Types.SearchTaskbarItemStateUpdatesSubscriptionVariables>(SearchTaskbarItemStateUpdatesDocument, options);
}
export type SearchTaskbarItemStateUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.useSubscription.Result<Types.SearchTaskbarItemStateUpdatesSubscription, Types.SearchTaskbarItemStateUpdatesSubscriptionVariables>;