<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->
<script lang="ts" setup>
import { useEventListener } from '@vueuse/core'
import { computed, readonly, ref } from 'vue'

import getUuid from '#shared/utils/getUuid.ts'

interface Props {
  label: string
  /**
   * horizontal line or vertical line
   * */
  orientation?: 'horizontal' | 'vertical'
  values?: {
    /**
     * Maximum width/height in px value of what the container can be resized to
     * */
    max?: number | string
    /**
     * Minimum width/height in px value of what the container can be resized to
     * */
    min?: number | string
    /**
     * Current width/height in px value of the container
     * */
    current?: number | string
  }
  disabled?: boolean
  buttonClass?: string
}

const props = withDefaults(defineProps<Props>(), {
  orientation: 'vertical',
})

const resizeLine = ref<HTMLDivElement>()
const resizing = ref(false)

const emit = defineEmits<{
  'mousedown-event': [MouseEvent]
  'touchstart-event': [TouchEvent]
  'dblclick-event': [MouseEvent]
}>()

const resizeOrientation = computed(() =>
  // Vertical resize line should have horizontal aria-orientation  -> container width
  // Horizontal resize line should have vertical aria-orientation -> container height
  props.orientation === 'horizontal' ? 'vertical' : 'horizontal',
)

const addRemoveResizingListener = (event: 'mouseup' | 'touchend') => {
  useEventListener(
    event,
    () => {
      resizing.value = false
    },
    { once: true },
  )
}

const handleMousedown = (event: MouseEvent) => {
  if (props.disabled) return

  emit('mousedown-event', event)
  resizing.value = true

  addRemoveResizingListener('mouseup')
}

const handleTouchstart = (event: TouchEvent) => {
  if (props.disabled) return

  emit('touchstart-event', event)
  resizing.value = true

  addRemoveResizingListener('touchend')
}

const handleDoubleClick = (event: MouseEvent) => {
  if (props.disabled) return

  emit('dblclick-event', event)
  resizeLine.value?.blur()
}

const id = getUuid()

defineExpose({
  resizeLine,
  resizing: readonly(resizing),
})
</script>
<template>
  <div
    class="flex justify-center opacity-0 focus-within:opacity-100 hover:opacity-100"
    :class="
      {
        horizontal: 'h-[12px] w-full',
        vertical: 'h-full w-[12px]',
      }[orientation]
    "
  >
    <button
      ref="resizeLine"
      v-tooltip="!disabled ? label : undefined"
      :aria-describedby="id"
      :disabled="disabled"
      tabindex="0"
      class="not-disabled:bg-neutral-500 focus-within:bg-blue-800! not-disabled:hover:bg-blue-600 focus:outline-hidden disabled:pointer-events-none not-disabled:dark:bg-gray-200 not-disabled:dark:hover:bg-blue-900"
      :class="[
        { 'bg-blue-800!': resizing },
        {
          horizontal: 'h-1 w-full enabled:cursor-row-resize!',
          vertical: 'h-full w-1 enabled:cursor-col-resize!',
        }[orientation],
        buttonClass,
      ]"
      @mousedown="handleMousedown"
      @blur="resizing = false"
      @touchstart="handleTouchstart"
      @dblclick="handleDoubleClick"
    />

    <span
      v-if="!disabled"
      :id="id"
      role="separator"
      class="invisible absolute -z-20"
      :aria-orientation="resizeOrientation"
      :aria-valuenow="values?.current ?? undefined"
      :aria-valuemax="values?.max ?? undefined"
      :aria-valuemin="values?.min ?? undefined"
    />
  </div>
</template>
