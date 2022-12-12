import * as Types from '../../../../../../shared/graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AutocompleteSearchMergeTicketDocument = gql`
    query autocompleteSearchMergeTicket($input: AutocompleteSearchMergeTicketInput!) {
  autocompleteSearchMergeTicket(input: $input) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
    disabled
    icon
    ticket {
      id
      number
      internalId
      state {
        id
        name
      }
    }
  }
}
    `;
export function useAutocompleteSearchMergeTicketQuery(variables: Types.AutocompleteSearchMergeTicketQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchMergeTicketQueryVariables> | ReactiveFunction<Types.AutocompleteSearchMergeTicketQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchMergeTicketQuery, Types.AutocompleteSearchMergeTicketQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchMergeTicketQuery, Types.AutocompleteSearchMergeTicketQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchMergeTicketQuery, Types.AutocompleteSearchMergeTicketQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchMergeTicketQuery, Types.AutocompleteSearchMergeTicketQueryVariables>(AutocompleteSearchMergeTicketDocument, variables, options);
}
export function useAutocompleteSearchMergeTicketLazyQuery(variables: Types.AutocompleteSearchMergeTicketQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchMergeTicketQueryVariables> | ReactiveFunction<Types.AutocompleteSearchMergeTicketQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchMergeTicketQuery, Types.AutocompleteSearchMergeTicketQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchMergeTicketQuery, Types.AutocompleteSearchMergeTicketQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchMergeTicketQuery, Types.AutocompleteSearchMergeTicketQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchMergeTicketQuery, Types.AutocompleteSearchMergeTicketQueryVariables>(AutocompleteSearchMergeTicketDocument, variables, options);
}
export type AutocompleteSearchMergeTicketQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AutocompleteSearchMergeTicketQuery, Types.AutocompleteSearchMergeTicketQueryVariables>;