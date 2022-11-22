<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { FormFieldContext } from '@shared/components/Form/types/field'
import { convertFileList } from '@shared/utils/files'
import { useEditor, EditorContent } from '@tiptap/vue-3'
import { useEventListener } from '@vueuse/core'
import { ref, toRef, watch } from 'vue'
import useValue from '../../composables/useValue'
import getExtensions from './extensions/list'
import type { EditorCustomPlugins, FieldEditorProps } from './types'
import FieldEditorActionBar from './FieldEditorActionBar.vue'

interface Props {
  context: FormFieldContext<FieldEditorProps>
}

const props = defineProps<Props>()

const reactiveContext = toRef(props, 'context')
const { currentValue } = useValue(reactiveContext)

// TODO: add maybe something to extract the props from the context, instead of using context.XYZ (or props.context.XYZ)

const disabledPlugins = Object.entries(props.context.meta || {})
  .filter(([, value]) => value.disabled)
  .map(([key]) => key as EditorCustomPlugins)

const editorExtensions = getExtensions(reactiveContext).filter(
  (extension) =>
    !disabledPlugins.includes(extension.name as EditorCustomPlugins),
)

const showActionBar = ref(false)
const editor = useEditor({
  extensions: editorExtensions,
  editorProps: {
    attributes: {
      role: 'textbox',
      name: props.context.node.name,
      id: props.context.id,
      class: 'min-h-[80px]',
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
  onUpdate({ editor }) {
    const html = editor.getHTML()
    if (html === '<p></p>') {
      props.context.node.input('')
    } else {
      props.context.node.input(html)
    }
  },
  onFocus() {
    showActionBar.value = true
  },
  onBlur() {
    props.context.handlers.blur()
  },
})

watch(
  () => props.context.id,
  (id) => {
    editor.value?.setOptions({
      editorProps: {
        attributes: {
          role: 'textbox',
          name: props.context.node.name,
          id,
          class: 'min-h-[80px]',
        },
      },
    })
  },
)

// TODO: https://github.com/ueberdosis/tiptap/issues/3289
//   At the moment the "setEditable" change triggers a "onUpdate", which triggers a unwanted input event with the current value.
// watch(
//   () => props.context.disabled,
//   (disabled) => {
//     editor.value?.setEditable(!disabled)
//     if (disabled && showActionBar.value) {
//       showActionBar.value = false
//     }
//   },
// )

// Set the new editor value, when it was changed from outside (e.G. form schema update).
props.context.node.on('input', ({ payload: value }) => {
  if (editor.value && value !== editor.value.getHTML()) {
    editor.value.commands.setContent(value, false)
  }
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
</script>

<template>
  <EditorContent
    ref="editorVueInstance"
    data-test-id="field-editor"
    class="px-2 py-2"
    :editor="editor"
  />
  <FieldEditorActionBar
    :editor="editor"
    :visible="showActionBar"
    :disabled-plugins="disabledPlugins"
    @hide="showActionBar = false"
    @blur="focusEditor"
  />
</template>
