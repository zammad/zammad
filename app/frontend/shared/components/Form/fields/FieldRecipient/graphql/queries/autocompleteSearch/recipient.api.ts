import * as Types from '../../../../../../../graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AutocompleteSearchRecipientDocument = gql`
    query autocompleteSearchRecipient($input: AutocompleteSearchRecipientInput!) {
  autocompleteSearchRecipient(input: $input) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
    disabled
    icon
  }
}
    `;
export function useAutocompleteSearchRecipientQuery(variables: Types.AutocompleteSearchRecipientQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchRecipientQueryVariables> | ReactiveFunction<Types.AutocompleteSearchRecipientQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchRecipientQuery, Types.AutocompleteSearchRecipientQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchRecipientQuery, Types.AutocompleteSearchRecipientQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchRecipientQuery, Types.AutocompleteSearchRecipientQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchRecipientQuery, Types.AutocompleteSearchRecipientQueryVariables>(AutocompleteSearchRecipientDocument, variables, options);
}
export function useAutocompleteSearchRecipientLazyQuery(variables: Types.AutocompleteSearchRecipientQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchRecipientQueryVariables> | ReactiveFunction<Types.AutocompleteSearchRecipientQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchRecipientQuery, Types.AutocompleteSearchRecipientQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchRecipientQuery, Types.AutocompleteSearchRecipientQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchRecipientQuery, Types.AutocompleteSearchRecipientQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchRecipientQuery, Types.AutocompleteSearchRecipientQueryVariables>(AutocompleteSearchRecipientDocument, variables, options);
}
export type AutocompleteSearchRecipientQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AutocompleteSearchRecipientQuery, Types.AutocompleteSearchRecipientQueryVariables>;