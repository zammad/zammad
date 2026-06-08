<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { NodeViewWrapper, type NodeViewProps } from '@tiptap/vue-3'
import { computed, nextTick, reactive, ref, type ComputedRef } from 'vue'
import DraggableResizable from 'vue3-draggable-resizable'
import 'vue3-draggable-resizable/dist/Vue3DraggableResizable.css'

import { useImageUpload } from '#shared/components/Form/fields/FieldEditor/features/image-handler/useImageUpload.ts'
import { blobToBase64 } from '#shared/utils/files.ts'
import testFlags from '#shared/utils/testFlags.ts'

import ImageFailedUploadOverlay from './ImageFailedUploadOverlay.vue'
import ImageUploadInsideOtherEditor from './ImageUploadInsideOtherEditor.vue'

// eslint-disable-next-line vue/prop-name-casing
const props = defineProps<NodeViewProps>()
const initialHeight = props.node.attrs.height
const initialWidth = props.node.attrs.width

const editorAttributes = computed(() => props.editor.options.editorProps.attributes) as ComputedRef<
  Record<string, unknown>
>

const isResized = ref(false)
const isResizing = ref(false)
const imageLoaded = ref(false)
const failedDueToCors = ref(false)
const isDraggable = computed(() => props.node.attrs.isDraggable)
const uploadCacheExists = computed(() => props.node.attrs.src.startsWith('/api/v1/attachments/'))
const uploadInsideOtherEditor = computed(
  () => props.node.attrs.src.startsWith('blob:') && !props.node.attrs.content,
)
const uploadFailed = ref(false)
const src = computed(() => props.node.attrs.src)

const getNodeStyle = () =>
  props.node?.attrs?.style?.split?.(';')?.reduce((acc: Record<string, string>, style: string) => {
    const [property, value] = style.split(':').map((item) => item.trim())
    if (property && value) acc[property] = value
    return acc
  }, {})

const handleUpload = () => {
  if (props.node.attrs.src.startsWith('/api/v1/attachments/')) return
  if (props.node.attrs.src.startsWith('blob:') && !props.node.attrs.content) return

  if (props.node.attrs.src.startsWith('file:')) {
    uploadFailed.value = true
    nextTick(() => testFlags.set('editor.inlineImagesFailure'))

    return
  }

  const { uploadImage } = useImageUpload(
    editorAttributes.value['data-form-id'] as string,
    editorAttributes.value.name as string,
    true,
  )

  const style = getNodeStyle()

  const width = style?.width ? parseFloat(style.width) : undefined
  const height = style?.height ? parseFloat(style.height) : undefined

  if (src.value.startsWith('http')) {
    fetch(src.value)
      .then((response) => response.blob())
      .then(async (blob) => {
        blobToBase64(blob).then((base64) => {
          // Update the node attributes with the base64 content.
          props.updateAttributes({
            src: URL.createObjectURL(blob),
            width,
            height,
            content: null,
          })

          uploadImage(
            [
              {
                name: props.node.attrs.alt || 'untitled',
                type: props.node.attrs.type || base64.match(/^data:(.+);base64/)?.at(1),
                content: base64,
              },
            ],
            (files) => {
              // Remember the preview src before updating the src in the node.
              const previewSrc = props.node.attrs.src

              props.updateAttributes({
                src: files[0].src,
                width,
                height,
                content: null,
              })

              nextTick(() => {
                URL.revokeObjectURL(previewSrc)
                testFlags.set('editor.inlineImagesLoaded')
              })
            },
          ).catch(() => {
            uploadFailed.value = true

            nextTick(() => testFlags.set('editor.inlineImagesFailure'))
          })
        })
      })
      .catch((error) => {
        // Heuristic: fetch() CORS/network issues typically surface as TypeError with generic message.
        if ((error instanceof Error ? error.name : '') === 'TypeError') {
          failedDueToCors.value = true
        }

        uploadFailed.value = true

        nextTick(() => testFlags.set('editor.inlineImagesFailure'))
      })
  } else {
    uploadImage(
      [
        {
          name: props.node.attrs.alt || 'untitled',
          type: props.node.attrs.type || props.node.attrs.src?.match(/^data:(.+);base64/)?.at(1),
          content: props.node.attrs.content || props.node.attrs.src,
        },
      ],
      (files) => {
        // Remember the preview src before updating the src in the node.
        const previewSrc = props.node.attrs.src

        props.updateAttributes({
          src: files[0].src,
          width,
          height,
          content: null,
        })

        nextTick(() => {
          URL.revokeObjectURL(previewSrc)
          testFlags.set('editor.inlineImagesLoaded')
        })
      },
    ).catch(() => {
      uploadFailed.value = true

      nextTick(() => testFlags.set('editor.inlineImagesFailure'))
    })
  }
}

handleUpload()

const dimensions = reactive({
  maxWidth: 0,
  maxHeight: 0,
  height: computed({
    get: () => Number(props.node.attrs.height) || 0,
    set: (height) => props.updateAttributes({ height }),
  }),
  width: computed({
    get: () => Number(props.node.attrs.width) || 0,
    set: (width) => props.updateAttributes({ width }),
  }),
})

const onLoadImage = (e: Event) => {
  if (imageLoaded.value || props.editor.isDestroyed || !props.editor.isEditable) return

  const img = e.target as HTMLImageElement
  const { naturalWidth, naturalHeight } = img

  dimensions.width = initialWidth !== '100%' ? initialWidth : naturalWidth
  dimensions.height = initialHeight !== 'auto' ? initialHeight : naturalWidth
  dimensions.maxHeight = naturalHeight
  dimensions.maxWidth = naturalWidth
  imageLoaded.value = true

  testFlags.set('editor.imageResized')
}

const stopResizing = ({ w, h }: { w: number; h: number }) => {
  dimensions.width = w
  dimensions.height = h
  isResized.value = true
}

const style = computed(() => {
  if (!imageLoaded.value || !isResized.value) return {}

  const { width, height } = dimensions
  return {
    width: `${width}px`,
    height: `${height}px`,
    maxWidth: '100%',
  }
})

// this is needed so "draggable resize" could calculate the maximum size
const wrapperStyle = computed(() => {
  if (!isResizing.value) return {}
  const { maxWidth, maxHeight } = dimensions
  return { width: maxWidth, height: maxHeight }
})
</script>

<template>
  <NodeViewWrapper
    as="div"
    class="relative inline-block"
    :style="wrapperStyle"
    :class="{
      'opacity-50': !uploadCacheExists || uploadInsideOtherEditor,
    }"
  >
    <ImageUploadInsideOtherEditor v-if="uploadInsideOtherEditor" />
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
        :width="node.attrs.width"
        :height="node.attrs.height"
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
      <img
        class="block h-full w-full"
        :alt="$t('Resize frame')"
        :src="src"
        :draggable="isDraggable"
      />
    </DraggableResizable>
  </NodeViewWrapper>
</template>
