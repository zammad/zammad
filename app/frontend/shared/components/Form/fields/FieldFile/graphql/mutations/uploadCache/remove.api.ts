import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const FormUploadCacheRemoveDocument = gql`
    mutation formUploadCacheRemove($formId: FormId!, $fileIds: [ID!]!) {
  formUploadCacheRemove(formId: $formId, fileIds: $fileIds) {
    success
  }
}
    `;
export function useFormUploadCacheRemoveMutation(options: VueApolloComposable.useMutation.Options<Types.FormUploadCacheRemoveMutation, Types.FormUploadCacheRemoveMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.FormUploadCacheRemoveMutation, Types.FormUploadCacheRemoveMutationVariables>(FormUploadCacheRemoveDocument, options);
}
export type FormUploadCacheRemoveMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.FormUploadCacheRemoveMutation, Types.FormUploadCacheRemoveMutationVariables>;