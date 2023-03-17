import * as Types from '../../../../../../../graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const FormUploadCacheAddDocument = gql`
    mutation formUploadCacheAdd($formId: FormId!, $files: [UploadFileInput!]!) {
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
export function useFormUploadCacheAddMutation(options: VueApolloComposable.UseMutationOptions<Types.FormUploadCacheAddMutation, Types.FormUploadCacheAddMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.FormUploadCacheAddMutation, Types.FormUploadCacheAddMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.FormUploadCacheAddMutation, Types.FormUploadCacheAddMutationVariables>(FormUploadCacheAddDocument, options);
}
export type FormUploadCacheAddMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.FormUploadCacheAddMutation, Types.FormUploadCacheAddMutationVariables>;