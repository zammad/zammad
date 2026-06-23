<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useActiveElement } from '@vueuse/core'
import { computed, useTemplateRef, watch } from 'vue'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'

import CollapseButton from '#desktop/components/CollapseButton/CollapseButton.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import ResizeLine from '#desktop/components/ResizeLine/ResizeLine.vue'
import { useResizeLine } from '#desktop/components/ResizeLine/useResizeLine.ts'
import { useAppBreakpoints } from '#desktop/composables/responsiveness/useAppBreakpoints.ts'

import { SidebarName, SidebarPosition } from './types.ts'
import { useSidebarDisplay } from './useSidebarDisplay.ts'

interface Props {
  name: SidebarName
  currentWidth?: number | string
  minWidth?: number | string
  maxWidth?: number | string
  noScroll?: boolean
  collapsible?: boolean
  iconCollapsed?: string
  position?: SidebarPosition
  /**
   * Allow resizing will always be false on smaller screens,
   * @see useAppBreakpoints().isSmallScreen
   */
  resizable?: boolean
  id: string
  noPadding?: boolean
  classes?: {
    resizeLine?: string
    collapseButton?: string
  }
  backgroundVariant?: 'primary' | 'secondary'
}

const props = withDefaults(defineProps<Props>(), {
  position: SidebarPosition.Start,
  backgroundVariant: 'primary',
  hideButtonWhenCollapsed: false,
})

const emit = defineEmits<{
  'resize-horizontal': [number]
  'resize-horizontal-start': []
  'resize-horizontal-end': []
  'reset-width': []
  collapse: []
  expand: []
}>()

const { isSidebarCollapsed, toggleSidebar } = useSidebarDisplay(props.name)

const onToggleSidebar = () => {
  const isCollapsed = toggleSidebar()

  if (isCollapsed) emit('collapse')
  else emit('expand')
}

const backgroundVariantClass = computed(() => {
  switch (props.backgroundVariant) {
    case 'secondary':
      return 'bg-blue-50 dark:bg-gray-800'
    case 'primary':
    default:
      return 'bg-neutral-950'
  }
})

// a11y keyboard navigation // TS: Does not infer type for some reason?
const resizeLineInstance = useTemplateRef<InstanceType<typeof ResizeLine>>('resize-line')

const activeElement = useActiveElement()

const handleKeyStroke = (e: KeyboardEvent, adjustment: number) => {
  if (!props.currentWidth || activeElement.value !== resizeLineInstance.value?.resizeLine) return

  e.preventDefault()

  const newWidth = Number(props.currentWidth) + adjustment

  emit('resize-horizontal', newWidth)
}

const { startResizing, isResizing } = useResizeLine(
  (positionX) => emit('resize-horizontal', positionX),
  resizeLineInstance.value?.resizeLine,
  handleKeyStroke,
  {
    calculateFromRight: props.position === SidebarPosition.End,
    orientation: 'vertical',
  },
)

watch(isResizing, (isResizing) => {
  if (isResizing) {
    emit('resize-horizontal-start')
    return
  }

  emit('resize-horizontal-end')
})

const collapseButtonClass = computed(() => {
  if (props.position === SidebarPosition.Start) return 'ltr:rounded-l-none rtl:rounded-r-none'
  if (props.position === SidebarPosition.End) return 'ltr:rounded-r-none rtl:rounded-l-none'

  return ''
})

const { isSmallScreen } = useAppBreakpoints()

const isResizable = computed(() => props.resizable && !isSmallScreen.value)

const { isTouchDevice } = useTouchDevice()
</script>

<template>
  <aside
    :id="id"
    class="relative flex max-h-screen flex-col overflow-y-clip border-neutral-100 dark:border-gray-900 print:hidden"
    :class="[
      {
        'py-3': isSidebarCollapsed && !noPadding,
        'border-s': position === SidebarPosition.End,
      },
      backgroundVariantClass,
    ]"
  >
    <CommonButton
      v-if="iconCollapsed && isSidebarCollapsed"
      class="mx-auto"
      size="large"
      data-test-id="action-button"
      variant="neutral"
      :icon="iconCollapsed"
      @click="onToggleSidebar()"
    />
    <div
      v-else
      class="flex h-full max-w-full flex-col overflow-x-hidden"
      :class="{
        'px-3 py-2.5': !isSidebarCollapsed && !noPadding,
        'overflow-y-hidden': noScroll,
        'overflow-y-auto': !noScroll,
        'border-e border-neutral-100 dark:border-gray-900':
          backgroundVariant === 'secondary' && SidebarPosition.Start,
        'border-s border-neutral-100 dark:border-gray-900':
          backgroundVariant === 'secondary' && SidebarPosition.End,
      }"
    >
      <slot v-bind="{ isCollapsed: isSidebarCollapsed, toggleCollapse: onToggleSidebar }" />
    </div>

    <ResizeLine
      v-if="isResizable"
      ref="resize-line"
      :label="$t('Resize sidebar')"
      class="absolute z-30 has-[+div:hover]:opacity-100"
      :class="[
        {
          'ltr:right-0 ltr:translate-x-1/2 rtl:left-0 rtl:-translate-x-1/2':
            position === SidebarPosition.Start,
          'ltr:left-0 ltr:-translate-x-1/2 rtl:right-0 rtl:translate-x-1/2':
            position === SidebarPosition.End,
          peer: !resizeLineInstance?.resizing,
        },
        classes?.resizeLine || '',
      ]"
      :values="{
        max: Number(maxWidth)?.toFixed(2),
        min: minWidth,
        current: currentWidth,
      }"
      :disabled="isSidebarCollapsed"
      @mousedown-event="startResizing"
      @touchstart-event="startResizing"
      @dblclick-event="$emit('reset-width')"
    />

    <CollapseButton
      v-if="collapsible && !isTouchDevice"
      :collapsed="isSidebarCollapsed"
      :owner-id="id"
      class="absolute top-12.25 z-30 hidden peer-hover:opacity-100 lg:flex"
      :inverse="position === SidebarPosition.End"
      variant="tertiary-gray"
      :collapse-label="$t('Collapse sidebar')"
      :expand-label="$t('Expand sidebar')"
      :class="[
        {
          'ltr:right-0 ltr:translate-x-[calc(100%-10px)] rtl:left-0 rtl:-translate-x-[calc(100%-10px)]':
            position === SidebarPosition.Start,
          'ltr:left-0 ltr:-translate-x-[calc(100%-10px)] rtl:right-0 rtl:translate-x-[calc(100%-10px)]':
            position === SidebarPosition.End,
          'ltr:translate-x-[calc(100%-7.5px)] rtl:-translate-x-[calc(100%-7.5px)]':
            isSidebarCollapsed && position === SidebarPosition.Start,
          'ltr:-translate-x-[calc(100%-7.5px)] rtl:translate-x-[calc(100%-7.5px)]':
            isSidebarCollapsed && position === SidebarPosition.End,
        },
        classes?.collapseButton || '',
      ]"
      :button-class="collapseButtonClass"
      @click="(node: MouseEvent) => (node.target as HTMLButtonElement)?.blur()"
      @toggle-collapse="onToggleSidebar"
    />
  </aside>
</template>
