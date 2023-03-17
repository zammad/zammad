import * as Types from '../../../../../../../graphql/types';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const FormUploadCacheRemoveDocument = gql`
    mutation formUploadCacheRemove($formId: FormId!, $fileIds: [ID!]!) {
  formUploadCacheRemove(formId: $formId, fileIds: $fileIds) {
    success
  }
}
    `;
export function useFormUploadCacheRemoveMutation(options: VueApolloComposable.UseMutationOptions<Types.FormUploadCacheRemoveMutation, Types.FormUploadCacheRemoveMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.FormUploadCacheRemoveMutation, Types.FormUploadCacheRemoveMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.FormUploadCacheRemoveMutation, Types.FormUploadCacheRemoveMutationVariables>(FormUploadCacheRemoveDocument, options);
}
export type FormUploadCacheRemoveMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.FormUploadCacheRemoveMutation, Types.FormUploadCacheRemoveMutationVariables>;