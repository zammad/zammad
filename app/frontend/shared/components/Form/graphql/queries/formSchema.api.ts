import * as Types from '../../../../graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const FormSchemaDocument = gql`
    query formSchema($formSchemaId: EnumFormSchemaId!) {
  formSchema(formSchemaId: $formSchemaId)
}
    `;
export function useFormSchemaQuery(variables: Types.FormSchemaQueryVariables | VueCompositionApi.Ref<Types.FormSchemaQueryVariables> | ReactiveFunction<Types.FormSchemaQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.FormSchemaQuery, Types.FormSchemaQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.FormSchemaQuery, Types.FormSchemaQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.FormSchemaQuery, Types.FormSchemaQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.FormSchemaQuery, Types.FormSchemaQueryVariables>(FormSchemaDocument, variables, options);
}
export function useFormSchemaLazyQuery(variables: Types.FormSchemaQueryVariables | VueCompositionApi.Ref<Types.FormSchemaQueryVariables> | ReactiveFunction<Types.FormSchemaQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.FormSchemaQuery, Types.FormSchemaQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.FormSchemaQuery, Types.FormSchemaQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.FormSchemaQuery, Types.FormSchemaQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.FormSchemaQuery, Types.FormSchemaQueryVariables>(FormSchemaDocument, variables, options);
}
export type FormSchemaQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.FormSchemaQuery, Types.FormSchemaQueryVariables>;