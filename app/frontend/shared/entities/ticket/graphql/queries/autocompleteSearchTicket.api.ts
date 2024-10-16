import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AutocompleteSearchTicketDocument = gql`
    query autocompleteSearchTicket($input: AutocompleteSearchTicketInput!) {
  autocompleteSearchTicket(input: $input) {
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
      stateColorCode
    }
  }
}
    `;
export function useAutocompleteSearchTicketQuery(variables: Types.AutocompleteSearchTicketQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchTicketQueryVariables> | ReactiveFunction<Types.AutocompleteSearchTicketQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchTicketQuery, Types.AutocompleteSearchTicketQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchTicketQuery, Types.AutocompleteSearchTicketQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchTicketQuery, Types.AutocompleteSearchTicketQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchTicketQuery, Types.AutocompleteSearchTicketQueryVariables>(AutocompleteSearchTicketDocument, variables, options);
}
export function useAutocompleteSearchTicketLazyQuery(variables?: Types.AutocompleteSearchTicketQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchTicketQueryVariables> | ReactiveFunction<Types.AutocompleteSearchTicketQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchTicketQuery, Types.AutocompleteSearchTicketQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchTicketQuery, Types.AutocompleteSearchTicketQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchTicketQuery, Types.AutocompleteSearchTicketQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchTicketQuery, Types.AutocompleteSearchTicketQueryVariables>(AutocompleteSearchTicketDocument, variables, options);
}
export type AutocompleteSearchTicketQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AutocompleteSearchTicketQuery, Types.AutocompleteSearchTicketQueryVariables>;