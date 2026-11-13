import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const TemplatesDocument = gql`
    query templates($onlyActive: Boolean = false) {
  templates(onlyActive: $onlyActive) {
    id
    name
  }
}
    `;
export function useTemplatesQuery(options: VueApolloComposable.useQuery.Options<Types.TemplatesQuery, Types.TemplatesQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.TemplatesQuery, Types.TemplatesQueryVariables>(TemplatesDocument, options);
}
export function useTemplatesLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.TemplatesQuery, Types.TemplatesQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.TemplatesQuery, Types.TemplatesQueryVariables>(TemplatesDocument, options);
}
export type TemplatesQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.TemplatesQuery, Types.TemplatesQueryVariables>;