<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onKeyDown, useEventListener, whenever } from '@vueuse/core'
import { computed, useTemplateRef } from 'vue'
import { nextTick, type Ref, ref, toRef } from 'vue'

import type { EditorButton } from '#shared/components/Form/fields/FieldEditor/types.ts'
import { useTraverseOptions } from '#shared/composables/useTraverseOptions.ts'
import stopEvent from '#shared/utils/events.ts'

import type { Editor } from '@tiptap/core'

interface Props {
  actions: EditorButton[]
  editor?: Editor
  visible?: boolean
  isActive?: (type: string, attributes?: Record<string, unknown>) => boolean
  noGradient?: boolean
}

const actionBar = useTemplateRef('action-bar')

const props = withDefaults(defineProps<Props>(), {
  visible: true,
})

const editor = toRef(props, 'editor')

const emit = defineEmits<{
  hide: []
  blur: []
  'click-action': [EditorButton, MouseEvent]
}>()

const opacityGradientEnd = ref('0')
const opacityGradientStart = ref('0')

const restoreScroll = () => {
  const menuBar = actionBar.value as HTMLElement
  // restore scroll position, if needed
  menuBar.scroll(0, 0)
}

const hideAfterLeaving = () => {
  restoreScroll()
  emit('hide')
}

const recalculateOpacity = () => {
  const target = actionBar.value
  if (!target) {
    return
  }
  const scrollMin = 40
  const bottomMax = target.scrollWidth - target.clientWidth
  const bottomMin = bottomMax - scrollMin
  const { scrollLeft } = target
  opacityGradientStart.value = Math.min(1, scrollLeft / scrollMin).toFixed(2)
  const opacityPart = (scrollLeft - bottomMin) / scrollMin
  opacityGradientEnd.value = Math.min(1, 1 - opacityPart).toFixed(2)
}

useTraverseOptions(actionBar, { direction: 'horizontal', ignoreTabindex: true })

onKeyDown(
  'Escape',
  (e) => {
    stopEvent(e)
    emit('blur')
  },
  { target: actionBar as Ref<EventTarget> },
)

useEventListener('click', (e) => {
  if (!actionBar.value) return

  const target = e.target as HTMLElement

  if (!actionBar.value.contains(target) && !editor.value?.isFocused) {
    restoreScroll()
    emit('hide')
  }
})

whenever(
  () => props.visible,
  () => nextTick(recalculateOpacity),
)

const disabledActionNames = ref<Set<string>>(new Set())

const activeActions = computed(() =>
  props.actions.filter(({ name }) => !disabledActionNames.value.has(name)),
)

// Unfortunately, we can't rely on mounted or setup hooks here, we need to await the editor to be ready
whenever(
  () => props.editor,
  (editor) => {
    if (!editor) return
    editor?.off('toggle-visibility')
    editor?.on('toggle-visibility', ({ name, active }) => {
      if (active) disabledActionNames.value.delete(name)
      else disabledActionNames.value.add(name)
    })
  },
  { immediate: true, flush: 'post' },
)
</script>

<template>
  <div class="relative">
    <!-- eslint-disable vuejs-accessibility/no-static-element-interactions -->
    <div
      ref="action-bar"
      data-test-id="action-bar"
      class="Menubar relative flex max-w-full items-center gap-1 overflow-x-auto overflow-y-hidden p-2"
      role="toolbar"
      tabindex="0"
      @keydown.tab="hideAfterLeaving"
      @scroll.passive="recalculateOpacity"
    >
      <template v-for="(action, idx) in activeActions" :key="action.name">
        <button
          :title="$t(action.label || action.name)"
          type="button"
          class="relative flex items-center gap-1 rounded bg-black p-2 lg:hover:bg-gray-300"
          :class="[
            action.class,
            {
              'bg-gray-300': isActive?.(action.name, action.attributes),
            },
          ]"
          :disabled="action.disabled"
          :aria-label="$t(action.label || action.name)"
          :aria-pressed="isActive?.(action.name, action.attributes)"
          tabindex="-1"
          @click="
            (event) => {
              action.command?.(event)
              $emit('click-action', action, event)
            }
          "
        >
          <CommonIcon :name="action.icon" size="small" decorative />
          <CommonIcon v-if="action.subMenu" name="caret" size="xs" decorative />
          <div
            v-if="action.name === 'textColor'"
            class="color-indicator absolute bottom-[0.6rem] h-1 w-1 border border-gray-400 rounded-xs box-content start-1/2 rtl:translate-x-1/2 ltr:-translate-x-1/2"
            :style="{
              backgroundColor: props.editor?.getAttributes('textStyle')?.color
                ? props.editor.getAttributes('textStyle').color
                : 'rgb(0, 0, 0)',
            }"
          />
        </button>
        <hr
          v-if="action.showDivider && idx < actions.length - 1"
          :class="action.dividerClass"
          class="h-6 w-px border-0 bg-black"
        />
      </template>
    </div>
    <template v-if="!props.noGradient">
      <div class="ShadowGradient LeftGradient" :style="{ opacity: opacityGradientStart }" />
      <div class="ShadowGradient RightGradient" :style="{ opacity: opacityGradientEnd }" />
    </template>
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

.ShadowGradient {
  position: absolute;
  height: 100%;
  width: 2rem;
}

.ShadowGradient::before {
  border-radius: 0 0 0.5rem;
  content: '';
  position: absolute;
  top: calc(0px - 30px - 1.5rem);
  height: calc(30px + 1.5rem);
  pointer-events: none;
}

.LeftGradient::before {
  border-radius: 0 0 0 0.5rem;
  left: -0.5rem;
  right: 0;
  background: linear-gradient(270deg, rgba(255, 255, 255, 0), #282829);
}

.RightGradient {
  right: 0;
}

.RightGradient::before {
  right: 0;
  left: 0;
  background: linear-gradient(90deg, rgba(255, 255, 255, 0), #282829);
}

.color-indicator {
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

  /* neutral 4 */
  &[style*='background-color: rgb(255, 255, 255)'] {
    background-color: rgb(0, 0, 0) !important;
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
