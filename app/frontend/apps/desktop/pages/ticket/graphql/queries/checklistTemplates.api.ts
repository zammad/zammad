import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const ChecklistTemplatesDocument = gql`
    query checklistTemplates($onlyActive: Boolean = false) {
  checklistTemplates(onlyActive: $onlyActive) {
    id
    name
    active
  }
}
    `;
export function useChecklistTemplatesQuery(options: VueApolloComposable.useQuery.Options<Types.ChecklistTemplatesQuery, Types.ChecklistTemplatesQueryVariables> = {}) {
  return VueApolloComposable.useQuery<Types.ChecklistTemplatesQuery, Types.ChecklistTemplatesQueryVariables>(ChecklistTemplatesDocument, options);
}
export function useChecklistTemplatesLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.ChecklistTemplatesQuery, Types.ChecklistTemplatesQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.ChecklistTemplatesQuery, Types.ChecklistTemplatesQueryVariables>(ChecklistTemplatesDocument, options);
}
export type ChecklistTemplatesQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.ChecklistTemplatesQuery, Types.ChecklistTemplatesQueryVariables>;