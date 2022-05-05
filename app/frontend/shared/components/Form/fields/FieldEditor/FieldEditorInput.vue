<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { FormFieldContext } from '@shared/components/Form/types/field'
import { useEditor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import { watch } from 'vue'

interface Props {
  context: FormFieldContext
}

const props = defineProps<Props>()

// TODO: add maybe something to extract the props from the context, instead of using context.XYZ (or props.context.XYZ)

const editor = useEditor({
  extensions: [StarterKit],
  editorProps: {
    attributes: {
      role: 'textbox',
      'aria-labelledby': props.context.id,
    },
  },
  // eslint-disable-next-line no-underscore-dangle
  content: props.context._value,
  onUpdate: ({ editor }) => {
    props.context.node.input(editor.getHTML())
  },
})

watch(
  () => props.context.id,
  (id) => {
    editor.value?.setOptions({
      editorProps: {
        attributes: {
          role: 'textbox',
          'aria-labelledby': id,
        },
      },
    })
  },
)

// Set the new editor value, when it was changed from outside (e.G. form schema update).
props.context.node.on('input', ({ payload: value }) => {
  if (editor.value && value !== editor.value.getHTML()) {
    editor.value.commands.setContent(value, false)
  }
})
</script>

<template>
  <EditorContent v-bind:editor="editor" />
</template>
