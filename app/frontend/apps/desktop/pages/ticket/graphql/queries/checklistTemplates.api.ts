import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const ChecklistTemplatesDocument = gql`
    query checklistTemplates($onlyActive: Boolean = false) {
  checklistTemplates(onlyActive: $onlyActive) {
    id
    name
    active
  }
}
    `;
export function useChecklistTemplatesQuery(variables: Types.ChecklistTemplatesQueryVariables | VueCompositionApi.Ref<Types.ChecklistTemplatesQueryVariables> | ReactiveFunction<Types.ChecklistTemplatesQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.ChecklistTemplatesQuery, Types.ChecklistTemplatesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.ChecklistTemplatesQuery, Types.ChecklistTemplatesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.ChecklistTemplatesQuery, Types.ChecklistTemplatesQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.ChecklistTemplatesQuery, Types.ChecklistTemplatesQueryVariables>(ChecklistTemplatesDocument, variables, options);
}
export function useChecklistTemplatesLazyQuery(variables: Types.ChecklistTemplatesQueryVariables | VueCompositionApi.Ref<Types.ChecklistTemplatesQueryVariables> | ReactiveFunction<Types.ChecklistTemplatesQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.ChecklistTemplatesQuery, Types.ChecklistTemplatesQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.ChecklistTemplatesQuery, Types.ChecklistTemplatesQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.ChecklistTemplatesQuery, Types.ChecklistTemplatesQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.ChecklistTemplatesQuery, Types.ChecklistTemplatesQueryVariables>(ChecklistTemplatesDocument, variables, options);
}
export type ChecklistTemplatesQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.ChecklistTemplatesQuery, Types.ChecklistTemplatesQueryVariables>;