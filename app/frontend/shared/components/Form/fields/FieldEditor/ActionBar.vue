<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onKeyDown, useEventListener, whenever } from '@vueuse/core'
import { storeToRefs } from 'pinia'
import { computed, nextTick, type Ref, ref, toRef } from 'vue'

import type { EditorButton } from '#shared/components/Form/fields/FieldEditor/useEditorActions.ts'
import {
  getFieldEditorClasses,
  getFieldEditorProps,
} from '#shared/components/Form/initializeFieldEditor.ts'
import { useTraverseOptions } from '#shared/composables/useTraverseOptions.ts'
import stopEvent from '#shared/utils/events.ts'

// eslint-disable-next-line import/no-restricted-paths
import { useThemeStore } from '#desktop/stores/theme.ts'

import type { Editor } from '@tiptap/core'

interface Props {
  actions: EditorButton[]
  editor?: Editor
  visible?: boolean
  isActive?: (type: string, attributes?: Record<string, unknown>) => boolean
  noGradient?: boolean
}

const actionBar = ref<HTMLElement>()

const props = withDefaults(defineProps<Props>(), {
  visible: true,
})

const editor = toRef(props, 'editor')

const emit = defineEmits<{
  hide: []
  blur: []
  clickAction: [EditorButton, MouseEvent]
}>()

const classes = getFieldEditorClasses()

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

const editorProps = getFieldEditorProps()

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

const { currentTheme } = storeToRefs(useThemeStore())

const checkCurrentTheme = (currentTheme: 'dark' | 'light' | 'auto') => {
  let theme: 'dark' | 'light' = 'dark'

  if (currentTheme === 'light') {
    theme = 'light'
  }
  if (currentTheme === 'auto') {
    const rootElement = document.documentElement
    theme = rootElement.getAttribute('data-theme') as 'dark' | 'light'
  }
  return theme
}

// Css lint rule for v-bind expects this naming convention
const leftgradientbeforebackground = computed(() => {
  const theme = checkCurrentTheme(currentTheme.value)

  return theme === 'dark'
    ? classes.actionBar.leftGradient.before.background.dark
    : classes.actionBar.leftGradient.before.background.light
})

// Css lint rule for v-bind expects this naming convention
const rightgradientbeforebackground = computed(() => {
  const theme = checkCurrentTheme(currentTheme.value)

  return theme === 'dark'
    ? classes.actionBar.rightGradient.before.background.dark
    : classes.actionBar.rightGradient.before.background.light
})

// Css lint rule for v-bind expects this naming convention
const beforegradienttop = computed(
  () => classes.actionBar.shadowGradient.before.top,
)
// Css lint rule for v-bind expects this naming convention
const beforegradientheight = computed(
  () => classes.actionBar.shadowGradient.before.height,
)
// Css lint rule for v-bind expects this naming convention
const leftgradientvalue = computed(() => classes.actionBar.leftGradient.left)
</script>

<template>
  <div class="relative">
    <!-- eslint-disable vuejs-accessibility/no-static-element-interactions -->
    <div
      ref="actionBar"
      data-test-id="action-bar"
      class="Menubar relative flex max-w-full overflow-x-auto overflow-y-hidden"
      :class="[classes.actionBar.buttonContainer]"
      role="toolbar"
      tabindex="0"
      @keydown.tab="hideAfterLeaving"
      @scroll.passive="recalculateOpacity"
    >
      <template v-for="action in actions" :key="action.name">
        <button
          :title="action.label || action.name"
          type="button"
          :class="[
            classes.actionBar.button.base,
            action.class,
            {
              [classes.actionBar.button.active]: isActive?.(
                action.name,
                action.attributes,
              ),
              'color-indicator': action.name === 'textColor',
            },
          ]"
          :disabled="action.disabled"
          :style="{
            '--color-indicator-background': editor?.getAttributes('textStyle')
              ?.color
              ? editor.getAttributes('textStyle').color
              : '#ffffff',
          }"
          :aria-label="action.label || action.name"
          :aria-pressed="isActive?.(action.name, action.attributes)"
          tabindex="-1"
          @click="
            (event) => {
              action.command?.(event)
              $emit('clickAction', action, event)
            }
          "
        >
          <CommonIcon
            :name="action.icon"
            :size="editorProps.actionBar.button.icon.size"
            decorative
          />
        </button>
        <div v-if="action.showDivider">
          <hr class="h-full w-px border-0 bg-neutral-100 dark:bg-gray-900" />
        </div>
      </template>
    </div>
    <template v-if="!props.noGradient">
      <div
        class="ShadowGradient LeftGradient"
        :style="{ opacity: opacityGradientStart }"
      />
      <div
        class="ShadowGradient RightGradient"
        :style="{ opacity: opacityGradientEnd }"
      />
    </template>
  </div>
</template>

<style lang="postcss" scoped>
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
  border-radius: 0 0 0.5rem;
  content: '';
  position: absolute;
  top: v-bind(beforegradienttop);
  height: v-bind(beforegradientheight);
  pointer-events: none;
}

.LeftGradient::before {
  border-radius: 0 0 0 0.5rem;
  left: v-bind(leftgradientvalue);
  right: 0;
  background: v-bind(leftgradientbeforebackground);
}

.RightGradient {
  right: 0;
}

.RightGradient::before {
  right: 0;
  left: 0;
  background: v-bind(rightgradientbeforebackground);
}

.color-indicator {
  --color-indicator-background: transparent;

  @apply relative;

  &::before {
    content: '';
    background: var(--color-indicator-background) !important;

    @apply absolute bottom-1 left-1/2 h-0.5 w-1/3 -translate-x-1/2 rounded-full bg-black;
  }
}
</style>
