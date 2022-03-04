<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <EditorContent v-bind:id="context.id" v-bind:editor="editor" />
</template>

<script setup lang="ts">
import type { FormFieldContext } from '@common/types/form'
import { useEditor, EditorContent } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'

interface Props {
  context: FormFieldContext
}

const props = defineProps<Props>()

// TODO: add maybe something to extract the props from the context, instead of using context.XYZ (or props.context.XYZ)

const editor = useEditor({
  extensions: [StarterKit],
  // eslint-disable-next-line no-underscore-dangle
  content: props.context._value,
  onUpdate: ({ editor }) => {
    props.context.node.input(editor.getHTML())
  },
})

// Set the new editor value, when it was changed from outside (e.G. form schema update).
props.context.node.on('input', ({ payload: value }) => {
  if (editor.value && value !== editor.value.getHTML()) {
    editor.value.commands.setContent(value, false)
  }
})
</script>
