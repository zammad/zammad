<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import ColorSchemeList from '#shared/components/Form/fields/FieldEditor/FieldEditorColorMenu/ColorSchemeList.vue'
import { getEditorColorMenuClasses } from '#shared/components/Form/fields/FieldEditor/FieldEditorColorMenu/initializeEditorColorMenu.ts'
import { useColorPallet } from '#shared/components/Form/fields/FieldEditor/FieldEditorColorMenu/useColorPallet.ts'
import { getFieldEditorClasses } from '#shared/components/Form/initializeFieldEditor.ts'

import type { Editor } from '@tiptap/vue-3'

const props = defineProps<{
  editor?: Editor
}>()

const emit = defineEmits<{
  action: [string]
}>()

const editor = toRef(props, 'editor')

const { accentColorPallet, neutralColorPallet } = useColorPallet()

const classes = getFieldEditorClasses()
const menuClasses = getEditorColorMenuClasses()

const handleSelectColor = (color: string) => {
  emit('action', color)
}
</script>

<template>
  <div v-if="editor" class="relative">
    <div
      ref="colorMenuActionBar"
      data-test-id="color-menu-action-bar"
      class="Menubar relative flex max-w-md flex-col flex-wrap overflow-x-auto overflow-y-hidden"
      :class="[classes.actionBar.tableMenuContainer]"
      role="toolbar"
      tabindex="0"
    >
      <ColorSchemeList
        v-for="(color, index) in neutralColorPallet"
        :key="`${color}-${index}`"
        :class="[menuClasses.colorSchemeList.base]"
        :editor="editor"
        orientation="horizontal"
        :color-scheme="color"
        @select-color="handleSelectColor"
      />

      <div class="flex gap-1">
        <ColorSchemeList
          v-for="(color, index) in accentColorPallet"
          :key="`${color}-${index}`"
          :editor="editor"
          :color-scheme="color"
          @select-color="handleSelectColor"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.Menubar {
  -ms-overflow-style: none; /* Internet Explorer 10+ */
  scrollbar-width: none; /* Firefox */

  &::-webkit-scrollbar {
    display: none; /* Safari and Chrome */
  }
}
</style>
