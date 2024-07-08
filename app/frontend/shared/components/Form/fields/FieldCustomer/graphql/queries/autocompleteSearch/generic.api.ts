import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

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
export function useAutocompleteSearchGenericQuery(variables: Types.AutocompleteSearchGenericQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchGenericQueryVariables> | ReactiveFunction<Types.AutocompleteSearchGenericQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables>(AutocompleteSearchGenericDocument, variables, options);
}
export function useAutocompleteSearchGenericLazyQuery(variables?: Types.AutocompleteSearchGenericQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchGenericQueryVariables> | ReactiveFunction<Types.AutocompleteSearchGenericQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables>(AutocompleteSearchGenericDocument, variables, options);
}
export type AutocompleteSearchGenericQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AutocompleteSearchGenericQuery, Types.AutocompleteSearchGenericQueryVariables>;