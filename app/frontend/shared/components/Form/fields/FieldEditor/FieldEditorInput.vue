<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useEditor, EditorContent } from '@tiptap/vue-3'
import { useEventListener } from '@vueuse/core'
import { computed, onMounted, onUnmounted, ref, toRef, watch } from 'vue'

import { getFieldEditorClasses } from '#shared/components/Form/initializeFieldEditor.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { htmlCleanup } from '#shared/utils/htmlCleanup.ts'
import log from '#shared/utils/log.ts'
import testFlags from '#shared/utils/testFlags.ts'

import useValue from '../../composables/useValue.ts'
import { getNodeByName } from '../../utils.ts'

import {
  getCustomExtensions,
  getHtmlExtensions,
  getPlainExtensions,
} from './extensions/List.ts'
import FieldEditorActionBar from './FieldEditorActionBar.vue'
import FieldEditorFooter from './FieldEditorFooter.vue'
import FieldEditorTableMenu from './FieldEditorTableMenu.vue'
import { PLUGIN_NAME as userMentionPluginName } from './suggestions/UserMention.ts'
import { convertInlineImages } from './utils.ts'

import type {
  EditorContentType,
  EditorCustomPlugins,
  FieldEditorContext,
  FieldEditorProps,
  PossibleSignature,
} from './types.ts'
import type { Editor } from '@tiptap/vue-3'

interface Props {
  context: FormFieldContext<FieldEditorProps>
}

const props = defineProps<Props>()

const reactiveContext = toRef(props, 'context')
const { currentValue } = useValue(reactiveContext)

const disabledPlugins = Object.entries(props.context.meta || {})
  .filter(([, value]) => value.disabled)
  .map(([key]) => key as EditorCustomPlugins)

const contentType = computed<EditorContentType>(
  () => props.context.contentType || 'text/html',
)

// remove user mention in plain text mode and inline images
if (contentType.value === 'text/plain') {
  disabledPlugins.push(userMentionPluginName, 'image')
}

const editorExtensions =
  contentType.value === 'text/plain'
    ? getPlainExtensions()
    : getHtmlExtensions()

getCustomExtensions(reactiveContext).forEach((extension) => {
  if (!disabledPlugins.includes(extension.name as EditorCustomPlugins)) {
    editorExtensions.push(extension)
  }
})

const hasImageExtension = editorExtensions.some(
  (extension) => extension.name === 'image',
)
const showActionBar = ref(false)
const editorValue = ref<string>(VITE_TEST_MODE ? props.context._value : '')

interface LoadImagesOptions {
  attachNonInlineFiles: boolean
}

const inlineImagesInEditor = (editor: Editor, files: File[]) => {
  convertInlineImages(files, editor.view.dom).then(async (urls) => {
    if (editor?.isDestroyed) return
    editor?.commands.setImages(urls)
  })
}

const addFilesToAttachments = (files: File[]) => {
  const attachmentsContext = getNodeByName(props.context.formId, 'attachments')
    ?.context as unknown as
    | { uploadFiles?: (files: File[]) => void }
    | undefined
  if (attachmentsContext && !attachmentsContext.uploadFiles) {
    log.error(
      '[FieldEditorInput] Attachments field was found, but it doesn\'t provide "uploadFiles" method.',
    )
  } else {
    attachmentsContext?.uploadFiles?.(files)
  }
}

// there is also a gif, but desktop only inlines these two for now
const imagesMimeType = ['image/png', 'image/jpeg']
const loadFiles = (
  files: FileList | File[] | null | undefined,
  editor: Editor | undefined,
  options: LoadImagesOptions,
) => {
  if (!files) {
    return false
  }

  const inlineImages: File[] = []
  const otherFiles: File[] = []

  for (const file of files) {
    if (imagesMimeType.includes(file.type)) {
      inlineImages.push(file)
    } else {
      otherFiles.push(file)
    }
  }

  if (inlineImages.length && editor) {
    inlineImagesInEditor(editor, inlineImages)
  }

  if (options.attachNonInlineFiles && otherFiles.length) {
    addFilesToAttachments(otherFiles)
  }

  return Boolean(
    inlineImages.length || (options.attachNonInlineFiles && otherFiles.length),
  )
}

const editor = useEditor({
  extensions: editorExtensions,
  editorProps: {
    attributes: {
      role: 'textbox',
      name: props.context.node.name,
      id: props.context.id,
      class: props.context.classes.input,
      'data-value': editorValue.value, // for testing, do not delete
      'data-form-id': props.context.formId,
    },
    // add inlined files
    handlePaste(view, event) {
      if (!hasImageExtension) {
        return
      }

      const items = Array.from(event.clipboardData?.items || [])
      for (const item of items) {
        if (item.type.startsWith('image')) {
          const file = item.getAsFile()

          if (file) {
            const loaded = loadFiles([file], editor.value, {
              attachNonInlineFiles: false,
            })

            if (loaded) {
              event.preventDefault()
              return true
            }
          }
        } else {
          return false
        }
      }

      return false
    },
    handleDrop(view, event) {
      if (!hasImageExtension) {
        return
      }
      const e = event as unknown as InputEvent
      const files = e.dataTransfer?.files || null
      const loaded = loadFiles(files, editor.value, {
        attachNonInlineFiles: true,
      })
      if (loaded) {
        event.preventDefault()
        return true
      }
      return false
    },
  },
  editable: props.context.disabled !== true,
  content:
    currentValue.value && contentType.value === 'text/html'
      ? htmlCleanup(currentValue.value)
      : currentValue.value,
  onUpdate({ editor }) {
    const content =
      contentType.value === 'text/plain' ? editor.getText() : editor.getHTML()
    const value = content === '<p></p>' ? '' : content
    props.context.node.input(value)

    if (!VITE_TEST_MODE) return
    editorValue.value = value
  },
  onFocus() {
    showActionBar.value = true
  },
  onBlur() {
    props.context.handlers.blur()
  },
})

if (VITE_TEST_MODE) {
  watch(
    () => [props.context.id, editorValue.value],
    ([id, value]) => {
      editor.value?.setOptions({
        editorProps: {
          attributes: {
            role: 'textbox',
            name: props.context.node.name,
            id,
            class: props.context.classes.input,
            'data-value': value,
            'data-form-id': props.context.formId,
          },
        },
      })
    },
  )
}

watch(
  () => props.context.disabled,
  (disabled) => {
    editor.value?.setEditable(!disabled, false)
    if (disabled && showActionBar.value) {
      showActionBar.value = false
    }
  },
)

const setEditorContent = (
  content: string | undefined,
  contentType: EditorContentType,
  emitUpdate?: boolean,
) => {
  if (!editor.value || !content) return

  editor.value.commands.setContent(
    contentType === 'text/html' ? htmlCleanup(content) : content,
    emitUpdate,
  )
}

// Set the new editor content, when the value was changed from outside (e.g. form schema update).
const updateValueKey = props.context.node.on(
  'input',
  ({ payload: newContent }) => {
    const currentContent =
      contentType.value === 'text/plain'
        ? editor.value?.getText()
        : editor.value?.getHTML()

    // Skip the update if the value is identical.
    if (newContent === currentContent) return

    setEditorContent(newContent, contentType.value, true)
  },
)

// Convert the current editor content, if the content type changed from outside (e.g. form schema update).
const updateContentTypeKey = props.context.node.on(
  'prop:contentType',
  ({ payload: newContentType }) => {
    const newContent =
      newContentType === 'text/plain'
        ? editor.value?.getText()
        : editor.value?.getHTML()

    setEditorContent(newContent, newContentType, true)
  },
)

onUnmounted(() => {
  props.context.node.off(updateValueKey)
  props.context.node.off(updateContentTypeKey)
})

const focusEditor = () => {
  const view = editor.value?.view
  view?.focus()
}

// focus editor when clicked on its label
useEventListener('click', (e) => {
  const label = document.querySelector(`label[for="${props.context.id}"]`)
  if (label === e.target) focusEditor()
})

// insert signature before full article blockquote or at the end of the document
const resolveSignaturePosition = (editor: Editor) => {
  let blockquotePosition: number | null = null
  editor.state.doc.descendants((node, pos) => {
    if (
      (node.type.name === 'paragraph' || node.type.name === 'blockquote') &&
      node.attrs['data-marker'] === 'signature-before'
    ) {
      blockquotePosition = pos
      return false
    }
  })
  if (blockquotePosition !== null) {
    return { position: 'before', from: blockquotePosition }
  }
  return { position: 'after', from: editor.state.doc.content.size || 0 }
}

const addSignature = (signature: PossibleSignature) => {
  if (!editor.value || editor.value.isDestroyed || !editor.value.isEditable)
    return
  const currentPosition = editor.value.state.selection.anchor
  const positionFromEnd = editor.value.state.doc.content.size - currentPosition
  // don't use "chain()", because we change positions a lot
  // and chain doesn't know about it
  editor.value.commands.removeSignature()
  const { position, from } = resolveSignaturePosition(editor.value)
  editor.value.commands.addSignature({ ...signature, position, from })
  const getNewPosition = (editor: Editor) => {
    if (signature.position != null) {
      return signature.position
    }
    if (currentPosition < from) {
      return currentPosition
    }
    if (from === 0 && currentPosition <= 1) {
      return 1
    }
    return editor.state.doc.content.size - positionFromEnd
  }
  // calculate new position from the end of the signature otherwise
  editor.value.commands.focus(getNewPosition(editor.value))
  requestAnimationFrame(() => {
    testFlags.set('editor.signatureAdd')
  })
}

const removeSignature = () => {
  if (!editor.value || editor.value.isDestroyed || !editor.value.isEditable)
    return
  const currentPosition = editor.value.state.selection.anchor
  editor.value.chain().removeSignature().focus(currentPosition).run()
  requestAnimationFrame(() => {
    testFlags.set('editor.removeSignature')
  })
}

const characters = computed(() => {
  if (contentType.value === 'text/plain') {
    return currentValue.value?.length || 0
  }
  if (!editor.value) return 0
  return editor.value.storage.characterCount.characters({
    node: editor.value.state.doc,
  })
})

const editorCustomContext = {
  _loaded: true,
  getEditorValue: (type: EditorContentType) => {
    if (!editor.value) return ''

    return type === 'text/plain'
      ? editor.value.getText()
      : editor.value.getHTML()
  },
  addSignature,
  removeSignature,
  focus: focusEditor,
}

Object.assign(props.context, editorCustomContext)

onMounted(() => {
  const onLoad = props.context.onLoad as ((
    context: FieldEditorContext,
  ) => void)[]
  onLoad.forEach((fn) => fn(editorCustomContext))
  onLoad.length = 0

  if (VITE_TEST_MODE) {
    if (!('editors' in globalThis))
      Object.defineProperty(globalThis, 'editors', { value: {} })
    Object.defineProperty(
      Reflect.get(globalThis, 'editors'),
      props.context.node.name,
      { value: editor.value, configurable: true },
    )
  }
})

const classes = getFieldEditorClasses()
</script>

<template>
  <div :class="classes.input.container">
    <EditorContent
      class="text-base ltr:text-left rtl:text-right"
      data-test-id="field-editor"
      :editor="editor"
    />
    <FieldEditorFooter
      v-if="context.meta?.footer && !context.meta.footer.disabled && editor"
      :footer="context.meta.footer"
      :characters="characters"
    />

    <FieldEditorTableMenu
      v-if="editor"
      :editor="editor"
      :content-type="contentType"
      :form-id="context.formId"
    />
  </div>

  <!-- TODO: questionable usability - it moves, when new line is added -->
  <FieldEditorActionBar
    :editor="editor"
    :content-type="contentType"
    :visible="showActionBar"
    :disabled-plugins="disabledPlugins"
    :form-id="context.formId"
    @hide="showActionBar = false"
    @blur="focusEditor"
  />
</template>

<style>
.tiptap {
  pre {
    background-color: #ced4da;
    border-radius: 6px;
    padding: 5px;
    margin-bottom: 6px;
    color: #111;
  }

  pre > code {
    background-color: transparent;
    padding: 0;
    margin: 0;
  }

  code {
    background-color: #ced4da;
    border-radius: 4px;
    padding: 1px 2px;
    color: #111;
  }

  table {
    border-collapse: collapse;
    table-layout: fixed;
    width: 100px;
    max-width: 200px;
    margin: 0;
    overflow: hidden;

    td,
    th {
      min-width: 1em;
      border: 2px solid #ced4da;
      padding: 3px 5px;
      vertical-align: top;
      box-sizing: border-box;
      position: relative;

      > * {
        margin-bottom: 0;
      }
    }

    th {
      font-weight: bold;
      text-align: left;
      background-color: #f1f3f5;
    }

    .selectedCell::after {
      z-index: 2;
      position: absolute;
      content: '';
      left: 0;
      right: 0;
      top: 0;
      bottom: 0;
      background: rgba(200, 200, 255, 0.4);
      pointer-events: none;
    }

    .column-resize-handle {
      position: absolute;
      right: -2px;
      top: 0;
      bottom: -2px;
      width: 4px;
      background-color: #adf;
      pointer-events: none;
    }

    p {
      margin: 0;
    }
  }
}

.tableWrapper {
  padding: 1rem 0;
  overflow-x: auto;
  max-width: 100%;
}

.resize-cursor {
  cursor: ew-resize;
  cursor: col-resize;
}
</style>
