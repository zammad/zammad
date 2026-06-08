<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { getEditorColorMenuClasses } from '#shared/components/Form/fields/FieldEditor/features/color-picker/initializeEditorColorMenuClasses.ts'
import { getFieldEditorClasses } from '#shared/components/Form/initializeFieldEditor.ts'
import { useAppName } from '#shared/composables/useAppName.ts'

import type { PaletteColor } from './colors/types.ts'
import type { Editor } from '@tiptap/core'

interface Props {
  editor: Editor
  colorPalette: PaletteColor[]
  orientation?: 'horizontal' | 'vertical'
}

const props = withDefaults(defineProps<Props>(), {
  orientation: 'vertical',
})

const emit = defineEmits<{
  'select-color': [string]
}>()

const orientationClass = computed(() => {
  return props.orientation === 'horizontal' ? 'grid-cols-5' : 'grid-rows-4'
})

const setColor = (color: string) => {
  if (!props.editor) return

  props.editor.commands.setColor(color)

  emit('select-color', color)
}

const checkActiveColor = (color: string) => {
  return props.editor?.getAttributes('textStyle').color === color
}

const classes = getFieldEditorClasses()
const { colorSchemeList: colorSchemeListClasses } = getEditorColorMenuClasses()

const appName = useAppName()
</script>

<template>
  <div
    role="listbox"
    class="grid"
    :class="[
      orientationClass,
      {
        Mobile: appName === 'mobile',
      },
    ]"
  >
    <button
      v-for="(color, index) in colorPalette"
      :key="`${color.value}-${index}`"
      v-tooltip="i18n.t(color.label, index + 1)"
      role="option"
      type="button"
      :aria-selected="checkActiveColor(color.value)"
      :class="[classes.actionBar.button.base, colorSchemeListClasses.button]"
      class="relative aspect-square rounded-xs"
      :style="{ backgroundColor: color.value }"
      @click="setColor(color.value)"
    >
      <CommonIcon
        v-if="checkActiveColor(color.value)"
        size="xs"
        class="absolute top-1/2 z-10 -translate-y-1/2 text-white ltr:left-1/2 ltr:-translate-x-1/2 rtl:right-1/2 rtl:translate-x-1/2 dark:text-black"
        name="editor-action-checkmark"
      />
    </button>
    <slot />
  </div>
</template>

<style scoped>
.Mobile button,
[data-theme='dark'] button {
  /* neutral 1 */
  &[style*='background-color: rgb(102, 102, 102)'] {
    background-color: rgb(204, 204, 204) !important;
  }

  /* neutral 2 is the same for both themes */

  /* neutral 3 */
  &[style*='background-color: rgb(204, 204, 204)'] {
    background-color: rgb(102, 102, 102) !important;
  }

  /* red 1 */
  &[style*='background-color: rgb(239, 68, 68)'] {
    background-color: rgb(241, 152, 167) !important;
  }

  /* orange 1 */
  &[style*='background-color: rgb(205, 121, 45)'] {
    background-color: rgb(246, 211, 102) !important;
  }

  /* green 1 */
  &[style*='background-color: rgb(80, 140, 70)'] {
    background-color: rgb(170, 214, 164) !important;
  }

  /* blue 1 */
  &[style*='background-color: rgb(48, 100, 172)'] {
    background-color: rgb(122, 202, 247) !important;
  }

  /* purple 1 */
  &[style*='background-color: rgb(107, 41, 132)'] {
    background-color: rgb(201, 135, 236) !important;
  }

  /* red 2 */
  &[style*='background-color: rgb(235, 61, 79)'] {
    background-color: rgb(237, 97, 118) !important;
  }

  /* orange 2 */
  &[style*='background-color: rgb(233, 159, 59)'] {
    background-color: rgb(243, 193, 79) !important;
  }

  /* green 2 */
  &[style*='background-color: rgb(95, 159, 84)'] {
    background-color: rgb(127, 187, 118) !important;
  }

  /* blue 2 */
  &[style*='background-color: rgb(70, 147, 231)'] {
    background-color: rgb(91, 174, 243) !important;
  }

  /* purple 2 */
  &[style*='background-color: rgb(153, 62, 195)'] {
    background-color: rgb(179, 91, 223) !important;
  }

  /* red 3 */
  &[style*='background-color: rgb(237, 97, 118)'] {
    background-color: rgb(235, 61, 79) !important;
  }

  /* orange 3 */
  &[style*='background-color: rgb(243, 193, 79)'] {
    background-color: rgb(233, 159, 59) !important;
  }

  /* green 3 */
  &[style*='background-color: rgb(127, 187, 118)'] {
    background-color: rgb(95, 159, 84) !important;
  }

  /* blue 3 */
  &[style*='background-color: rgb(91, 174, 243)'] {
    background-color: rgb(70, 147, 231) !important;
  }

  /* purple 3 */
  &[style*='background-color: rgb(179, 91, 223)'] {
    background-color: rgb(153, 62, 195) !important;
  }

  /* red 4 */
  &[style*='background-color: rgb(241, 152, 167)'] {
    background-color: rgb(239, 68, 68) !important;
  }

  /* orange 4 */
  &[style*='background-color: rgb(246, 211, 102)'] {
    background-color: rgb(205, 121, 45) !important;
  }

  /* green 4 */
  &[style*='background-color: rgb(170, 214, 164)'] {
    background-color: rgb(80, 140, 70) !important;
  }

  /* blue 4 */
  &[style*='background-color: rgb(122, 202, 247)'] {
    background-color: rgb(48, 100, 172) !important;
  }

  /* purple 4 */
  &[style*='background-color: rgb(201, 135, 236)'] {
    background-color: rgb(107, 41, 132) !important;
  }
}
</style>
