<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { FormFieldContext } from '@shared/components/Form/types/field'
import { convertFileList } from '@shared/utils/files'
import { useEditor, EditorContent } from '@tiptap/vue-3'
import { useEventListener } from '@vueuse/core'
import { ref, toRef, watch } from 'vue'
import useValue from '../../composables/useValue'
import extensions from './extensions/list'

import useEditorActions from './useEditorActions'

interface Props {
  context: FormFieldContext
}

const props = defineProps<Props>()

const { currentValue } = useValue(toRef(props, 'context'))

// TODO: add maybe something to extract the props from the context, instead of using context.XYZ (or props.context.XYZ)

// eslint-disable-next-line vue/no-setup-props-destructure
const initialPlaceholder = props.context.attrs.placeholder

const showActionBar = ref(false)
const editor = useEditor({
  extensions,
  editorProps: {
    attributes: {
      role: 'textbox',
      name: props.context.node.name,
      'aria-labelledby': props.context.id,
      ...(!currentValue.value &&
        initialPlaceholder && { 'aria-placeholder': initialPlaceholder }),
    },
    // add inlined files
    handlePaste(view, event) {
      const files = event.clipboardData?.files || null
      convertFileList(files).then((urls) => {
        editor.value?.commands.setImages(urls)
      })

      if (files && files.length) {
        event.preventDefault()
        return true
      }

      return false
    },
    handleDrop(view, event) {
      const e = event as unknown as InputEvent
      const files = e.dataTransfer?.files || null
      convertFileList(files).then((urls) => {
        editor.value?.commands.setImages(urls)
      })
      if (files && files.length) {
        event.preventDefault()
        return true
      }
      return false
    },
  },
  editable: props.context.disabled !== true,
  content: currentValue.value,
  onUpdate: ({ editor }) => {
    props.context.node.input(editor.getHTML())
  },
  onFocus() {
    showActionBar.value = true
  },
})

watch(
  [
    () => props.context.id,
    () => props.context.attrs.placeholder,
    () => editor.value?.isEmpty,
  ],
  ([id, placeholder, isEmpty]) => {
    editor.value?.setOptions({
      editorProps: {
        attributes: {
          role: 'textbox',
          name: props.context.node.name,
          'aria-labelledby': id,
          ...(isEmpty && placeholder && { 'aria-placeholder': placeholder }),
        },
      },
    })
  },
)

watch(
  () => props.context.disabled,
  (disabled) => {
    editor.value?.setEditable(!disabled)
    if (disabled && showActionBar.value) {
      showActionBar.value = false
    }
  },
)

// Set the new editor value, when it was changed from outside (e.G. form schema update).
props.context.node.on('input', ({ payload: value }) => {
  if (editor.value && value !== editor.value.getHTML()) {
    editor.value.commands.setContent(value, false)
  }
})

const { actions, isActive } = useEditorActions(editor)

const actionBar = ref<HTMLElement>()

useEventListener('click', (e) => {
  if (!actionBar.value || !editor.value) return

  const target = e.target as HTMLElement

  if (!actionBar.value.contains(target) && !editor.value.isFocused) {
    showActionBar.value = false
  }
})
</script>

<template>
  <EditorContent
    data-test-id="field-editor"
    class="editor-content px-4 py-2"
    :editor="editor"
  />
  <div
    v-show="showActionBar"
    ref="actionBar"
    data-test-id="action-bar"
    class="absolute bottom-0 flex max-w-full gap-1 overflow-y-auto bg-black p-2"
  >
    <button
      v-for="action in actions"
      :key="action.name"
      :class="[
        'min-w-[30px] rounded p-2 lg:hover:bg-gray-300',
        action.class,
        { '!bg-gray-300': isActive(action.name, action.attributes) },
      ]"
      :aria-label="action.label || action.name"
      @click="action.command"
    >
      <component
        :is="action.component"
        v-if="action.component"
        :editor="editor"
      />
      <template v-else-if="action.text">
        {{ action.text }}
      </template>
      <CommonIcon v-else-if="action.icon" :name="action.icon" size="small" />
    </button>
  </div>
</template>
