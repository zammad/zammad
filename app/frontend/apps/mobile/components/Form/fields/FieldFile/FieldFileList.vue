<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, useTemplateRef } from 'vue'

import { getFileClasses } from '#shared/components/Form/fields/FieldFile/initializeFileClasses.ts'
import type { FieldFileListProps } from '#shared/components/Form/fields/FieldFile/types.ts'
import { useImageViewer } from '#shared/composables/useImageViewer.ts'
import { useTraverseOptions } from '#shared/composables/useTraverseOptions.ts'

import CommonFilePreview from '#mobile/components/CommonFilePreview/CommonFilePreview.vue'

const props = defineProps<FieldFileListProps>()

const emit = defineEmits<{
  remove: [file: FieldFileListProps['files'][number]]
}>()

const classMap = getFileClasses()

const { showImage } = useImageViewer(computed(() => props.files))

const filesContainer = useTemplateRef('files-container')

useTraverseOptions(filesContainer, {
  direction: 'vertical',
})

const showGradient = computed(() => props.files.length + props.loadingFiles.length > 2)

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
</script>

<template>
  <div>
    <div v-if="showGradient" class="relative w-full">
      <div class="file-list show-gradient top-gradient absolute h-5 w-full"></div>
    </div>
    <div
      ref="files-container"
      role="list"
      class="overflow-auto"
      :class="{
        'opacity-60': !canInteract,
        [classMap.listContainer]: true,
      }"
      @scroll.passive="onFilesScroll($event as UIEvent)"
    >
      <CommonFilePreview
        v-for="(file, idx) of files"
        :key="file.id || `${file.name}-${idx}`"
        :file="file"
        role="listitem"
        :class="{ 'pointer-events-none opacity-75': file.isProcessing }"
        :no-remove="file.isProcessing"
        :loading="file.isProcessing"
        :preview-url="file.preview || file.content"
        :download-url="file.content"
        @preview="canInteract && !file.isProcessing && showImage(file)"
        @remove="canInteract && !file.isProcessing && emit('remove', file)"
      />
      <CommonFilePreview
        v-for="(file, idx) of loadingFiles"
        :key="file.id || `${file.name}${idx}`"
        role="listitem"
        :file="file"
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
  </div>
</template>
