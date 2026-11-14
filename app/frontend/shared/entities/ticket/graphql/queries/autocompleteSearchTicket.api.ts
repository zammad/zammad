import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

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
export function useAutocompleteSearchTicketQuery(options: VueApolloComposable.useQuery.Options<Types.AutocompleteSearchTicketQuery, Types.AutocompleteSearchTicketQueryVariables>) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchTicketQuery, Types.AutocompleteSearchTicketQueryVariables>(AutocompleteSearchTicketDocument, options);
}
export function useAutocompleteSearchTicketLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.AutocompleteSearchTicketQuery, Types.AutocompleteSearchTicketQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchTicketQuery, Types.AutocompleteSearchTicketQueryVariables>(AutocompleteSearchTicketDocument, options);
}
export type AutocompleteSearchTicketQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.AutocompleteSearchTicketQuery, Types.AutocompleteSearchTicketQueryVariables>;