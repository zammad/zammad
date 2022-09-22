import * as Types from '../../../../graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const FormUpdaterDocument = gql`
    query formUpdater($formUpdaterId: EnumFormUpdaterId!, $meta: FormUpdaterMetaInput!, $data: JSON!, $relationFields: [FormUpdaterRelationField!]!, $id: ID) {
  formUpdater(
    formUpdaterId: $formUpdaterId
    meta: $meta
    data: $data
    relationFields: $relationFields
    id: $id
  )
}
    `;
export function useFormUpdaterQuery(variables: Types.FormUpdaterQueryVariables | VueCompositionApi.Ref<Types.FormUpdaterQueryVariables> | ReactiveFunction<Types.FormUpdaterQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables>(FormUpdaterDocument, variables, options);
}
export function useFormUpdaterLazyQuery(variables: Types.FormUpdaterQueryVariables | VueCompositionApi.Ref<Types.FormUpdaterQueryVariables> | ReactiveFunction<Types.FormUpdaterQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables>(FormUpdaterDocument, variables, options);
}
export type FormUpdaterQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables>;