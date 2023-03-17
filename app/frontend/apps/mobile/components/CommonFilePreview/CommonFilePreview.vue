<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, getCurrentInstance, ref } from 'vue'
import type { StoredFile } from '@shared/graphql/types'
import { canDownloadFile, canPreviewFile } from '@shared/utils/files'
import { humanizeFileSize } from '@shared/utils/helpers'
import { getIconByContentType } from '@shared/utils/icons'
import { i18n } from '@shared/i18n'

export interface Props {
  file: Pick<StoredFile, 'type' | 'name' | 'size'>

  downloadUrl?: string
  previewUrl?: string

  noPreview?: boolean
  noRemove?: boolean

  wrapperClass?: string
  iconClass?: string
  sizeClass?: string
}

const props = withDefaults(defineProps<Props>(), {
  wrapperClass: 'border-gray-300',
  iconClass: 'border-gray-300',
  sizeClass: 'text-white/80',
})

defineEmits<{
  (e: 'remove'): void
  (e: 'preview', $event: Event): void
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
  if (canPreview.value) return 'button'
  return 'div'
})

const vm = getCurrentInstance()

const ariaLabel = computed(() => {
  const listensForPreview = !!vm?.vnode.props?.onPreview
  if (canPreview.value && listensForPreview)
    return i18n.t('Preview %s', props.file.name) // opens a preview on the same page
  if (props.downloadUrl && canDownload.value)
    return i18n.t('Download %s', props.file.name) // directly downloads file
  if (props.downloadUrl && !canDownload.value)
    return i18n.t('Open %s', props.file.name) // opens file in another tab
  return props.file.name // cannot download and preview, probably just uploaded pdf
})
</script>

<template>
  <div
    class="mb-2 flex w-full items-center gap-2 rounded-2xl border-[0.5px] p-3 last:mb-0"
    :class="wrapperClass"
  >
    <Component
      :is="componentType"
      class="flex w-full select-none items-center gap-2 overflow-hidden text-left"
      :type="componentType === 'button' && 'button'"
      :class="{ 'cursor-pointer': componentType !== 'div' }"
      :aria-label="ariaLabel"
      :link="downloadUrl"
      :download="canDownload ? true : undefined"
      :target="!canDownload ? '_blank' : ''"
      @click="canPreview && $emit('preview', $event)"
    >
      <div
        v-if="!noPreview"
        class="flex h-9 w-9 items-center justify-center rounded border-[0.5px] p-1"
        :class="iconClass"
      >
        <img
          v-if="canPreview"
          class="max-h-8"
          :src="previewUrl"
          :alt="$t('Image of %s', file.name)"
          @error="imageFailed = true"
        />
        <CommonIcon v-else size="base" decorative :name="icon" />
      </div>
      <div class="flex flex-1 flex-col overflow-hidden leading-4">
        <span class="overflow-hidden text-ellipsis whitespace-nowrap">
          {{ file.name }}
        </span>
        <span v-if="file.size" class="whitespace-nowrap" :class="sizeClass">
          {{ humanizeFileSize(file.size) }}
        </span>
      </div>
    </Component>

    <button
      v-if="!noRemove"
      type="button"
      :aria-label="i18n.t('Remove %s', file.name)"
      @click.stop.prevent="$emit('remove')"
      @keypress.space.prevent="$emit('remove')"
    >
      <CommonIcon
        class="text-gray ltr:right-2 rtl:left-2"
        name="mobile-close-small"
        size="base"
        decorative
      />
    </button>
  </div>
</template>
