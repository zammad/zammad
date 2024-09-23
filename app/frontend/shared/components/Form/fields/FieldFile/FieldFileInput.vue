<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { useDropZone } from '@vueuse/core'
import { useTemplateRef } from 'vue'
import { toRef, computed, ref, type ComputedRef } from 'vue'

import CommonFilePreview from '#shared/components/CommonFilePreview/CommonFilePreview.vue'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { useAppName } from '#shared/composables/useAppName.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useImageViewer } from '#shared/composables/useImageViewer.ts'
import { useSharedVisualConfig } from '#shared/composables/useSharedVisualConfig.ts'
import { useTraverseOptions } from '#shared/composables/useTraverseOptions.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { convertFileList } from '#shared/utils/files.ts'

import { useFileUploadProcessing } from '../../composables/useFileUploadProcessing.ts'

import { useFileValidation } from './composable/useFileValidation.ts'
import { useFormUploadCacheAddMutation } from './graphql/mutations/uploadCache/add.api.ts'
import { useFormUploadCacheRemoveMutation } from './graphql/mutations/uploadCache/remove.api.ts'
import { getFileClasses } from './initializeFileClasses.ts'

import type { FieldFileProps, FileUploaded } from './types.ts'
import type { SetOptional } from 'type-fest'

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
const loadingFiles = ref<SetOptional<FileUploaded, 'id'>[]>([])

// TODO: We improved now the upload cache endpoint also working for show, so maybe we could use this for preview.
const uploadFilesWithContent = computed(() => {
  return uploadFiles.value.map((file) => {
    const content = contentFiles.value[file.id]
    return { ...file, content }
  })
})

const addFileMutation = new MutationHandler(useFormUploadCacheAddMutation({}))
const addFileLoading = addFileMutation.loading()

const removeFileMutation = new MutationHandler(
  useFormUploadCacheRemoveMutation({}),
)
const removeFileLoading = addFileMutation.loading()

const canInteract = computed(
  () =>
    !props.context.disabled &&
    !addFileLoading.value &&
    !removeFileLoading.value,
)

const { setFileUploadProcessing, removeFileUploadProcessing } =
  useFileUploadProcessing(props.context.formId, props.context.node.name)

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
  const confirmed = await waitForConfirmation(
    __('Are you sure you want to delete "%s"?'),
    {
      textPlaceholder: [file.name],
      buttonLabel: __('Delete'),
      buttonVariant: 'danger',
    },
  )

  if (!confirmed) return

  if (!fileId) {
    uploadFiles.value = uploadFiles.value.filter((elem) => elem !== file)
    return
  }

  const toBeDeletedFile = uploadFiles.value.find((file) => file.id === fileId)
  if (toBeDeletedFile) {
    toBeDeletedFile.isProcessing = true
  }

  removeFileMutation
    .send({ formId: props.context.formId, fileIds: [fileId] })
    .then((data) => {
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
    !props.context.multiple &&
    (uploadFiles.value.length >= 1 || loadingFiles.value.length >= 1)
  )
})

const bottomGradientOpacity = ref('1')

const onFilesScroll = (event: UIEvent) => {
  const target = event.target as HTMLElement
  const scrollMin = 20
  const bottomMax = target.scrollHeight - target.clientHeight
  const bottomMin = bottomMax - scrollMin
  const { scrollTop } = target
  if (scrollTop <= bottomMin) {
    bottomGradientOpacity.value = '1'
    return
  }
  const opacityPart = (scrollTop - bottomMin) / scrollMin
  bottomGradientOpacity.value = (1 - opacityPart).toFixed(2)
}

const { showImage } = useImageViewer(uploadFilesWithContent)

const filesContainer = useTemplateRef('files-container')

useTraverseOptions(filesContainer, {
  direction: 'vertical',
})

const appName = useAppName()
const classMap = getFileClasses()
const { fieldFile: fieldFileConfig } = useSharedVisualConfig()

const showDivider = computed(() => {
  return (
    classMap.divider &&
    !reachedUploadLimit.value &&
    (uploadFiles.value.length || loadingFiles.value.length)
  )
})

const showGradient = computed(() => {
  return (
    appName === 'mobile' &&
    (uploadFiles.value.length > 2 || loadingFiles.value.length > 2)
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
      <div v-if="showGradient" class="relative w-full">
        <div
          class="file-list show-gradient top-gradient absolute h-5 w-full"
        ></div>
      </div>
      <div
        v-if="uploadFiles.length || loadingFiles.length"
        ref="files-container"
        role="list"
        class="overflow-auto"
        :class="{
          'opacity-60': !canInteract,
          'pb-4': reachedUploadLimit,
          [classMap.listContainer]: true,
        }"
        @scroll.passive="onFilesScroll($event as UIEvent)"
      >
        <CommonFilePreview
          v-for="(uploadFile, idx) of uploadFilesWithContent"
          :key="uploadFile.id || `${uploadFile.name}-${idx}`"
          :file="uploadFile"
          role="listitem"
          :class="{ 'pointer-events-none opacity-75': uploadFile.isProcessing }"
          :no-remove="uploadFile.isProcessing"
          :loading="uploadFile.isProcessing"
          :preview-url="uploadFile.preview || uploadFile.content"
          :download-url="uploadFile.content"
          @preview="canInteract && showImage(uploadFile)"
          @remove="canInteract && removeFile(uploadFile)"
        />
        <CommonFilePreview
          v-for="(uploadFile, idx) of loadingFiles"
          :key="uploadFile.id || `${uploadFile.name}${idx}`"
          role="listitem"
          :file="uploadFile"
          loading
          no-remove
        />
      </div>
      <div v-if="showGradient" class="relative w-full">
        <div
          class="file-list show-gradient bottom-gradient absolute h-5 w-full"
          :style="{ opacity: bottomGradientOpacity }"
        ></div>
      </div>
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
          :v-bind="context.attrs"
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
