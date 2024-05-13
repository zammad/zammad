import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import { UserAttributesFragmentDoc } from '../../../../../../../graphql/fragments/userAttributes.api';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const AutocompleteSearchAgentDocument = gql`
    query autocompleteSearchAgent($input: AutocompleteSearchUserInput!) {
  autocompleteSearchAgent(input: $input) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
    disabled
    icon
    user {
      ...userAttributes
      vip
      outOfOffice
      outOfOfficeStartAt
      outOfOfficeEndAt
      active
    }
  }
}
    ${UserAttributesFragmentDoc}`;
export function useAutocompleteSearchAgentQuery(variables: Types.AutocompleteSearchAgentQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchAgentQueryVariables> | ReactiveFunction<Types.AutocompleteSearchAgentQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchAgentQuery, Types.AutocompleteSearchAgentQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchAgentQuery, Types.AutocompleteSearchAgentQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchAgentQuery, Types.AutocompleteSearchAgentQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchAgentQuery, Types.AutocompleteSearchAgentQueryVariables>(AutocompleteSearchAgentDocument, variables, options);
}
export function useAutocompleteSearchAgentLazyQuery(variables?: Types.AutocompleteSearchAgentQueryVariables | VueCompositionApi.Ref<Types.AutocompleteSearchAgentQueryVariables> | ReactiveFunction<Types.AutocompleteSearchAgentQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchAgentQuery, Types.AutocompleteSearchAgentQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchAgentQuery, Types.AutocompleteSearchAgentQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.AutocompleteSearchAgentQuery, Types.AutocompleteSearchAgentQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchAgentQuery, Types.AutocompleteSearchAgentQueryVariables>(AutocompleteSearchAgentDocument, variables, options);
}
export type AutocompleteSearchAgentQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.AutocompleteSearchAgentQuery, Types.AutocompleteSearchAgentQueryVariables>;