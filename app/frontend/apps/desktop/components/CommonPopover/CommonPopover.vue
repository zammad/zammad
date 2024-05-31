<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onClickOutside, type UseElementBoundingReturn } from '@vueuse/core'
import { onKeyUp, useElementBounding, useWindowSize } from '@vueuse/core'
import {
  type ComponentPublicInstance,
  computed,
  nextTick,
  onUnmounted,
  ref,
} from 'vue'

import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import stopEvent from '#shared/utils/events.ts'
import testFlags from '#shared/utils/testFlags.ts'

import { useTransitionConfig } from '#desktop/composables/useTransitionConfig.ts'

import { usePopoverInstances } from './usePopoverInstances.ts'

import type {
  Placement,
  CommonPopoverInternalInstance,
  Orientation,
} from './types'

export interface Props {
  owner: HTMLElement | ComponentPublicInstance | undefined
  orientation?: Orientation
  placement?: Placement
  hideArrow?: boolean
  id?: string
}

const props = withDefaults(defineProps<Props>(), {
  placement: 'start',
  orientation: 'autoVertical',
})

const emit = defineEmits<{
  open: []
  close: []
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

const locale = useLocaleStore()

const autoOrientation = computed(() => {
  if (props.orientation === 'autoVertical') {
    return hasDirectionUp.value ? 'top' : 'bottom'
  }

  if (props.orientation === 'autoHorizontal') {
    return hasDirectionRight.value ? 'right' : 'left'
  }

  if (locale.localeData?.dir === EnumTextDirection.Rtl) {
    if (props.orientation === 'left') return 'right'
    if (props.orientation === 'right') return 'left'
  }

  return props.orientation
})

const verticalOrientation = computed(() => {
  return autoOrientation.value === 'top' || autoOrientation.value === 'bottom'
})

const currentPlacement = computed(() => {
  if (verticalOrientation.value) {
    if (locale.localeData?.dir === EnumTextDirection.Rtl) {
      if (props.placement === 'start') return 'end'
      return 'start'
    }
    return props.placement
  }
  if (hasDirectionUp.value) return 'end'
  return 'start'
})

const BORDER_OFFSET = 2
const PLACEMENT_OFFSET_WO_ARROW = 16
const PLACEMENT_OFFSET_WITH_ARROW = 30
const ORIENTATION_OFFSET_WO_ARROW = 6
const ORIENTATION_OFFSET_WITH_ARROW = 16

const popoverStyle = computed(() => {
  if (!targetElementBounds) return { top: 0, left: 0, maxHeight: 0 }

  const maxHeight = hasDirectionUp.value
    ? targetElementBounds.top.value
    : windowSize.height.value - targetElementBounds.bottom.value

  const style: Record<string, string> = {
    maxHeight: `${verticalOrientation.value ? maxHeight - 24 : maxHeight + 34}px`,
  }

  const arrowOffset = props.hideArrow
    ? PLACEMENT_OFFSET_WO_ARROW
    : PLACEMENT_OFFSET_WITH_ARROW

  const placementOffset = targetElementBounds.width.value / 2 - arrowOffset

  if (verticalOrientation.value && currentPlacement.value === 'end') {
    style.right = `${windowSize.width.value - targetElementBounds.right.value + placementOffset - BORDER_OFFSET}px`
  } else if (verticalOrientation.value && currentPlacement.value === 'start') {
    style.left = `${targetElementBounds.left.value + placementOffset + BORDER_OFFSET}px`
  } else if (!verticalOrientation.value && currentPlacement.value === 'start') {
    style.top = `${targetElementBounds.top.value + placementOffset + BORDER_OFFSET}px`
  } else if (!verticalOrientation.value && currentPlacement.value === 'end') {
    style.bottom = `${windowSize.height.value - targetElementBounds.bottom.value + placementOffset - BORDER_OFFSET}px`
  }

  const orientationOffset = props.hideArrow
    ? ORIENTATION_OFFSET_WO_ARROW
    : ORIENTATION_OFFSET_WITH_ARROW

  switch (autoOrientation.value) {
    case 'top':
      style.bottom = `${windowSize.height.value - targetElementBounds.top.value + orientationOffset}px`
      break
    case 'bottom':
      style.top = `${
        targetElementBounds.top.value +
        targetElementBounds.height.value +
        orientationOffset
      }px`
      break
    case 'left':
      style.right = `${windowSize.width.value - targetElementBounds.left.value + orientationOffset}px`
      break
    case 'right':
      style.left = `${targetElementBounds.right.value + orientationOffset}px`
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

  if (verticalOrientation.value && currentPlacement.value === 'end') {
    // eslint-disable-next-line zammad/zammad-tailwind-ltr
    classes['right-2'] = true
  } else if (verticalOrientation.value && currentPlacement.value === 'start') {
    // eslint-disable-next-line zammad/zammad-tailwind-ltr
    classes['left-7'] = true
  } else if (!verticalOrientation.value && currentPlacement.value === 'start') {
    classes['top-7'] = true
  } else if (!verticalOrientation.value && currentPlacement.value === 'end') {
    classes['bottom-2'] = true
  }

  return classes
})

const { moveNextFocusToTrap } = useTrapTab(popoverElement)

const { instances } = usePopoverInstances()

const updateOwnerAriaExpandedState = () => {
  const element = props.owner
  if (!element) return

  if ('ariaExpanded' in element) {
    element.ariaExpanded = showPopover.value ? 'true' : 'false'
  }
}

const closePopover = (isInteractive = false) => {
  if (!showPopover.value) return

  showPopover.value = false
  emit('close')

  nextTick(() => {
    if (!isInteractive && props.owner) {
      // eslint-disable-next-line no-unused-expressions
      '$el' in props.owner ? props.owner.$el?.focus?.() : props.owner?.focus?.()
    }
    updateOwnerAriaExpandedState()
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

  onClickOutside(popoverElement, () => closePopover(true), {
    ignore: [props.owner],
  })

  requestAnimationFrame(() => {
    nextTick(() => {
      moveNextFocusToTrap()
      updateOwnerAriaExpandedState()
      testFlags.set('common-popover.opened')
    })
  })
}

const togglePopover = (isInteractive = false) => {
  if (showPopover.value) {
    closePopover(isInteractive)
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

const { durations } = useTransitionConfig()
</script>

<template>
  <Teleport to="body">
    <Transition name="fade" :duration="durations.normal">
      <div
        v-if="showPopover"
        :id="id"
        ref="popoverElement"
        role="region"
        class="popover fixed z-50 flex min-h-9 rounded-xl border border-neutral-100 bg-white antialiased dark:border-gray-900 dark:bg-gray-500"
        :style="popoverStyle"
        :aria-labelledby="owner && '$el' in owner ? owner.$el?.id : owner?.id"
      >
        <div class="overflow-y-auto">
          <slot />
        </div>
        <div
          v-if="!hideArrow"
          class="absolute -z-10 h-[22px] w-[22px] -rotate-45 transform border border-neutral-100 bg-white dark:border-gray-900 dark:bg-gray-500"
          :class="arrowPlacementClasses"
        />
      </div>
    </Transition>
  </Teleport>
</template>
