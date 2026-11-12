import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const AutocompleteSearchGenericDocument = gql`
    query autocompleteSearchGeneric($input: AutocompleteSearchGenericInput!, $membersCount: Int = 10) {
  autocompleteSearchGeneric(input: $input) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
    disabled
    object {
      __typename
      ... on User {
        id
        internalId
        login
        image
        firstname
        lastname
        fullname
        email
        phone
        outOfOffice
        outOfOfficeStartAt
        outOfOfficeEndAt
        active
        vip
        organization {
          __typename
          id
          internalId
          name
          active
          vip
          ticketsCount {
            open
            closed
          }
        }
        hasSecondaryOrganizations
      }
      ... on Organization {
        id
        internalId
        name
        active
        vip
        allMembers(first: $membersCount) {
          edges {
            node {
              __typename
              id
              internalId
              login
              image
              firstname
              lastname
              fullname
              email
              phone
              outOfOffice
              outOfOfficeStartAt
              outOfOfficeEndAt
              active
              vip
              hasSecondaryOrganizations
            }
          }
        }
      }
    }
  }
}
    `;
export function useAutocompleteSearchGenericQuery(options: VueApolloComposable.useQuery.Options<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables>) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables>(AutocompleteSearchGenericDocument, options);
}
export function useAutocompleteSearchGenericLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables>(AutocompleteSearchGenericDocument, options);
}
export type AutocompleteSearchGenericQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables>;