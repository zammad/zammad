<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { getEditorColorMenuClasses } from '#shared/components/Form/fields/FieldEditor/FieldEditorColorMenu/initializeEditorColorMenu.ts'
import type {
  ColorGroup,
  ColorScheme,
} from '#shared/components/Form/fields/FieldEditor/FieldEditorColorMenu/types.ts'
import { getFieldEditorClasses } from '#shared/components/Form/initializeFieldEditor.ts'

import type { Editor } from '@tiptap/core'

interface Props {
  editor: Editor
  colorScheme: ColorGroup
  orientation?: 'horizontal' | 'vertical'
}

const props = withDefaults(defineProps<Props>(), {
  orientation: 'vertical',
})

const emit = defineEmits<{
  selectColor: [string]
}>()

const orientationClass = computed(() => {
  return props.orientation === 'horizontal' ? 'flex-row' : 'flex-col'
})

const setColor = (color: ColorScheme) => {
  if (!props.editor) return
  props.editor.commands.setColor(color.value)

  emit('selectColor', color.value)
}

const checkActiveColor = (color: string) => {
  return props.editor?.getAttributes('textStyle').color === color
}

const classes = getFieldEditorClasses()
const { colorSchemeList: colorSchemeListClasses } = getEditorColorMenuClasses()
</script>

<template>
  <div
    role="listbox"
    :aria-label="$t(colorScheme.name)"
    class="flex gap-1"
    :class="[orientationClass]"
  >
    <button
      v-for="(schemeColor, schemeColorIndex) in colorScheme.values"
      :key="`${schemeColor.value}-${schemeColorIndex}`"
      role="option"
      type="button"
      :aria-selected="checkActiveColor(schemeColor.value)"
      :aria-label="$t(schemeColor.label)"
      :class="[classes.actionBar.button.base, colorSchemeListClasses.button]"
      class="relative shrink-0 rounded-sm"
      :style="{ backgroundColor: schemeColor.value }"
      @click="setColor(schemeColor)"
    >
      <CommonIcon
        v-if="checkActiveColor(schemeColor.value)"
        size="xs"
        class="absolute top-1/2 z-10 -translate-y-1/2 text-white ltr:left-1/2 ltr:-translate-x-1/2 rtl:right-1/2 rtl:translate-x-1/2 dark:text-black"
        name="editor-action-checkmark"
      />
    </button>
  </div>
</template>
