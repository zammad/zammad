<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import type { FormFieldContext } from '@shared/components/Form/types/field'
import type { Scalars, UploadedFile } from '@shared/graphql/types'
import { InputHTMLAttributes, ref, Ref } from 'vue'
import { useFormUploadCacheAddMutation } from '@shared/components/Form/fields/FieldFile/graphql/mutations/uploadCache/add.api'
import { useFormUploadCacheRemoveMutation } from '@shared/components/Form/fields/FieldFile/graphql/mutations/uploadCache/remove.api'
import { MutationHandler } from '@shared/server/apollo/handler'
import { convertFileList } from '@shared/utils/files'

// TODO: First proof of concept, this needs to be finalized during the first real usage.
// TODO: Add a test + story for this component.

export interface Props {
  context: FormFieldContext<{
    accept: InputHTMLAttributes['accept']
    capture: InputHTMLAttributes['capture']
    multiple: InputHTMLAttributes['multiple']
  }>
}

const props = defineProps<Props>()

const uploadFiles: Ref<UploadedFile[]> = ref([])

const addFileMutation = new MutationHandler(useFormUploadCacheAddMutation({}))
const addFileLoading = addFileMutation.loading()

const onFileChanged = async ($event: Event) => {
  const { files } = $event.target as HTMLInputElement
  const uploads = await convertFileList(files)

  addFileMutation
    .send({ formId: props.context.formId, files: uploads })
    .then((data) => {
      if (data?.formUploadCacheAdd?.uploadedFiles) {
        uploadFiles.value.push(...data.formUploadCacheAdd.uploadedFiles)
      }
    })
}

const removeFile = async (fileId: Scalars['ID']) => {
  new MutationHandler(
    useFormUploadCacheRemoveMutation({
      variables: { formId: props.context.formId, fileIds: [fileId] },
    }),
  )
    .send()
    .then((data) => {
      if (data?.formUploadCacheRemove?.success) {
        uploadFiles.value = uploadFiles.value.filter((elem) => {
          return elem.id !== fileId
        })
      }
    })
}
</script>

<template>
  <div v-if="addFileLoading">LOADING, PLEASE WAIT...</div>
  <ul v-if="uploadFiles.length">
    <li v-for="uploadFile in uploadFiles" v-bind:key="uploadFile.id">
      {{ uploadFile.name }}
      <span v-on:click="removeFile(uploadFile.id)">REMOVE THIS FILE</span>
    </li>
  </ul>
  <input
    type="file"
    v-bind:accept="props.context.accept"
    v-bind:capture="props.context.capture"
    v-bind:multiple="props.context.multiple"
    v-on:change="onFileChanged($event)"
  />
</template>
