<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useIntersectionObserver } from '@vueuse/core'
import { useTemplateRef } from 'vue'

import type { EditorButton } from '#shared/components/Form/fields/FieldEditor/types.ts'

import type { Editor } from '@tiptap/core'

interface Props {
  action: EditorButton
  actionBar: HTMLDivElement | null
  editor?: Editor
  isActive?: (type: string, attributes?: Record<string, unknown>) => boolean
}

const props = defineProps<Props>()

const emit = defineEmits<{
  click: [MouseEvent]
  visible: [boolean]
}>()

const button = useTemplateRef('button')

const { pause: pauseIntersectionObserver, resume: resumeIntersectionObserver } =
  useIntersectionObserver(
    button,
    ([{ isIntersecting, target }]) => {
      ;(target as HTMLButtonElement).disabled = !(isIntersecting && !props.action.disabled)
      emit('visible', isIntersecting ?? false)
    },
    {
      root: props.actionBar,
      threshold: 0.1,
    },
  )

defineExpose({
  pauseIntersectionObserver,
  resumeIntersectionObserver,
})
</script>

<template>
  <button
    ref="button"
    v-tooltip="$t(action.label || action.name)"
    type="button"
    class="transition-color relative flex items-center gap-1 rounded-lg p-1.5 focus-visible-app-default hover:bg-blue-600 hover:text-black active:bg-blue-800! active:text-white aria-expanded:text-white dark:hover:bg-blue-900 dark:hover:text-white"
    :class="[
      action.class,
      {
        'bg-blue-800! text-white': isActive?.(action.name, action.attributes),
      },
    ]"
    :disabled="action.disabled"
    :aria-label="$t(action.label || action.name)"
    :aria-pressed="isActive?.(action.name, action.attributes)"
    tabindex="-1"
    @click="$emit('click', $event)"
  >
    <CommonIcon :name="action.icon" size="tiny" decorative />
    <CommonIcon
      v-if="action.subMenu"
      name="chevron-down"
      :fixed-size="{ width: 10, height: 10 }"
      decorative
    />
    <div
      v-if="action.name === 'textColor'"
      class="color-indicator absolute start-1/2 bottom-[0.4rem] box-content h-1.5 w-1.5 rounded-[1px] border border-blue-50 ltr:-translate-x-[0.25rem] rtl:translate-x-[0.25rem] dark:border-gray-800"
      :style="{
        backgroundColor: props.editor?.getAttributes('textStyle')?.color
          ? props.editor.getAttributes('textStyle').color
          : 'rgb(0, 0, 0)',
      }"
    />
  </button>
</template>

<style scoped>
[data-theme='dark'] .color-indicator {
  /* auto */
  &[style*='background-color: rgb(0, 0, 0)'] {
    background-color: rgb(255, 255, 255) !important;
  }

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
