import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';

export const FormUploadCacheAddDocument = gql`
    mutation formUploadCacheAdd($formId: FormId!, $files: [UploadCacheFileInput!]!) {
  formUploadCacheAdd(formId: $formId, files: $files) {
    uploadedFiles {
      id
      name
      size
      type
    }
  }
}
    `;
export function useFormUploadCacheAddMutation(options: VueApolloComposable.useMutation.Options<Types.FormUploadCacheAddMutation, Types.FormUploadCacheAddMutationVariables> = {}) {
  return VueApolloComposable.useMutation<Types.FormUploadCacheAddMutation, Types.FormUploadCacheAddMutationVariables>(FormUploadCacheAddDocument, options);
}
export type FormUploadCacheAddMutationCompositionFunctionResult = VueApolloComposable.useMutation.Result<Types.FormUploadCacheAddMutation, Types.FormUploadCacheAddMutationVariables>;