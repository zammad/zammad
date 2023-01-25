<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import stopEvent from '@shared/utils/events'
import type { Editor } from '@tiptap/vue-3'
import { useTraverseOptions } from '@shared/composables/useTraverseOptions'
import { onKeyDown, useEventListener, whenever } from '@vueuse/core'
import { nextTick, ref, toRef } from 'vue'
import type { Ref } from 'vue'
import useEditorActions from './useEditorActions'
import type { EditorContentType, EditorCustomPlugins } from './types'

const props = defineProps<{
  editor?: Editor
  contentType: EditorContentType
  visible: boolean
  disabledPlugins: EditorCustomPlugins[]
}>()

const emit = defineEmits<{
  (e: 'hide'): void
  (e: 'blur'): void
}>()

const actionBar = ref<HTMLElement>()
const editor = toRef(props, 'editor')

const { actions, isActive } = useEditorActions(
  editor,
  props.contentType,
  props.disabledPlugins,
)

const opacityGradientEnd = ref('0')
const opacityGradientStart = ref('0')

const restoreScroll = () => {
  const menuBar = actionBar.value as HTMLElement
  // restore scroll position, if needed
  menuBar.scroll(0, 0)
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

const hideAfterLeaving = () => {
  restoreScroll()
  emit('hide')
}

useTraverseOptions(actionBar, { direction: 'horizontal' })
</script>

<template>
  <div v-show="visible" class="relative">
    <div
      ref="actionBar"
      data-test-id="action-bar"
      class="Menubar relative flex max-w-full gap-1 overflow-x-auto overflow-y-hidden p-2"
      role="toolbar"
      tabindex="0"
      @keydown.tab="hideAfterLeaving"
      @scroll.passive="recalculateOpacity"
    >
      <button
        v-for="action in actions"
        :key="action.name"
        type="button"
        :class="[
          'rounded bg-black p-2 lg:hover:bg-gray-300',
          action.class,
          { '!bg-gray-300': isActive(action.name, action.attributes) },
        ]"
        :aria-label="action.label || action.name"
        :aria-pressed="isActive(action.name, action.attributes)"
        tabindex="-1"
        @click="action.command"
      >
        <CommonIcon :name="action.icon" size="small" decorative />
      </button>
    </div>
    <div
      class="ShadowGradient LeftGradient"
      :style="{ opacity: opacityGradientStart }"
    ></div>
    <div
      class="ShadowGradient RightGradient"
      :style="{ opacity: opacityGradientEnd }"
    ></div>
  </div>
</template>

<style scoped lang="scss">
.Menubar {
  -ms-overflow-style: none; /* Internet Explorer 10+ */
  scrollbar-width: none; /* Firefox */

  &::-webkit-scrollbar {
    display: none; /* Safari and Chrome */
  }
}

.ShadowGradient {
  @apply absolute h-full w-8;
}

.ShadowGradient::before {
  content: '';
  position: absolute;
  top: calc(0px - 30px - 1.5rem);
  height: calc(30px + 1.5rem);
  pointer-events: none;
}

.LeftGradient::before {
  left: -0.5rem;
  right: 0;
  background: linear-gradient(
    270deg,
    rgba(255, 255, 255, 0),
    theme('colors.gray.500')
  );
}

.RightGradient {
  right: 0;
}

.RightGradient::before {
  right: 0;
  left: 0;
  background: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0),
    theme('colors.gray.500')
  );
}
</style>
