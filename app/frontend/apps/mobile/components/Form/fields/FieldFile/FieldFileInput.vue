<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { toRef, computed, ref } from 'vue'
import { convertFileList } from '#shared/utils/files.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useImageViewer } from '#shared/composables/useImageViewer.ts'
import { useTraverseOptions } from '#shared/composables/useTraverseOptions.ts'
import { waitForConfirmation } from '#shared/utils/confirmation.ts'
import type { FileUploaded } from '#shared/components/Form/fields/FieldFile/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import CommonFilePreview from '#mobile/components/CommonFilePreview/CommonFilePreview.vue'
import useInstantValidation from '#mobile/components/Form/fields/FieldFile/composables/useInstantValidation.ts'
import type { FieldFileProps } from './types.ts'
import { useFormUploadCacheAddMutation } from './graphql/mutations/uploadCache/add.api.ts'
import { useFormUploadCacheRemoveMutation } from './graphql/mutations/uploadCache/remove.api.ts'

export interface Props {
  context: FormFieldContext<FieldFileProps>
}

const props = defineProps<Props>()

const contextReactive = toRef(props, 'context')

const uploadFiles = computed<FileUploaded[]>({
  get() {
    return contextReactive.value._value || []
  },
  set(value) {
    props.context.node.input(value)
  },
})

const loadingFiles = ref<FileUploaded[]>([])

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

const fileInput = ref<HTMLInputElement>()
const reset = () => {
  loadingFiles.value = []
  const input = fileInput.value
  if (!input) return
  input.value = ''
  input.files = null
}

const { validate } = useInstantValidation()

const loadFiles = async (files: FileList | File[]) => {
  loadingFiles.value = Array.from(files || []).map((file) => ({
    name: file.name,
    size: file.size,
    type: file.type,
  }))

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

  const previewableFile = uploadedFiles.map((file, index) => ({
    ...file,
    content: uploads[index].content,
  }))

  uploadFiles.value = [...uploadFiles.value, ...previewableFile]
  reset()
}

Object.assign(props.context, {
  uploadFiles: loadFiles,
})

const onFileChanged = async ($event: Event) => {
  const input = $event.target as HTMLInputElement
  const { files } = input

  if (!files) return
  // Extra validation for file size and type if specified in the rules
  const isValid = validate(
    files,
    props.context.parsedRules as Array<Record<'name', string>>,
  )
  if (!isValid) return

  await loadFiles(files)
}

const removeFile = async (file: FileUploaded) => {
  const fileId = file.id

  const confirmed = await waitForConfirmation(
    __('Are you sure you want to delete "%s"?'),
    {
      headingPlaceholder: [file.name],
      buttonTitle: __('Delete'),
      buttonVariant: 'danger',
    },
  )

  if (!confirmed) return

  if (!fileId) {
    uploadFiles.value = uploadFiles.value.filter((elem) => elem !== file)
    return
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
  return !props.context.multiple && uploadFiles.value.length >= 1
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

const { showImage } = useImageViewer(uploadFiles)

const filesContainer = ref<HTMLDivElement>()

useTraverseOptions(filesContainer, {
  direction: 'vertical',
})
</script>

<template>
  <div v-if="uploadFiles.length > 2" class="relative w-full">
    <div class="ShadowGradient TopGradient absolute h-5 w-full"></div>
  </div>
  <div
    v-if="uploadFiles.length || loadingFiles.length"
    ref="filesContainer"
    class="max-h-48 overflow-auto px-4 pt-4"
    :class="{
      'opacity-60': !canInteract,
      'pb-4': reachedUploadLimit,
    }"
    @scroll.passive="onFilesScroll"
  >
    <CommonFilePreview
      v-for="(uploadFile, idx) of uploadFiles"
      :key="uploadFile.id || `${uploadFile.name}${idx}`"
      :file="uploadFile"
      :preview-url="uploadFile.preview || uploadFile.content"
      :download-url="uploadFile.content"
      @preview="canInteract && showImage(uploadFile)"
      @remove="canInteract && removeFile(uploadFile)"
    />
    <CommonFilePreview
      v-for="(uploadFile, idx) of loadingFiles"
      :key="uploadFile.id || `${uploadFile.name}${idx}`"
      :file="uploadFile"
      loading
      no-remove
    />
  </div>
  <div v-if="uploadFiles.length > 2" class="relative w-full">
    <div
      class="ShadowGradient BottomGradient absolute h-5 w-full"
      :style="{ opacity: bottomGradientOpacity }"
    ></div>
  </div>
  <button
    v-if="!reachedUploadLimit"
    class="flex w-full items-center justify-center gap-1 p-4 text-blue"
    type="button"
    tabindex="0"
    :class="{
      'text-blue/60': !canInteract,
    }"
    :disabled="!canInteract"
    @click="canInteract && fileInput?.click()"
  >
    <CommonIcon name="attachment" size="base" decorative />
    <span class="text-base">
      {{ $t(uploadTitle) }}
    </span>
  </button>
  <input
    ref="fileInput"
    data-test-id="fileInput"
    type="file"
    :name="context.node.name"
    class="hidden"
    tabindex="-1"
    aria-hidden="true"
    :accept="context.accept"
    :capture="context.capture"
    :multiple="context.multiple"
    @change="canInteract && onFileChanged($event)"
  />
</template>

<style scoped>
.ShadowGradient::before {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  bottom: 1.25rem;
  height: 30px;
  pointer-events: none;
}

.BottomGradient::before {
  bottom: 1.25rem;
  background: linear-gradient(rgba(255, 255, 255, 0), theme('colors.gray.500'));
}

.TopGradient::before {
  top: 0;
  background: linear-gradient(theme('colors.gray.500'), rgba(255, 255, 255, 0));
}
</style>
