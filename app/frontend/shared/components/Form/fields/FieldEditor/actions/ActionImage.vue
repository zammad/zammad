<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { convertFileList } from '@shared/utils/files'
import type { Editor } from '@tiptap/vue-3'
import { ref } from 'vue'

const props = defineProps<{
  editor: Editor
}>()

const inputRef = ref<HTMLElement>()

const insertImage = async (e: Event) => {
  if (!props.editor) return
  const input = e.target as HTMLInputElement
  if (!input.files || !input.files.length) return
  const base64urls = await convertFileList(input.files)
  props.editor.commands.setImages(base64urls)
  input.value = ''
}
</script>

<template>
  <!-- TODO change icon-->
  <CommonIcon name="document" size="small" @click="inputRef?.click()" />
  <input
    ref="inputRef"
    class="hidden"
    type="file"
    multiple
    accept="image/*"
    @change="insertImage"
  />
</template>
