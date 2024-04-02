<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, onUnmounted, ref } from 'vue'
import { onClickOutside, type UseElementBoundingReturn } from '@vueuse/core'
import { onKeyUp, useElementBounding, useWindowSize } from '@vueuse/core'

import stopEvent from '#shared/utils/events.ts'
import { getFirstFocusableElement } from '#shared/utils/getFocusableElements.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import testFlags from '#shared/utils/testFlags.ts'

import { usePopoverInstances } from './usePopoverInstances.ts'
import type {
  ArrowPlacement,
  CommonPopoverInternalInstance,
  Oritentation,
} from './types'

export interface Props {
  owner: HTMLElement | undefined
  orientation?: Oritentation
  arrowPlacement?: ArrowPlacement
}

const props = withDefaults(defineProps<Props>(), {
  arrowPlacement: 'start',
  orientation: 'autoVertical',
})

const emit = defineEmits<{
  (e: 'open'): void
  (e: 'close'): void
}>()

const popoverElement = ref<HTMLElement>()

const showPopover = ref(false)

let targetElementBounds: UseElementBoundingReturn
const windowSize = useWindowSize()

const hasDirectionUp = computed(() => {
  if (!targetElementBounds || !windowSize.height) return false
  return targetElementBounds.y.value > windowSize.height.value / 2
})

const hasDirectionRight = computed(() => {
  if (!targetElementBounds || !windowSize.width) return false

  return targetElementBounds.x.value < windowSize.width.value / 2
})

const autoOrientation = computed(() => {
  if (props.orientation === 'autoVertical') {
    return hasDirectionUp.value ? 'top' : 'bottom'
  }

  if (props.orientation === 'autoHorizontal') {
    return hasDirectionRight.value ? 'right' : 'left'
  }

  return props.orientation
})

const verticalOrientation = computed(() => {
  return autoOrientation.value === 'top' || autoOrientation.value === 'bottom'
})

const currentArrowPlacement = computed(() => {
  if (verticalOrientation.value) {
    return props.arrowPlacement
  }

  if (hasDirectionUp.value) {
    return 'end'
  }

  return 'start'
})

const OUTSIDE_DISTANCE_ARROW = 28
const ARROW_HEIGHT = 16

const popoverStyle = computed(() => {
  if (!targetElementBounds) return { top: 0, left: 0, maxHeight: 0 }

  const maxHeight = hasDirectionUp.value
    ? targetElementBounds.top.value
    : windowSize.height.value - targetElementBounds.bottom.value

  const style: Record<string, string> = {
    maxHeight: `${verticalOrientation.value ? maxHeight - 24 : maxHeight + 34}px`,
  }

  const targetElementBoundsOutside =
    targetElementBounds.width.value / 2 - OUTSIDE_DISTANCE_ARROW

  if (verticalOrientation.value && currentArrowPlacement.value === 'end') {
    style.right = `${windowSize.width.value - targetElementBounds.right.value + 10}px`
  } else if (
    verticalOrientation.value &&
    currentArrowPlacement.value === 'start'
  ) {
    style.left = `${targetElementBounds.left.value + targetElementBoundsOutside}px`
  } else if (
    !verticalOrientation.value &&
    currentArrowPlacement.value === 'start'
  ) {
    style.top = `${targetElementBounds.top.value + targetElementBoundsOutside}px`
  } else if (
    !verticalOrientation.value &&
    currentArrowPlacement.value === 'end'
  ) {
    style.bottom = `${windowSize.height.value - targetElementBounds.bottom.value + 10}px`
  }

  switch (autoOrientation.value) {
    case 'top':
      style.bottom = `${windowSize.height.value - targetElementBounds.top.value + ARROW_HEIGHT}px`
      break
    case 'bottom':
      style.top = `${
        targetElementBounds.top.value +
        targetElementBounds.height.value +
        ARROW_HEIGHT
      }px`
      break
    case 'left':
      style.right = `${windowSize.width.value - targetElementBounds.left.value + ARROW_HEIGHT}px`
      break
    case 'right':
      style.left = `${targetElementBounds.right.value + ARROW_HEIGHT}px`
      break
    default:
  }

  return style
})

const arrowPlacementClasses = computed(() => {
  const classes: Record<string, boolean> = {
    // eslint-disable-next-line zammad/zammad-tailwind-ltr
    '-translate-x-1/2': verticalOrientation.value,
    '-translate-y-1/2': !verticalOrientation.value,
  }

  switch (autoOrientation.value) {
    case 'bottom':
      Object.assign(classes, {
        '-top-[11px]': true,
        'border-l-0 border-b-0': true,
      })
      break
    case 'top':
      Object.assign(classes, {
        '-bottom-[11px]': true,
        'border-r-0 border-t-0': true,
      })
      break
    case 'left':
      Object.assign(classes, {
        // eslint-disable-next-line zammad/zammad-tailwind-ltr
        '-right-[11px]': true,
        'border-t-0 border-l-0': true,
      })
      break
    case 'right':
      Object.assign(classes, {
        // eslint-disable-next-line zammad/zammad-tailwind-ltr
        '-left-[11px]': true,
        'border-b-0 border-r-0': true,
      })
      break
    default:
  }

  if (verticalOrientation.value && currentArrowPlacement.value === 'end') {
    // eslint-disable-next-line zammad/zammad-tailwind-ltr
    classes['right-2'] = true
  } else if (
    verticalOrientation.value &&
    currentArrowPlacement.value === 'start'
  ) {
    // eslint-disable-next-line zammad/zammad-tailwind-ltr
    classes['left-7'] = true
  } else if (
    !verticalOrientation.value &&
    currentArrowPlacement.value === 'start'
  ) {
    classes['top-7'] = true
  } else if (
    !verticalOrientation.value &&
    currentArrowPlacement.value === 'end'
  ) {
    classes['bottom-2'] = true
  }

  return classes
})

useTrapTab(popoverElement)

const { instances } = usePopoverInstances()

const closePopover = () => {
  if (!showPopover.value) return

  showPopover.value = false
  emit('close')

  nextTick(() => {
    props.owner?.focus()
    testFlags.set('common-select.closed')
  })
}

const openPopover = () => {
  if (showPopover.value) return

  targetElementBounds = useElementBounding(props.owner)

  instances.value.forEach((instance) => {
    if (instance.isOpen.value) instance.closePopover()
  })

  showPopover.value = true
  emit('open')

  onClickOutside(popoverElement, closePopover, {
    ignore: [props.owner],
  })

  requestAnimationFrame(() => {
    nextTick(() => {
      const firstFocusable = getFirstFocusableElement(popoverElement.value)
      firstFocusable?.focus()
      firstFocusable?.scrollIntoView({ block: 'nearest' })
      testFlags.set('common-popover.opened')
    })
  })
}

const togglePopover = () => {
  if (showPopover.value) {
    closePopover()
  } else {
    openPopover()
  }
}

onKeyUp('Escape', (e) => {
  if (!showPopover.value) return

  stopEvent(e)
  closePopover()
})

const exposedInstance: CommonPopoverInternalInstance = {
  isOpen: computed(() => showPopover.value),
  openPopover,
  closePopover,
  togglePopover,
}

instances.value.add(exposedInstance)

onUnmounted(() => {
  instances.value.delete(exposedInstance)
})

defineExpose(exposedInstance)

const duration = VITE_TEST_MODE ? undefined : { enter: 300, leave: 200 }
</script>

<template>
  <Teleport to="body">
    <Transition name="fade" :duration="duration">
      <div
        v-if="showPopover"
        ref="popoverElement"
        role="region"
        class="popover fixed z-50 min-h-9 flex antialiased rounded-xl border border-neutral-100 dark:border-gray-900 bg-white dark:bg-gray-500"
        :style="popoverStyle"
        :aria-labelledby="owner?.id"
      >
        <div class="overflow-y-auto"><slot /></div>
        <div
          class="absolute -z-10 w-[22px] h-[22px] -rotate-45 bg-white dark:bg-gray-500 transform border border-neutral-100 dark:border-gray-900"
          :class="arrowPlacementClasses"
        ></div>
      </div>
    </Transition>
  </Teleport>
</template>
