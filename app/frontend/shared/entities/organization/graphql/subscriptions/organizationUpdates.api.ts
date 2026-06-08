import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { OrganizationAttributesFragmentDoc } from '../fragments/organizationAttributes.api';
import { OrganizationMembersWithFetchMoreFragmentDoc } from '../fragments/organizationMembersWithFetchMore.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const OrganizationUpdatesDocument = gql`
    subscription organizationUpdates($organizationId: ID!, $first: Int, $after: String) {
  organizationUpdates(organizationId: $organizationId) {
    organization {
      ...organizationAttributes
      ...organizationMembersWithFetchMore
      policy {
        update
      }
      ticketsCount {
        open
        closed
        openSearchQuery
        closedSearchQuery
      }
    }
  }
}
    ${OrganizationAttributesFragmentDoc}
${OrganizationMembersWithFetchMoreFragmentDoc}`;
export function useOrganizationUpdatesSubscription(variables: Types.OrganizationUpdatesSubscriptionVariables | VueCompositionApi.Ref<Types.OrganizationUpdatesSubscriptionVariables> | ReactiveFunction<Types.OrganizationUpdatesSubscriptionVariables>, options: VueApolloComposable.UseSubscriptionOptions<Types.OrganizationUpdatesSubscription, Types.OrganizationUpdatesSubscriptionVariables> | VueCompositionApi.Ref<VueApolloComposable.UseSubscriptionOptions<Types.OrganizationUpdatesSubscription, Types.OrganizationUpdatesSubscriptionVariables>> | ReactiveFunction<VueApolloComposable.UseSubscriptionOptions<Types.OrganizationUpdatesSubscription, Types.OrganizationUpdatesSubscriptionVariables>> = {}) {
  return VueApolloComposable.useSubscription<Types.OrganizationUpdatesSubscription, Types.OrganizationUpdatesSubscriptionVariables>(OrganizationUpdatesDocument, variables, options);
}
export type OrganizationUpdatesSubscriptionCompositionFunctionResult = VueApolloComposable.UseSubscriptionReturn<Types.OrganizationUpdatesSubscription, Types.OrganizationUpdatesSubscriptionVariables>;