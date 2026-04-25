<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import { baseColors } from '#shared/components/Form/fields/FieldEditor/features/color-picker/colors/colors-base.ts'
import { neutralColors } from '#shared/components/Form/fields/FieldEditor/features/color-picker/colors/colors-neutral.ts'
import ColorSchemeList from '#shared/components/Form/fields/FieldEditor/features/color-picker/ColorSchemeList.vue'
import { getEditorColorMenuClasses } from '#shared/components/Form/fields/FieldEditor/features/color-picker/initializeEditorColorMenuClasses.ts'
import { getFieldEditorClasses } from '#shared/components/Form/initializeFieldEditor.ts'

import type { Editor } from '@tiptap/vue-3'

const props = defineProps<{
  editor?: Editor
}>()

const emit = defineEmits<{
  action: [string]
}>()

const editor = toRef(props, 'editor')

const classes = getFieldEditorClasses()
const menuClasses = getEditorColorMenuClasses()

const handleSelectColor = (color: string) => {
  emit('action', color)
}

const unsetColor = () => {
  if (!props.editor) return

  props.editor.commands.unsetColor()

  handleSelectColor('auto')
}
</script>

<template>
  <div v-if="editor" class="relative">
    <div
      data-test-id="color-menu-action-bar"
      class="relative mx-auto scroll-bar-hidden flex max-w-md flex-col overflow-x-auto overflow-y-hidden"
      :class="classes.actionBar.tableMenuContainer"
      role="toolbar"
      tabindex="0"
    >
      <div class="grid grid-cols-5" :class="classes.actionBar.tableMenuGrid">
        <ColorSchemeList
          v-for="(palette, index) in baseColors"
          :key="`palette-${index}`"
          :class="menuClasses.colorSchemeList.base"
          :editor="editor"
          :color-palette="palette"
          @select-color="handleSelectColor"
        />
      </div>

      <ColorSchemeList
        :class="menuClasses.colorSchemeList.base"
        :editor="editor"
        orientation="horizontal"
        :color-palette="neutralColors"
        @select-color="handleSelectColor"
      >
        <button
          v-tooltip="i18n.t('Reset text color')"
          class="col-span-2 rounded-xs"
          :class="menuClasses.colorSchemeList.autoButton"
          type="button"
          @click="unsetColor"
        >
          <CommonIcon
            class="mx-auto"
            :class="menuClasses.colorSchemeList.autoButtonIcon"
            name="editor-text-color"
            size="tiny"
          />
        </button>
      </ColorSchemeList>
    </div>
  </div>
</template>
