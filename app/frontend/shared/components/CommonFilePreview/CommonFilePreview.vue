<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import { useSharedVisualConfig } from '#shared/composables/useSharedVisualConfig.ts'
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import type { StoredFile } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { getFilePreviewClasses } from '#shared/initializer/initializeFilePreviewClasses.ts'
import {
  canDownloadFile,
  canPreviewFile,
  humanizeFileSize,
} from '#shared/utils/files.ts'
import { getIconByContentType } from '#shared/utils/icons.ts'

export interface Props {
  file: Pick<StoredFile, 'type' | 'name' | 'size'>

  downloadUrl?: string
  previewUrl?: string
  loading?: boolean

  noPreview?: boolean
  noRemove?: boolean

  wrapperClass?: string
  iconClass?: string
  sizeClass?: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  remove: []
  preview: [$event: Event]
}>()

const imageFailed = ref(false)

const canPreview = computed(() => {
  const { file, previewUrl } = props

  if (!previewUrl || imageFailed.value) return false

  return canPreviewFile(file.type)
})

const canDownload = computed(() => canDownloadFile(props.file.type))
const icon = computed(() => getIconByContentType(props.file.type))

const componentType = computed(() => {
  if (props.downloadUrl) return 'CommonLink'
  return 'div'
})

const ariaLabel = computed(() => {
  if (props.downloadUrl && canDownload.value)
    return i18n.t('Download %s', props.file.name) // directly downloads file
  if (props.downloadUrl && !canDownload.value)
    return i18n.t('Open %s', props.file.name) // opens file in another tab
  return props.file.name // cannot download and preview, probably just uploaded pdf
})

const onPreviewClick = (event: Event) => {
  emit('preview', event)
}

const { isTouchDevice } = useTouchDevice()

const { filePreview: filePreviewConfig } = useSharedVisualConfig()

const classMap = getFilePreviewClasses()
</script>

<template>
  <div
    class="group/file-preview flex w-full items-center gap-2 outline-none"
    :class="[classMap.wrapper, wrapperClass]"
  >
    <button
      v-if="!noPreview && canPreview"
      class="flex h-9 w-9 items-center justify-center rounded border"
      :class="classMap.preview"
      :aria-label="$t('Preview %s', props.file.name)"
      @click="onPreviewClick"
      @keydown.delete.prevent="$emit('remove')"
      @keydown.backspace.prevent="$emit('remove')"
    >
      <img
        v-if="canPreview"
        class="max-h-9 rounded object-cover"
        :src="previewUrl"
        :alt="$t('Image of %s', file.name)"
        @error="imageFailed = true"
      />
    </button>

    <Component
      :is="componentType"
      class="flex w-full select-none items-center gap-2 overflow-hidden text-left outline-none"
      :class="{
        'cursor-pointer': componentType !== 'div',
        [classMap.link]: true,
      }"
      :aria-label="ariaLabel"
      tabindex="0"
      :link="downloadUrl"
      :download="canDownload ? file.name : undefined"
      :target="!canDownload ? '_blank' : undefined"
      @keydown.delete.prevent="$emit('remove')"
      @keydown.backspace.prevent="$emit('remove')"
    >
      <div
        v-if="!canPreview"
        class="flex h-9 w-9 items-center justify-center rounded border"
        :class="[classMap.icon, iconClass]"
      >
        <CommonIcon
          v-if="loading"
          size="base"
          :label="$t('File \'%s\' is uploading', file.name)"
          name="loading"
          animation="spin"
        />
        <CommonIcon v-else size="base" decorative :name="icon" />
      </div>
      <div class="flex flex-1 flex-col overflow-hidden" :class="classMap.base">
        <span class="truncate">
          {{ file.name }}
        </span>
        <span
          v-if="file.size"
          class="whitespace-nowrap"
          :class="[classMap.size, sizeClass]"
        >
          {{ humanizeFileSize(file.size) }}
        </span>
      </div>
    </Component>

    <component
      :is="filePreviewConfig?.buttonComponent"
      v-if="!noRemove"
      :class="{
        'opacity-0 transition-opacity': !isTouchDevice,
      }"
      class="focus:opacity-100 group-hover/file-preview:opacity-100"
      type="button"
      icon="remove-attachment"
      :aria-label="i18n.t('Remove %s', file.name)"
      v-bind="filePreviewConfig?.buttonProps"
      @click.stop.prevent="$emit('remove')"
      @keypress.space.prevent="$emit('remove')"
    />
  </div>
</template>
