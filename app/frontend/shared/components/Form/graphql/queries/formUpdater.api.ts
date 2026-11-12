import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const FormUpdaterDocument = gql`
    query formUpdater($formUpdaterId: EnumFormUpdaterId!, $meta: FormUpdaterMetaInput!, $data: JSON!, $relationFields: [FormUpdaterRelationField!]!, $id: ID) {
  formUpdater(
    formUpdaterId: $formUpdaterId
    meta: $meta
    data: $data
    relationFields: $relationFields
    id: $id
  ) {
    fields
    flags
  }
}
    `;
export function useFormUpdaterQuery(options: VueApolloComposable.useQuery.Options<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables>) {
  return VueApolloComposable.useQuery<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables>(FormUpdaterDocument, options);
}
export function useFormUpdaterLazyQuery(options?: VueApolloComposable.useLazyQuery.Options<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables>) {
  return VueApolloComposable.useLazyQuery<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables>(FormUpdaterDocument, options);
}
export type FormUpdaterQueryCompositionFunctionResult = VueApolloComposable.useQuery.Result<Types.FormUpdaterQuery, Types.FormUpdaterQueryVariables>;