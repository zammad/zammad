<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useEditor, EditorContent } from '@tiptap/vue-3'
import { useEventListener } from '@vueuse/core'
import { computed, onMounted, onUnmounted, ref, toRef, watch } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import { useAttachments } from '#shared/components/Form/fields/FieldEditor/composables/useAttachments.ts'
import { useSignatureHandling } from '#shared/components/Form/fields/FieldEditor/composables/useSignatureHandling.ts'
import { PLUGIN_NAME as userMentionPluginName } from '#shared/components/Form/fields/FieldEditor/extensions/UserMention.ts'
import {
  getCustomExtensions,
  getHtmlExtensions,
  getPlainExtensions,
} from '#shared/components/Form/fields/FieldEditor/extensions.ts'
import FieldEditorTableMenu from '#shared/components/Form/fields/FieldEditor/features/table/EditorTableMenu.vue'
import FieldEditorFooter from '#shared/components/Form/fields/FieldEditor/FieldEditorFooter.vue'
import type {
  EditorContentType,
  EditorCustomPlugins,
  FieldEditorContext,
  FieldEditorProps,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import {
  getFieldEditorClasses,
  getEditorComponents,
} from '#shared/components/Form/initializeFieldEditor.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { htmlCleanup } from '#shared/utils/htmlCleanup.ts'

interface Props {
  context: FormFieldContext<FieldEditorProps>
}

const props = defineProps<Props>()

const actionBarComponent = getEditorComponents().actionBar

const reactiveContext = toRef(props, 'context')
const { currentValue } = useValue(reactiveContext)

const disabledPlugins = Object.entries(props.context.meta || {})
  .filter(([, value]) => value.disabled)
  .map(([key]) => key as EditorCustomPlugins)

const contentType = computed<EditorContentType>(() => props.context.contentType || 'text/html')

const isPlainText = computed(() => contentType.value === 'text/plain')

// remove user mention in plain text mode and inline images
if (isPlainText.value) {
  disabledPlugins.push(userMentionPluginName, 'image')
}

const { hasPermission } = useSessionStore()

const customExtensions = getCustomExtensions(reactiveContext)

// TODO: extensions are in general not reactive in TipTap, we need to check if all things are working as expected.
// TODO: Maybe we need a re-creation of the editor in some edge cases... plain <-> html (check against simple channels...)
const availableCustomExtensions = computed(() =>
  customExtensions.filter((extension) => {
    const { name, options } = extension

    if (disabledPlugins.includes(name as EditorCustomPlugins)) {
      return false
    }
    if (options?.permission && !hasPermission(options.permission)) {
      return false
    }

    return true
  }),
)

const editorExtensions = computed(() => {
  const baseExtensions = isPlainText.value ? getPlainExtensions() : getHtmlExtensions()
  return [...baseExtensions, ...availableCustomExtensions.value]
})

const showActionBar = ref(false)
const editorValue = ref<string>(VITE_TEST_MODE ? props.context._value : '')

const { hasImageExtension, loadFiles } = useAttachments(
  editorExtensions.value,
  props.context.formId,
)

const hasTableExtension = computed(() =>
  editorExtensions.value.some((ext) => ext.name === 'tableKit'),
)

const editor = useEditor({
  extensions: editorExtensions.value,
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
      if (!hasImageExtension.value) return

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
      if (!hasImageExtension.value) return

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
    const content = isPlainText.value ? editor.getText() : editor.getHTML()
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

  editor.value.commands.setContent(contentType === 'text/html' ? htmlCleanup(content) : content, {
    emitUpdate,
  })
}

// Set the new editor content, when the value was changed from outside (e.g. form schema update).
const updateValueKey = props.context.node.on('input', ({ payload: newContent }) => {
  const currentContent = isPlainText.value ? editor.value?.getText() : editor.value?.getHTML()

  // Skip the update if the value is identical.
  if (newContent === currentContent) return

  setEditorContent(newContent, contentType.value, true)
})

// Convert the current editor content, if the content type changed from outside (e.g. form schema update).
const updateContentTypeKey = props.context.node.on(
  'prop:contentType',
  ({ payload: newContentType }) => {
    const newContent =
      newContentType === 'text/plain' ? editor.value?.getText() : editor.value?.getHTML()

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

const characters = computed(() => {
  if (isPlainText.value) {
    return currentValue.value?.length || 0
  }
  if (!editor.value) return 0
  return editor.value.storage.characterCount.characters({
    node: editor.value.state.doc,
  })
})

const { addSignature, removeSignature } = useSignatureHandling(editor)

const editorCustomContext = {
  _loaded: true,
  getEditorValue: (type: EditorContentType) => {
    if (!editor.value) return ''

    return type === 'text/plain' ? editor.value.getText() : editor.value.getHTML()
  },
  addSignature,
  removeSignature,
  focus: focusEditor,
}

// eslint-disable-next-line vue/no-mutating-props
Object.assign(props.context, editorCustomContext)

onMounted(() => {
  const onLoad = props.context.onLoad as ((context: FieldEditorContext) => void)[]
  onLoad.forEach((fn) => fn(editorCustomContext))
  onLoad.length = 0

  if (VITE_TEST_MODE) {
    if (!('editors' in globalThis)) Object.defineProperty(globalThis, 'editors', { value: {} })
    Object.defineProperty(Reflect.get(globalThis, 'editors'), props.context.node.name, {
      value: editor.value,
      configurable: true,
    })
  }
})

const classes = getFieldEditorClasses()
</script>

<template>
  <!-- TODO: questionable usability - it moves, when new line is added -->
  <div class="flex flex-col">
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
        v-if="editor && hasTableExtension"
        :editor="editor"
        :content-type="contentType"
      />
    </div>

    <component
      :is="actionBarComponent"
      :editor="editor"
      :content-type="contentType"
      :visible="showActionBar"
      :disabled-plugins="disabledPlugins"
      :form-context="reactiveContext"
      @hide="showActionBar = false"
      @blur="focusEditor"
    />
  </div>
</template>

<style>
.tiptap {
  table {
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
  overflow-x: auto;
  max-width: 100%;
}

.resize-cursor {
  cursor: ew-resize;
  cursor: col-resize;
}
</style>
