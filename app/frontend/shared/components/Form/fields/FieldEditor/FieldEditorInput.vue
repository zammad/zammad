<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useEditor, EditorContent } from '@tiptap/vue-3'
import { type Editor } from '@tiptap/vue-3'
import { useEventListener } from '@vueuse/core'
import { computed, onMounted, onUnmounted, ref, toRef, useTemplateRef, watch } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import { useAttachments } from '#shared/components/Form/fields/FieldEditor/composables/useAttachments.ts'
import { useSignatureHandling } from '#shared/components/Form/fields/FieldEditor/composables/useSignatureHandling.ts'
import { EXTENSION_NAME as userMentionExtensionName } from '#shared/components/Form/fields/FieldEditor/extensions/UserMention.ts'
import {
  imageExtensionName,
  getCustomExtensions,
  getHtmlExtensions,
  getPlainExtensions,
  PlaceholderExtensionName,
} from '#shared/components/Form/fields/FieldEditor/extensions.ts'
import FieldEditorFooter from '#shared/components/Form/fields/FieldEditor/FieldEditorFooter.vue'
import type {
  EditorContentType,
  EditorCustomExtensions,
  FieldEditorContext,
  FieldEditorProps,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import {
  getFieldEditorClasses,
  getEditorComponents,
} from '#shared/components/Form/initializeFieldEditor.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { getButtonGroup } from '#shared/components/ObjectAttributes/attributes/AttributeRichtext/initializeRichtextButtons.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { htmlCleanup } from '#shared/utils/htmlCleanup.ts'

import { TableKitExtensionName } from './extensions/TableKit.ts'
import { useInlineMode } from './useInlineMode.ts'

interface Props {
  context: FormFieldContext<FieldEditorProps>
}

const props = defineProps<Props>()

const placeholder = props.context.placeholder
  ? props.context.placeholder
  : props.context.inline
    ? __('Click to edit…')
    : ''

const getEditorContent = (editor: Editor, type: EditorContentType) => {
  if (type === 'text/plain') return editor.getText()

  const content = editor.getHTML()

  return editor.isEmpty ? '' : content
}

const actionBarComponent = getEditorComponents().actionBar

const reactiveContext = toRef(props, 'context')
const { currentValue } = useValue(reactiveContext)

const disabledExtensions = Object.entries(props.context.meta || {})
  .filter(([, value]) => value.disabled)
  .map(([key]) => key as EditorCustomExtensions | string)

const disableExtension = (extensionName: EditorCustomExtensions | string) => {
  if (disabledExtensions.includes(extensionName)) return
  disabledExtensions.push(extensionName)
}

const contentType = computed<EditorContentType>(() => props.context.contentType || 'text/html')

const isPlainText = computed(() => contentType.value === 'text/plain')

// Disable user mention and image extensions in plain text mode.
if (isPlainText.value) {
  disableExtension(userMentionExtensionName)
  disableExtension(imageExtensionName)
}

const { hasPermission } = useSessionStore()

const customExtensions = getCustomExtensions(reactiveContext)

// Disable all custom extensions and tables for the basic set.
if (props.context.extensionSet === 'basic') {
  customExtensions.forEach((extension) =>
    disableExtension(extension.name as EditorCustomExtensions),
  )

  disableExtension(TableKitExtensionName)
}

if (placeholder === '') disableExtension(PlaceholderExtensionName)

// TODO: extensions are in general not reactive in TipTap, we need to check if all things are working as expected.
// TODO: Maybe we need a re-creation of the editor in some edge cases... plain <-> html (check against simple channels...)
const editorExtensions = computed(() => {
  const baseExtensions = isPlainText.value
    ? getPlainExtensions(placeholder, props.context?.meta)
    : getHtmlExtensions(placeholder, props.context?.meta)

  const availableExtensions = [...baseExtensions, ...customExtensions].filter((extension) => {
    const { name, options } = extension

    if (disabledExtensions.includes(name as EditorCustomExtensions)) return false
    if (options?.permission && !hasPermission(options.permission)) return false

    return true
  })

  return availableExtensions
})

const showActionBar = ref(false)
const editorValue = ref<string>(VITE_TEST_MODE ? props.context._value : '')

const { hasImageExtension, loadFiles } = useAttachments(
  editorExtensions.value,
  props.context.formId,
)

const editor = useEditor({
  extensions: editorExtensions.value,
  textDirection: 'auto',
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
    const value = getEditorContent(editor as Editor, contentType.value)
    props.context.node.input(value)

    if (!VITE_TEST_MODE) return
    editorValue.value = value
  },
  onFocus() {
    showActionBar.value = true

    if (!isInlineMode.value) return

    isEditing.value = true
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
  if (!editor.value || content === undefined) return

  editor.value.commands.setContent(contentType === 'text/html' ? htmlCleanup(content) : content, {
    emitUpdate,
  })
}

// Set the new editor content, when the value was changed from outside (e.g. form schema update).
const updateValueKey = props.context.node.on('input', ({ payload: newContent }) => {
  // Early return when no editor exists, keep this in mind, when we have real initial value problems.
  if (!editor.value) return

  const currentContent = getEditorContent(editor.value, contentType.value)

  // Skip the update if the value is identical.
  if (newContent === currentContent) return

  setEditorContent(newContent, contentType.value, true)
})

// Convert the current editor content, if the content type changed from outside (e.g. form schema update).
const updateContentTypeKey = props.context.node.on(
  'prop:contentType',
  ({ payload: newContentType }) => {
    if (!editor.value) return

    const newContent = getEditorContent(editor.value, newContentType)

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

  // ⚠️ Keep in mind for htmlExtension we count characters based on the serialized HTML, not text content as CharacterCount does.
  // It is opauce to the user that the counts differs from the input
  // f.e.g. <b>bold</b> is 13 characters, but user would expect 4 characters.
  return editor.value.storage.characterCount.characters({
    node: editor.value.state.doc,
  })
})

const { addSignature, removeSignature } = useSignatureHandling(editor)

const editorCustomContext = {
  _loaded: true,
  getEditorValue: (type: EditorContentType) => {
    if (!editor.value) return ''

    return getEditorContent(editor.value, type)
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

const buttonGroup = getButtonGroup()

const wrapperElement = useTemplateRef('wrapper')

const {
  isInlineMode,
  isSubmitting,
  isEditing,
  onWrapperClick,
  handleCancel,
  handleChange,
  labelInlineDesktopClasses,
  containerInlineDesktopClasses,
  wrapperInlineDesktopClasses,
  inputInlineDesktopTextStyles,
} = useInlineMode(toRef(props, 'context'), wrapperElement)

watch(isEditing, (editing) => {
  if (!isInlineMode.value && editing) return

  // augmenting type mess up the entire type interface
  // @ts-expect-error @ts-ignore
  editor.value?.storage?.characterCount?.clearWarnings?.()
})

const reclaimEditorFocus = (event: MouseEvent) => {
  // Place cursor at end when clicking the wrapper directly (not editor content).
  // Should be true only for inline mode, when button group is not sticky.
  if ((event.target as HTMLElement).getAttribute('data-field') === 'wrapper')
    editor.value?.commands.focus('end')
}
</script>

<template>
  <!-- TODO: questionable usability - it moves, when new line is added -->
  <!-- eslint-disable vuejs-accessibility/no-static-element-interactions -->
  <div
    ref="wrapper"
    :role="isInlineMode ? 'button' : undefined"
    tabindex="-1"
    class="flex flex-col relative"
    :class="[
      containerInlineDesktopClasses,
      {
        'show-action-bar': isEditing,
      },
    ]"
    @click="onWrapperClick"
    @keydown.space="onWrapperClick"
  >
    <!-- Check if SR label is present on FormKit level labelSrOnly must be true -->
    <CommonLabel
      v-if="context.labelSrOnly && context.label && isInlineMode && !isEditing"
      class="absolute top-4 rtl:right-1 ltr:left-1"
      :class="labelInlineDesktopClasses"
      size="small"
    >
      {{ context.label }}
    </CommonLabel>

    <!-- We don't need to make thi div a11y, since it affects only no SR users.    -->
    <!-- eslint-disable-next-line vuejs-accessibility/click-events-have-key-events   -->
    <div
      :class="[
        classes.input.container,
        wrapperInlineDesktopClasses,
        {
          [classes.input.inlineContainer]: isInlineMode,
        },
      ]"
      data-field="wrapper"
      @click="reclaimEditorFocus"
    >
      <EditorContent
        class="text-base cursor-text"
        data-test-id="field-editor"
        :editor="editor"
        :style="inputInlineDesktopTextStyles"
      />

      <FieldEditorFooter
        v-if="context.meta?.footer && !context.meta.footer.disabled && editor"
        :footer="context.meta.footer"
        :characters="characters"
      />

      <!-- BUTTON group is only implemented in DESKTOP -->
      <component
        :is="buttonGroup"
        v-if="isInlineMode && buttonGroup"
        class="sticky bottom-0 float-right"
        :class="{ invisible: !isEditing }"
        :submit-disabled="isSubmitting"
        :cancel-disabled="isSubmitting"
        @click.stop
        @cancel="handleCancel"
        @submit="handleChange"
      />
    </div>

    <component
      :is="actionBarComponent"
      :class="{
        invisible: isInlineMode && !isEditing,
      }"
      :editor="editor"
      :content-type="contentType"
      :visible="showActionBar"
      :disabled-extensions="disabledExtensions"
      :form-context="reactiveContext"
      :is-editing="isEditing"
      :is-inline-mode="isInlineMode"
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

  /* DESKTOP ONLY CLASS  */
  p.is-editor-empty:first-child::before {
    color: var(--color-gray-100);
    content: attr(data-placeholder);
    float: left;
    height: 0;
    pointer-events: none;
    font-size: var(--text-sm);
  }

  &:focus p.is-editor-empty:first-child::before {
    content: none;
  }
}

[data-theme='dark'] {
  /* DESKTOP ONLY CLASS  */
  p.is-editor-empty:first-child::before {
    color: var(--color-neutral-400);
  }
}

.show-action-bar {
  .tiptap {
    p:first-child::before {
      content: none;
    }
  }
}

.tableWrapper {
  position: relative;
  overflow-x: auto;
  max-width: 100%;
}

.resize-cursor {
  cursor: ew-resize;
  cursor: col-resize;
}
</style>
