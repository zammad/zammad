<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { TextSelection } from '@tiptap/pm/state'
import { NodeViewWrapper, type NodeViewProps, type VueRenderer } from '@tiptap/vue-3'
import {
  computed,
  nextTick,
  onBeforeUnmount,
  ref,
  shallowRef,
  toRaw,
  useTemplateRef,
  watch,
  type ComponentPublicInstance,
} from 'vue'
import { DraggableResizable, type ResizePayload } from 'vue-drag-resize-kit'
import 'vue-drag-resize-kit/style.css'

import {
  isInFloatingPopover,
  setFloatingPopover,
} from '#shared/components/Form/fields/FieldEditor/utils.ts'
import {
  getEditorComponents,
  getFieldEditorClasses,
} from '#shared/components/Form/initializeFieldEditor.ts'
import { i18n } from '#shared/i18n.ts'
import getUuid from '#shared/utils/getUuid.ts'
import testFlags from '#shared/utils/testFlags.ts'

// Not async loaded: the form is handed to a `VueRenderer`, which renders nothing for a promise.
import ImageAltForm from './ImageAltForm.vue'
import ImageFailedUploadOverlay from './ImageFailedUploadOverlay.vue'
import ImageUploadInsideOtherEditor from './ImageUploadInsideOtherEditor.vue'
import { getEditorFormId, getInlineImageUpload } from './inlineImageUploads.ts'

import type { ImageToolbarAction } from './types.ts'

const props = defineProps<NodeViewProps>()

const classes = getFieldEditorClasses()

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

const resizeStarted = ref(false)

const toPixels = (value: unknown) => Number(value) || undefined

const width = computed(() => toPixels(props.node.attrs.width))
const height = computed(() => toPixels(props.node.attrs.height))

const onLoadImage = () => {
  imageLoaded.value = true
  testFlags.set('editor.imageResized')
}

const frame = useTemplateRef<InstanceType<typeof DraggableResizable>>('frame')

// The frame takes the focus from the editor, else ProseMirror would handle the arrow keys.
const startResizing = async () => {
  if (!imageLoaded.value || uploadFailed.value) return

  resizeStarted.value = false
  isResizing.value = true

  await nextTick()
  frame.value?.$el.focus()
}

const resizeSelectedImage = ({ position }: { position: number }) => {
  if (position === props.getPos()) startResizing()
}

props.editor.on('resize-image', resizeSelectedImage)

onBeforeUnmount(() => props.editor.off('resize-image', resizeSelectedImage))

// Read through the reactive proxy, a leaf node reports a size of 2: ProseMirror compares by identity.
const imageNodeSize = () => toRaw(props.node).nodeSize

watch(isResizing, (resizing) => {
  if (resizing || !frame.value?.$el.contains(document.activeElement)) return

  nextTick(() => {
    const position = props.getPos()
    if (position === undefined) return

    props.editor
      .chain()
      .focus()
      .setTextSelection(position + imageNodeSize())
      .run()
  })
})

// Library props named `aria-*`, which the accessibility lint rule takes for ARIA attributes.
const frameAccessibility = computed(() => ({
  ariaRoleDescription: i18n.t('resizable image'),
  ariaSizeText: (w: number, h: number) => i18n.t('%s × %s pixels', Math.round(w), Math.round(h)),
}))

const stopResizing = ({ w, h }: ResizePayload) => {
  props.updateAttributes({ width: Math.round(w), height: Math.round(h) })
  isResized.value = true
}

const sizeAttributes = computed(() => ({
  width: props.node.attrs.width === '100%' ? undefined : props.node.attrs.width,
  height: props.node.attrs.height === 'auto' ? undefined : props.node.attrs.height,
}))

// Only the frame itself: Enter on a toolbar item activates the item.
const deactivateOnEnter = (event: KeyboardEvent) => {
  if (event.target !== event.currentTarget) return

  event.preventDefault()
  isResizing.value = false
}

const toolbar = getEditorComponents().imageToolbar

const frameImage = useTemplateRef('frame-image')
const toolbarContent = useTemplateRef<ComponentPublicInstance>('toolbar-content')

const altFormId = `image-alt-form-${getUuid()}`
const altForm = shallowRef<VueRenderer | null>(null)
let altFormInvoker: Element | null = null

const closeAltForm = ({ restoreFocus = false } = {}) => {
  if (!altForm.value) return

  altForm.value.destroy()
  altForm.value = null

  if (restoreFocus && altFormInvoker instanceof HTMLElement && altFormInvoker.isConnected)
    altFormInvoker.focus()

  altFormInvoker = null
}

const saveAlt = (alt: string) => {
  props.updateAttributes({ alt })
  closeAltForm({ restoreFocus: true })
}

const openAltForm = () => {
  if (altForm.value) return closeAltForm({ restoreFocus: true })

  altFormInvoker = document.activeElement

  altForm.value = setFloatingPopover(
    ImageAltForm,
    props.editor,
    {
      id: altFormId,
      alt: props.node.attrs.alt,
      onSave: saveAlt,
      onCancel: () => closeAltForm({ restoreFocus: true }),
    },
    // Below the toolbar, which it would cover otherwise.
    { anchor: toolbarContent.value?.$el, onClose: closeAltForm },
  )
}

watch(isResizing, (resizing) => {
  if (!resizing) closeAltForm()
})

onBeforeUnmount(closeAltForm)

const deleteImage = () => {
  props.editor.commands.focus()
  props.deleteNode()
}

// Focused synchronously, else closing the frame would put the caret back in front of the text.
const typeAfterImage = (text: string) => {
  const position = props.getPos()
  if (position === undefined) return

  const after = position + imageNodeSize()
  const { state, view } = props.editor
  const tr = state.tr.insertText(text, after)

  view.dispatch(tr.setSelection(TextSelection.create(tr.doc, after + text.length)))
  view.focus()
  isResizing.value = false
}

// ProseMirror ignores keys within a node view: the browser would replace the image with the text.
const editBesideImage = (event: KeyboardEvent) => {
  if (event.target !== event.currentTarget || event.defaultPrevented) return
  if (event.ctrlKey || event.metaKey || event.isComposing) return

  if (event.key === 'Backspace' || event.key === 'Delete') {
    event.preventDefault()
    deleteImage()
    return
  }

  if (Array.from(event.key).length !== 1) return

  event.preventDefault()
  typeAfterImage(event.key)
}

const SMALL_IMAGE_WIDTH = 200

const FRAME_BOUNDARY = "p, [role='textbox']"

// The width the frame may take, measured like the library does for its `boundary`.
const boundaryWidth = () => {
  const boundary = frame.value?.$el.parentElement?.closest(FRAME_BOUNDARY)
  if (!boundary) return Infinity

  const { paddingLeft, paddingRight } = getComputedStyle(boundary)

  return boundary.clientWidth - (parseFloat(paddingLeft) || 0) - (parseFloat(paddingRight) || 0)
}

const naturalWidth = () => frameImage.value?.naturalWidth || Infinity

// Capped at the boundary, the original size of a wider image is the one fitting its width.
const originalSizeFits = ref(false)

const measureOriginalSize = () => {
  originalSizeFits.value = naturalWidth() < Math.floor(boundaryWidth())
}

const resizeTo = (w: number) => frame.value?.resizeTo({ w })

const toolbarActions = computed<ImageToolbarAction[]>(() => [
  {
    key: 'alternativeText',
    label: __('Alternative text'),
    icon: 'input-cursor-text',
    attrs: {
      'aria-haspopup': 'dialog',
      'aria-expanded': !!altForm.value,
      'aria-controls': altForm.value ? altFormId : undefined,
    },
    showDivider: true,
    onClick: openAltForm,
  },
  {
    key: 'smallSize',
    label: __('Small size'),
    icon: 'arrows-angle-contract',
    // Never enlarges an image that is smaller already.
    onClick: () => resizeTo(Math.min(SMALL_IMAGE_WIDTH, naturalWidth())),
  },
  ...(originalSizeFits.value
    ? [
        {
          key: 'originalSize',
          label: __('Original size'),
          icon: 'recycle',
          onClick: () => resizeTo(naturalWidth()),
        },
      ]
    : []),
  {
    key: 'fitToWidth',
    label: __('Fit to width'),
    icon: 'arrows-fullscreen',
    showDivider: true,
    onClick: () => resizeTo(Infinity),
  },
  {
    key: 'removeImage',
    label: __('Remove image'),
    icon: 'trash3',
    variant: 'danger',
    onClick: deleteImage,
  },
])
</script>

<template>
  <NodeViewWrapper
    as="div"
    class="relative inline-block max-w-full"
    :class="{
      'opacity-50': uploadPending || uploadInsideOtherEditor,
    }"
  >
    <ImageUploadInsideOtherEditor v-if="uploadInsideOtherEditor" :width="width" :height="height" />
    <button
      v-else-if="!isResizing && src"
      class="relative inline-block max-w-full"
      :class="[
        classes.imageHandler.imageButton,
        { [classes.imageHandler.selectedImage]: selected },
      ]"
      :disabled="uploadFailed"
      @click="startResizing"
      @keydown.space.prevent="startResizing"
      @keydown.enter.prevent="startResizing"
    >
      <ImageFailedUploadOverlay
        v-if="uploadFailed"
        :width="`${isResized ? `${width}px` : '100%'}`"
        :height="`${isResized ? `${height}px` : 'auto'}`"
      >
        <template v-if="failedDueToCors" #default>
          {{ $t('Inserting image not possible due to source restrictions') }}
        </template>
      </ImageFailedUploadOverlay>

      <img
        class="block"
        :src="src"
        :alt="node.attrs.alt"
        v-bind="sizeAttributes"
        :title="node.attrs.title"
        :draggable="isDraggable"
        @load="onLoadImage"
      />
    </button>
    <DraggableResizable
      v-else-if="src && !uploadFailed"
      ref="frame"
      v-model:active="isResizing"
      :class="classes.imageHandler.resizeFrame"
      layout="flow"
      :boundary="FRAME_BOUNDARY"
      lock-aspect-ratio
      keyboard
      :aria-label="node.attrs.alt || $t('Image')"
      v-bind="frameAccessibility"
      :toolbar-label="$t('Image actions')"
      :ignore-outside="isInFloatingPopover"
      @mousedown.prevent
      @keydown.stop="editBesideImage"
      @keydown.enter="deactivateOnEnter"
      @resize-start="resizeStarted = true"
      @resize-end="stopResizing"
    >
      <!-- Below the image only, where the library places it by default: placed `auto`, it flips above
        an image as far down as the sticky editor toolbar, counting the room behind it as free. -->
      <template v-if="toolbar" #toolbar>
        <component :is="toolbar" ref="toolbar-content" :actions="toolbarActions" />
      </template>

      <img
        ref="frame-image"
        class="block"
        :class="{ 'size-full': resizeStarted }"
        v-bind="sizeAttributes"
        :alt="$t('Resize frame')"
        :src="src"
        :draggable="isDraggable"
        @load="measureOriginalSize"
      />
    </DraggableResizable>
  </NodeViewWrapper>
</template>
