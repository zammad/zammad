<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { NodeViewWrapper, type NodeViewProps } from '@tiptap/vue-3'
import { computed, ref } from 'vue'
import DraggableResizable from 'vue3-draggable-resizable'
import 'vue3-draggable-resizable/dist/Vue3DraggableResizable.css'

import testFlags from '#shared/utils/testFlags.ts'

import ImageFailedUploadOverlay from './ImageFailedUploadOverlay.vue'
import ImageUploadInsideOtherEditor from './ImageUploadInsideOtherEditor.vue'
import { getEditorFormId, getInlineImageUpload } from './inlineImageUploads.ts'

const props = defineProps<NodeViewProps>()

const isResized = ref(false)
const isResizing = ref(false)
const imageLoaded = ref(false)
const isDraggable = computed(() => props.node.attrs.isDraggable)
const src = computed(() => props.node.attrs.src)
const formId = computed(() => getEditorFormId(props.editor))
const upload = computed(() => getInlineImageUpload(formId.value, src.value))
const uploadPending = computed(() => !!upload.value && upload.value.status !== 'uploaded')
const uploadInsideOtherEditor = computed(
  () => src.value.startsWith('blob:') && !props.node.attrs.content && !upload.value,
)
const uploadFailed = computed(() => upload.value?.status === 'failed')
const failedDueToCors = computed(() => !!upload.value?.failedDueToCors)

// Rendering must not change the document: the natural size only sizes the resize frame, and
//   width/height are written once the image is actually resized.
const naturalWidth = ref(0)
const naturalHeight = ref(0)

const toPixels = (value: unknown) => Number(value) || undefined

const width = computed(() => toPixels(props.node.attrs.width))
const height = computed(() => toPixels(props.node.attrs.height))

const dimensions = computed(() => ({
  width: width.value ?? naturalWidth.value,
  height: height.value ?? naturalHeight.value,
}))

const onLoadImage = (e: Event) => {
  if (imageLoaded.value) return

  const img = e.target as HTMLImageElement

  naturalWidth.value = img.naturalWidth
  naturalHeight.value = img.naturalHeight
  imageLoaded.value = true

  testFlags.set('editor.imageResized')
}

const stopResizing = ({ w, h }: { w: number; h: number }) => {
  props.updateAttributes({ width: w, height: h })
  isResized.value = true
}

const style = computed(() => {
  if (!imageLoaded.value || !isResized.value) return {}

  return {
    width: `${dimensions.value.width}px`,
    height: `${dimensions.value.height}px`,
    maxWidth: '100%',
  }
})

// this is needed so "draggable resize" could calculate the maximum size
const wrapperStyle = computed(() => {
  if (!isResizing.value) return {}
  return { width: naturalWidth.value, height: naturalHeight.value }
})
</script>

<template>
  <NodeViewWrapper
    as="div"
    class="relative inline-block"
    :style="wrapperStyle"
    :class="{
      'opacity-50': uploadPending || uploadInsideOtherEditor,
    }"
  >
    <ImageUploadInsideOtherEditor v-if="uploadInsideOtherEditor" :width="width" :height="height" />
    <button
      v-else-if="!isResizing && src"
      class="relative inline-block"
      :disabled="uploadFailed"
      @click="isResizing = true"
      @keydown.space.prevent="isResizing = true"
      @keydown.enter.prevent="isResizing = true"
    >
      <ImageFailedUploadOverlay
        v-if="uploadFailed"
        :width="`${isResized ? `${dimensions.width}px` : '100%'}`"
        :height="`${isResized ? `${dimensions.height}px` : 'auto'}`"
      >
        <template v-if="failedDueToCors" #default>
          {{ $t('Inserting image not possible due to source restrictions') }}
        </template>
      </ImageFailedUploadOverlay>

      <img
        class="inline-block"
        :style="style"
        :src="src"
        :alt="node.attrs.alt"
        :width="node.attrs.width === '100%' ? undefined : node.attrs.width"
        :height="node.attrs.height === 'auto' ? undefined : node.attrs.height"
        :title="node.attrs.title"
        :draggable="isDraggable"
        @load="onLoadImage"
      />
    </button>
    <!--  Resizing can only battle tested in production mode  -->
    <DraggableResizable
      v-else-if="src && !uploadFailed"
      v-model:active="isResizing"
      :h="dimensions.height"
      :w="dimensions.width"
      :handles="['br', 'mr', 'tr']"
      :draggable="false"
      lock-aspect-ratio
      parent
      class="relative! inline-block!"
      @resize-end="stopResizing"
    >
      <img class="block size-full" :alt="$t('Resize frame')" :src="src" :draggable="isDraggable" />
    </DraggableResizable>
  </NodeViewWrapper>
</template>
