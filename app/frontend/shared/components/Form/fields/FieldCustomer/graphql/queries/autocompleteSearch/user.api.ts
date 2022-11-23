import * as Types from '../../../../../../../graphql/types';

import gql from 'graphql-tag';
import { UserAttributesFragmentDoc } from '../../../../../../../graphql/fragments/userAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AutocompleteSearchUserDocument = gql`
    query autocompleteSearchUser($input: AutocompleteSearchInput!) {
  autocompleteSearchUser(input: $input) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
    disabled
    icon
    user {
      ...userAttributes
    }
  }
}
    ${UserAttributesFragmentDoc}`;
export function useAutocompleteSearchUserQuery(variables: Types.AutocompleteSearchUserQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchUserQueryVariables> | ReactiveFunction<Types.AutocompleteSearchUserQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables>(AutocompleteSearchUserDocument, variables, options);
}
export function useAutocompleteSearchUserLazyQuery(variables: Types.AutocompleteSearchUserQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchUserQueryVariables> | ReactiveFunction<Types.AutocompleteSearchUserQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables>(AutocompleteSearchUserDocument, variables, options);
}
export type AutocompleteSearchUserQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AutocompleteSearchUserQuery, Types.AutocompleteSearchUserQueryVariables>;