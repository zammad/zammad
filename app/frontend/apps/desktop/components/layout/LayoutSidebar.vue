<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useActiveElement } from '@vueuse/core'
import { ref, watch } from 'vue'

import CollapseButton from '#desktop/components/CollapseButton/CollapseButton.vue'
import { useCollapseHandler } from '#desktop/components/CollapseButton/composables/useCollapseHandler.ts'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useResizeWidthHandle } from '#desktop/components/ResizeHandle/composables/useResizeWidthHandle.ts'
import ResizeHandle from '#desktop/components/ResizeHandle/ResizeHandle.vue'

interface Props {
  name: string
  /**
   @property currentWidth
   @property minWidth
   @property maxWidth
   - used for accessibility
   / */
  currentWidth?: number
  minWidth?: number
  maxWidth?: number
  collapsible?: boolean
  iconCollapsed?: string
  resizable?: boolean
  id: string
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'resize-horizontal': [number]
  'resize-horizontal-start': []
  'resize-horizontal-end': []
  'reset-width': []
  collapse: [boolean]
  expand: [boolean]
}>()

const { toggleCollapse, isCollapsed } = useCollapseHandler(emit, {
  storageKey: `${props.name}-sidebar-collapsed`,
})

// a11y keyboard navigation
const resizeHandleComponent = ref<InstanceType<typeof ResizeHandle>>()

const activeElement = useActiveElement()

const handleKeyStroke = (e: KeyboardEvent, adjustment: number) => {
  e.preventDefault()
  if (
    !props.currentWidth ||
    activeElement.value !== resizeHandleComponent.value?.$el
  )
    return
  const newWidth = props.currentWidth + adjustment
  if (
    props.maxWidth &&
    props.minWidth &&
    (newWidth >= props.maxWidth || newWidth <= props.minWidth)
  )
    return
  emit('resize-horizontal', newWidth)
}

const { startResizing, isResizingHorizontal } = useResizeWidthHandle(
  (positionX) => emit('resize-horizontal', positionX),
  resizeHandleComponent,
  handleKeyStroke,
)

watch(isResizingHorizontal, (isResizing) => {
  if (isResizing) {
    emit('resize-horizontal-start')
  } else {
    emit('resize-horizontal-end')
  }
})
</script>

<template>
  <aside
    :id="props.id"
    class="group/sidebar -:bg-neutral-950 relative flex max-h-screen flex-col border-e border-neutral-100 dark:border-gray-900"
    :class="{
      'py-3': isCollapsed,
    }"
  >
    <CollapseButton
      v-if="collapsible"
      :is-collapsed="isCollapsed"
      :owner-id="id"
      group="sidebar"
      class="absolute top-[49px] z-20 ltr:right-0 ltr:translate-x-1/2 rtl:left-0 rtl:-translate-x-1/2"
      @toggle-collapse="toggleCollapse"
    />
    <ResizeHandle
      v-if="resizable && !isCollapsed"
      ref="resizeHandleComponent"
      class="absolute top-1/2 -translate-y-1/2 ltr:right-0 rtl:left-0"
      :aria-label="$t('Resize sidebar')"
      :aria-valuenow="currentWidth"
      :aria-valuemax="maxWidth?.toFixed(2)"
      :aria-valuemin="minWidth"
      role="separator"
      aria-orientation="horizontal"
      tabindex="0"
      @mousedown="startResizing"
      @touchstart="startResizing"
      @dblclick="$emit('reset-width')"
    />
    <CommonButton
      v-if="iconCollapsed && isCollapsed"
      class="mx-auto"
      size="medium"
      data-test-id="action-button"
      variant="neutral"
      :icon="iconCollapsed"
      @click="toggleCollapse"
    />
    <div
      v-else
      class="flex h-full flex-col overflow-y-auto"
      :class="{ 'p-3': !isCollapsed }"
    >
      <slot v-bind="{ isCollapsed }" />
    </div>
  </aside>
</template>
