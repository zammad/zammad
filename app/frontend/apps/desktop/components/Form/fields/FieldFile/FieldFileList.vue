<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { getFileClasses } from '#shared/components/Form/fields/FieldFile/initializeFileClasses.ts'
import type {
  FieldFileListProps,
  FieldFileUploaded,
} from '#shared/components/Form/fields/FieldFile/types.ts'
import type { FilePreview } from '#shared/utils/files.ts'

import CommonFileList from '#desktop/components/CommonFileList/CommonFileList.vue'
import { useFilePreviewViewer } from '#desktop/composables/useFilePreviewViewer.ts'

import FieldFileListSkeleton from './FieldFileListSkeleton.vue'

const props = defineProps<FieldFileListProps>()

const emit = defineEmits<{
  remove: [file: FieldFileUploaded]
}>()

// Keeps the height cap the field had before the list moved in here, so a long attachment
//   list cannot push the compose area off screen.
const classMap = getFileClasses()

/**
 * Files still living in the upload cache are only reachable through the data URI the field
 *   kept when it read them, so `content` stands in for both the download target and the
 *   thumbnail until the server has a preview of its own.
 */
const listFiles = computed(() =>
  props.files.map((file, index) => ({
    ...file,
    internalId: file.id || `${file.name}-${index}`,
    preview: file.preview || file.content || '',
    downloadUrl: file.content || '',
  })),
)

const { showPreview } = useFilePreviewViewer(computed(() => props.files))

const onPreview = (type: FilePreview, file: (typeof listFiles.value)[number]) => {
  if (!props.canInteract || file.isProcessing) return

  // The viewer matches files by identity, so it has to receive the original object rather
  //   than the copy the list rendered.
  showPreview(type, props.files[listFiles.value.indexOf(file)])
}

const onRemove = (file: (typeof listFiles.value)[number]) => {
  if (!props.canInteract || file.isProcessing) return

  emit('remove', props.files[listFiles.value.indexOf(file)])
}
</script>

<template>
  <CommonFileList
    :files="listFiles"
    :label="$t('Attached files')"
    class="overflow-auto"
    :class="{ 'opacity-60': !canInteract, [classMap.listContainer]: true }"
    @preview="onPreview"
    @remove="onRemove"
  >
    <template v-if="loadingFiles.length" #append>
      <li v-for="(file, index) of loadingFiles" :key="file.id || `${file.name}-${index}`">
        <FieldFileListSkeleton :name="file.name" />
      </li>
    </template>
  </CommonFileList>
</template>
