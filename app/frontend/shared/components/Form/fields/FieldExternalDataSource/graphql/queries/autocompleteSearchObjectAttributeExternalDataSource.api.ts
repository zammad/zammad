import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const AutocompleteSearchObjectAttributeExternalDataSourceDocument = gql`
    query autocompleteSearchObjectAttributeExternalDataSource($input: AutocompleteSearchObjectAttributeExternalDataSourceInput!) {
  autocompleteSearchObjectAttributeExternalDataSource(input: $input) {
    value
    label
    labelPlaceholder
    heading
    headingPlaceholder
  }
}
    `;
export function useAutocompleteSearchObjectAttributeExternalDataSourceQuery(options: VueApolloComposable.useQuery.Options<Types.AutocompleteSearchObjectAttributeExternalDataSourceQuery, Types.AutocompleteSearchObjectAttributeExternalDataSourceQueryVariables>) {
  return VueApolloComposable.useQuery<Types.AutocompleteSearchObjectAttributeExternalDataSourceQuery, Types.AutocompleteSearchObjectAttributeExternalDataSourceQueryVariables>(AutocompleteSearchObjectAttributeExternalDataSourceDocument, options);
}
export function useAutocompleteSearchObjectAttributeExternalDataSourceLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.AutocompleteSearchObjectAttributeExternalDataSourceQuery, Types.AutocompleteSearchObjectAttributeExternalDataSourceQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.AutocompleteSearchObjectAttributeExternalDataSourceQuery, Types.AutocompleteSearchObjectAttributeExternalDataSourceQueryVariables>(AutocompleteSearchObjectAttributeExternalDataSourceDocument, options);
}
export type AutocompleteSearchObjectAttributeExternalDataSourceQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.AutocompleteSearchObjectAttributeExternalDataSourceQuery, Types.AutocompleteSearchObjectAttributeExternalDataSourceQueryVariables>;