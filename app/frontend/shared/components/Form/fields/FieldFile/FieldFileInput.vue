<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { useDropZone } from '@vueuse/core'
import { useTemplateRef } from 'vue'
import { toRef, computed, ref, type ComputedRef } from 'vue'

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useSharedVisualConfig } from '#shared/composables/useSharedVisualConfig.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { convertFileList } from '#shared/utils/files.ts'

import { useFileUploadProcessing } from '../../composables/useFileUploadProcessing.ts'

import { useFileValidation } from './composable/useFileValidation.ts'
import { useFormUploadCacheAddMutation } from './graphql/mutations/uploadCache/add.api.ts'
import { useFormUploadCacheRemoveMutation } from './graphql/mutations/uploadCache/remove.api.ts'
import { getFileClasses } from './initializeFileClasses.ts'

import type { FieldFileLoading, FieldFileProps, FieldFileUploaded, FileUploaded } from './types.ts'

export interface Props {
  context: FormFieldContext<FieldFileProps>
}

const props = defineProps<Props>()

const contextReactive = toRef(props, 'context')

const { validateFileSize } = useFileValidation()

// TODO: later we need to check how file content from prefilled upload cache is working
// Switch to direct url for preview?
const uploadFiles = computed<FileUploaded[]>({
  get() {
    return contextReactive.value._value || []
  },
  set(value) {
    props.context.node.input(value)
  },
})

const contentFiles = ref<Record<string, string>>({})
const loadingFiles = ref<FieldFileLoading[]>([])

// TODO: We improved now the upload cache endpoint also working for show, so maybe we could use this for preview.
const uploadFilesWithContent = computed<FieldFileUploaded[]>(() => {
  return uploadFiles.value.map((file) => {
    const content = contentFiles.value[file.id]
    return { ...file, content }
  })
})

const addFileMutation = new MutationHandler(useFormUploadCacheAddMutation({}))
const addFileLoading = addFileMutation.loading()

const removeFileMutation = new MutationHandler(useFormUploadCacheRemoveMutation({}))
const removeFileLoading = addFileMutation.loading()

const canInteract = computed(
  () => !props.context.disabled && !addFileLoading.value && !removeFileLoading.value,
)

const { setFileUploadProcessing, removeFileUploadProcessing } = useFileUploadProcessing(
  props.context.formId,
  props.context.node.name,
)

const fileInput = useTemplateRef('file-input')

const reset = () => {
  loadingFiles.value = []
  const input = fileInput.value
  if (!input) return
  input.value = ''
  input.files = null

  removeFileUploadProcessing()
}

const loadFiles = async (files: FileList | File[]) => {
  loadingFiles.value = Array.from(files || []).map((file) => ({
    name: file.name,
    size: file.size,
    type: file.type,
  }))

  setFileUploadProcessing()

  const uploads = await convertFileList(files)

  const data = await addFileMutation
    .send({
      formId: props.context.formId,
      files: uploads,
    })
    .catch(() => {
      reset()
    })

  const uploadedFiles = data?.formUploadCacheAdd?.uploadedFiles

  if (!uploadedFiles) {
    reset()
    return
  }

  const previewableFile = uploadedFiles.reduce(
    (filesContent: Record<string, string>, file, index) => {
      filesContent[file.id] = uploads[index].content
      return filesContent
    },
    {},
  )

  contentFiles.value = { ...contentFiles.value, ...previewableFile }
  uploadFiles.value = [...uploadFiles.value, ...uploadedFiles]

  reset()
}

// eslint-disable-next-line vue/no-mutating-props
Object.assign(props.context, {
  uploadFiles: loadFiles,
})

const onFileChanged = async ($event: Event) => {
  const input = $event.target as HTMLInputElement

  const { files } = input
  if (
    props.context.allowedFiles &&
    files &&
    !validateFileSize(props.context.node, files, props.context.allowedFiles)
  ) {
    return
  }
  if (!files) return

  await loadFiles(files)
}

const { waitForConfirmation } = useConfirmation()

const removeFile = async (file: FileUploaded) => {
  const fileId = file.id
  const confirmed = await waitForConfirmation(__('Are you sure you want to delete "%s"?'), {
    textPlaceholder: [file.name],
    buttonLabel: __('Delete'),
    buttonVariant: 'danger',
  })

  if (!confirmed) return

  if (!fileId) {
    uploadFiles.value = uploadFiles.value.filter((elem) => elem !== file)
    return
  }

  const toBeDeletedFile = uploadFiles.value.find((file) => file.id === fileId)
  if (toBeDeletedFile) {
    toBeDeletedFile.isProcessing = true
  }

  removeFileMutation.send({ formId: props.context.formId, fileIds: [fileId] }).then((data) => {
    if (data?.formUploadCacheRemove?.success) {
      uploadFiles.value = uploadFiles.value.filter((elem) => {
        return elem.id !== fileId
      })
    }
  })
}

const uploadTitle = computed(() => {
  if (!props.context.multiple) {
    return __('Attach file')
  }
  if (uploadFiles.value.length === 0) {
    return __('Attach files')
  }
  return __('Attach another file')
})

const reachedUploadLimit = computed(() => {
  return (
    !props.context.multiple && (uploadFiles.value.length >= 1 || loadingFiles.value.length >= 1)
  )
})

const classMap = getFileClasses()
const { fieldFile: fieldFileConfig } = useSharedVisualConfig()

const showDivider = computed(() => {
  return (
    classMap.divider &&
    !reachedUploadLimit.value &&
    (uploadFiles.value.length || loadingFiles.value.length)
  )
})

const acceptableFileTypes = computed(() => props.context.accept?.split(','))

const dropZoneElement = useTemplateRef('drop-zone')

const { isOverDropZone } = useDropZone(dropZoneElement, {
  dataTypes: acceptableFileTypes as ComputedRef<string[]>, // TODO: Maybe add a PR in vueuse, that the ref can also be undefined.
  onDrop: (files: File[] | null) => {
    if (!files) return

    loadFiles(files)
  },
})
</script>

<template>
  <div class="relative" :class="context.classes.input">
    <div ref="drop-zone">
      <component
        :is="fieldFileConfig?.listComponent"
        v-if="uploadFiles.length || loadingFiles.length"
        :files="uploadFilesWithContent"
        :loading-files="loadingFiles"
        :can-interact="canInteract"
        :class="{ 'pb-4': reachedUploadLimit }"
        @remove="removeFile"
      />
      <div v-if="showDivider" class="w-full px-2.5">
        <hr class="h-px w-full border-0" :class="classMap.divider" />
      </div>
      <div class="w-full p-1 text-center">
        <component
          :is="fieldFileConfig?.buttonComponent"
          v-if="!reachedUploadLimit"
          :class="classMap.button"
          type="button"
          size="medium"
          variant="secondary"
          prefix-icon="attachment"
          :disabled="!canInteract"
          @click="canInteract && fileInput?.click()"
        >
          {{ $t(uploadTitle) }}
        </component>
        <input
          :id="context.id"
          ref="file-input"
          data-test-id="fileInput"
          type="file"
          :name="context.node.name"
          :aria-describedby="context.describedBy"
          v-bind="context.attrs"
          class="hidden"
          tabindex="-1"
          aria-hidden="true"
          :accept="context.accept"
          :capture="context.capture"
          :multiple="context.multiple"
          @change="canInteract && onFileChanged($event)"
        />
      </div>
    </div>
    <div
      v-if="classMap.dropZoneContainer && isOverDropZone"
      class="pointer-events-none absolute inset-0 z-10 flex items-center justify-center p-2.5"
      :class="classMap.dropZoneContainer"
    >
      <div
        class="flex h-full w-full items-center justify-center rounded border-2 border-dashed"
        :class="classMap.dropZoneBorder"
      >
        <CommonLabel
          class="text-blue-800"
          :size="uploadFiles.length || loadingFiles.length ? 'large' : 'medium'"
          >{{ $t('Drop files here') }}</CommonLabel
        >
      </div>
    </div>
  </div>
</template>
