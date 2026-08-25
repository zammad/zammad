<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { computed, ref } from 'vue'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { i18n } from '#shared/i18n.ts'
import {
  canDownloadFile,
  canPreviewFile,
  humanizeFileSize,
  splitFileName,
  type FilePreview,
} from '#shared/utils/files.ts'
import { getIconByContentType } from '#shared/utils/icons.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import type { FileListFile } from './types.ts'

interface Props {
  file: FileListFile
  noRemove?: boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  preview: [type: FilePreview]
  remove: []
}>()

const { isTouchDevice } = useTouchDevice()

const imageFailed = ref(false)

// A file is only previewable when the server also produced a preview for it — and an
//   image whose thumbnail failed to load falls back to its content-type icon.
const canPreview = computed(() => {
  if (!props.file.preview || imageFailed.value) return false

  return canPreviewFile(props.file.type)
})

const canDownload = computed(() => canDownloadFile(props.file.type))

const icon = computed(() => getIconByContentType(props.file.type))

const fileNameParts = computed(() => splitFileName(props.file.name))

const fileSizeLabel = computed(() => {
  if (props.file.size === null || props.file.size === undefined) return undefined

  return humanizeFileSize(props.file.size)
})

// Previewable files open the preview, everything else downloads right away — so the
//   whole row always does the one thing that makes sense for that file, as a button or
//   as a link.
const buildPrimaryAction = () => {
  if (canPreview.value) {
    return {
      component: 'button',
      label: i18n.t('Preview %s', props.file.name),
      attrs: { type: 'button' },
    }
  }

  if (canDownload.value) {
    return {
      component: 'CommonLink',
      label: i18n.t('Download %s', props.file.name),
      attrs: { link: props.file.downloadUrl, download: props.file.name },
    }
  }

  // Cannot be sent as a download (`text/html`), so it opens in a new tab instead.
  return {
    component: 'CommonLink',
    label: i18n.t('Open %s', props.file.name),
    attrs: { link: props.file.downloadUrl, target: '_blank' },
  }
}

// On a row that is itself the download link this icon is a visual duplicate of it, so
//   it stays on screen but is taken out of the accessibility tree and the tab order
//   instead of announcing the same destination twice.
const buildDownloadAction = () => {
  const redundant = !canPreview.value

  return {
    label: canDownload.value
      ? i18n.t('Download file: %s', props.file.name)
      : i18n.t('Open file: %s', props.file.name),
    attrs: {
      link: props.file.downloadUrl,
      download: canDownload.value ? props.file.name : undefined,
      target: canDownload.value ? undefined : '_blank',
      'aria-hidden': redundant ? 'true' : undefined,
      tabindex: redundant ? -1 : 0,
    },
  }
}

// A rebuilt object is a new reference even when it describes the very same action, so
//   the prev-compare hands back the previous one and `v-bind` has nothing to patch
//   unless the file itself changed.
const primaryAction = computed<ReturnType<typeof buildPrimaryAction>>((currentValue) => {
  const action = buildPrimaryAction()

  return currentValue && isEqual(currentValue, action) ? currentValue : action
})

const downloadAction = computed<ReturnType<typeof buildDownloadAction>>((currentValue) => {
  const action = buildDownloadAction()

  return currentValue && isEqual(currentValue, action) ? currentValue : action
})

const onPrimaryClick = () => {
  if (!canPreview.value) return

  emit('preview', canPreview.value)
}
</script>

<template>
  <div
    data-test-id="file-list-item"
    class="group flex items-center gap-2 rounded-[calc(var(--radius-lg)-var(--spacing))] p-2.5"
    :class="{
      // Only a file that can be previewed rests on its own surface — the neutral
      //   background is what marks the row as something to open.
      'border border-neutral-100 bg-neutral-50 transition-colors hover:bg-blue-600 active:bg-blue-800! active:text-white dark:border-gray-900 dark:bg-gray-500 dark:hover:bg-blue-900 formkit-alternative-background:bg-blue-200 dark:formkit-alternative-background:bg-gray-700':
        canPreview,
      'hover:outline hover:outline-blue-800': !canPreview,
    }"
  >
    <component
      :is="primaryAction.component"
      v-tooltip="primaryAction.label"
      v-bind="primaryAction.attrs"
      class="flex min-w-0 flex-1 items-center gap-2 text-left no-underline! focus-visible-app-default select-none focus-visible:rounded-[3px]"
      @click="onPrimaryClick"
    >
      <img
        v-if="canPreview === 'image'"
        class="size-9 shrink-0 rounded-[3px] border border-neutral-100 object-cover dark:border-gray-900"
        :src="file.preview"
        :alt="$t('Image name: %s', file.name)"
        @error="imageFailed = true"
      />
      <div
        v-else
        class="flex size-9 shrink-0 items-center justify-center rounded-[3px] text-stone-200 dark:text-neutral-500"
        :class="{
          'border border-neutral-100 group-active:text-white dark:border-gray-900': canPreview,
        }"
      >
        <CommonIcon size="base" decorative :name="icon" />
      </div>

      <div
        class="flex min-w-0 flex-1 flex-col text-sm leading-snug text-black dark:text-white"
        :class="{ 'group-active:text-white': canPreview }"
      >
        <div class="flex">
          <span class="line-clamp-1 min-w-0 break-all">{{ fileNameParts.base }}</span>
          <span v-if="fileNameParts.ext" class="shrink-0">{{ fileNameParts.ext }}</span>
        </div>

        <CommonLabel
          v-if="fileSizeLabel"
          size="small"
          class="line-clamp-1 leading-snug text-stone-200 dark:text-neutral-500"
          :class="{ 'group-active:text-white': canPreview }"
        >
          {{ fileSizeLabel }}
        </CommonLabel>
      </div>
    </component>

    <div
      data-test-id="file-list-item-actions"
      class="flex shrink-0 items-center gap-1 group-hover:opacity-100 focus-within:opacity-100"
      :class="{ 'opacity-0 transition-opacity': !isTouchDevice }"
    >
      <CommonLink
        v-tooltip="downloadAction.label"
        v-bind="downloadAction.attrs"
        class="rounded-xs p-0.5 text-stone-200! focus-visible-app-default hover:text-black! dark:text-neutral-500! dark:hover:text-white!"
        :class="{
          'group-hover:text-black! dark:group-hover:text-white!': !canPreview,
          'group-active:text-white!': canPreview,
        }"
        @mousedown.stop
      >
        <CommonIcon size="xs" decorative name="download" />
      </CommonLink>

      <CommonButton
        v-if="!noRemove"
        v-tooltip="$t('Remove file: %s', file.name)"
        icon="x-lg"
        size="small"
        variant="remove"
        @click.stop="$emit('remove')"
        @mousedown.stop
      />
    </div>
  </div>
</template>
