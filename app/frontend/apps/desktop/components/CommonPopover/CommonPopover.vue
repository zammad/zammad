<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import {
  onClickOutside,
  onKeyUp,
  useElementBounding,
  useElementHover,
  useTimeoutFn,
  useWindowSize,
  type UseElementBoundingReturn,
  whenever,
  useCurrentElement,
  type MaybeElementRef,
  type VueInstance,
  unrefElement,
} from '@vueuse/core'
import {
  type ComponentPublicInstance,
  computed,
  nextTick,
  onMounted,
  onUnmounted,
  ref,
  toRef,
  type UnwrapRef,
  useTemplateRef,
} from 'vue'

import { useOnEmitter } from '#shared/composables/useOnEmitter.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { getPopoverClasses } from '#shared/initializer/initializePopover.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import stopEvent from '#shared/utils/events.ts'
import testFlags from '#shared/utils/testFlags.ts'

import { useAppBreakpoints } from '#desktop/composables/responsiveness/useAppBreakpoints.ts'
import { useDelayTimings } from '#desktop/composables/useDelayTimings.ts'
import { useTransitionConfig } from '#desktop/composables/useTransitionConfig.ts'

import { usePopoverInstances } from './usePopoverInstances.ts'

import type {
  Placement,
  CommonPopoverInternalInstance,
  Orientation,
  TargetElementBounds,
} from './types.ts'

export interface Props {
  owner: HTMLElement | ComponentPublicInstance | undefined
  orientation?: Orientation
  placement?: Placement
  hideArrow?: boolean
  id?: string
  persistent?: boolean
  noCloseOnClickOutside?: boolean
  noFullWidth?: boolean
  /**
   * Allows a wider popover, limited to the space the popover has next to its owner.
   */
  wide?: boolean
  zIndex?: string
}

const props = withDefaults(defineProps<Props>(), {
  placement: 'start',
  orientation: 'autoVertical',
  zIndex: '50',
})

const emit = defineEmits<{
  open: []
  close: []
}>()

const { isSmallScreen } = useAppBreakpoints()

const popoverElement = useTemplateRef('popover')

const showPopover = ref(false)

const targetElementBounds = ref<UnwrapRef<UseElementBoundingReturn>>()
const windowSize = useWindowSize()

const hasDirectionUp = computed(() => {
  if (!targetElementBounds.value || !windowSize.height) return false
  return targetElementBounds.value.y > windowSize.height.value / 2
})

const hasDirectionRight = computed(() => {
  if (!targetElementBounds.value || !windowSize.width) return false

  return targetElementBounds.value.x < windowSize.width.value / 2
})

const locale = useLocaleStore()

const overflowOrientation = ref<Orientation | null>(null)

const autoOrientation = computed(() => {
  if (overflowOrientation.value) return overflowOrientation.value

  // ignore (auto-)Horizontal in favor for autoVertical on small screens
  // since there is no enough space for left and right placement
  if (props.orientation === 'autoVertical' || isSmallScreen.value) {
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

const verticalOrientation = computed(
  () => autoOrientation.value === 'top' || autoOrientation.value === 'bottom',
)

const overflowHorizontalPlacement = ref<Placement | null>(null)

whenever(
  () => !showPopover.value,
  () => {
    overflowHorizontalPlacement.value = null
    overflowOrientation.value = null
  },
)

const currentPlacement = computed(() => {
  const placement = overflowHorizontalPlacement.value || props.placement

  if (placement === 'arrowStart' || placement === 'arrowEnd') {
    if (locale.localeData?.dir === EnumTextDirection.Rtl) {
      return placement === 'arrowStart' ? 'arrowEnd' : 'arrowStart'
    }
    return placement
  }

  if (verticalOrientation.value) {
    if (locale.localeData?.dir === EnumTextDirection.Rtl) {
      if (placement === 'start') return 'end'
      if (placement === 'end') return 'start'
      return props.hideArrow ? 'start' : 'arrowStart'
    }
    return placement
  }
  if (hasDirectionUp.value) return props.hideArrow ? 'end' : 'arrowEnd'
  return props.hideArrow ? 'start' : 'arrowStart'
})

const BORDER_OFFSET = 2
const PLACEMENT_OFFSET_WO_ARROW = 16
const PLACEMENT_OFFSET_WITH_ARROW = 30
const ORIENTATION_OFFSET_WO_ARROW = 6
const ORIENTATION_OFFSET_WITH_ARROW = 16
const WIDE_VIEWPORT_MARGIN = 8
const WIDE_MIN_WIDTH = 448

// Below a usable width the popover keeps its size, so the regular overflow handling flips it.
const getWideMaxWidth = () => {
  if (!props.wide || !targetElementBounds.value) return

  const bounds = targetElementBounds.value
  const orientationOffset = props.hideArrow
    ? ORIENTATION_OFFSET_WO_ARROW
    : ORIENTATION_OFFSET_WITH_ARROW

  let availableWidth: number

  if (autoOrientation.value === 'left') availableWidth = bounds.left - orientationOffset
  else if (autoOrientation.value === 'right')
    availableWidth = windowSize.width.value - bounds.right - orientationOffset
  else if (currentPlacement.value === 'start') availableWidth = windowSize.width.value - bounds.left
  else if (currentPlacement.value === 'end') availableWidth = bounds.right
  else return

  availableWidth -= WIDE_VIEWPORT_MARGIN

  if (availableWidth < WIDE_MIN_WIDTH) return

  return availableWidth
}

// Positions the popover along the owner's edge, across the orientation axis.
const getPlacementStyle = (
  bounds: TargetElementBounds,
  arrowOffset: number,
): Record<string, string> => {
  const placementOffset = bounds.width / 2 - arrowOffset

  if (verticalOrientation.value) {
    switch (currentPlacement.value) {
      case 'start':
        return { left: `${bounds.left - BORDER_OFFSET}px` }
      case 'arrowStart':
        return { left: `${bounds.left + placementOffset + BORDER_OFFSET}px` }
      case 'arrowEnd':
        return {
          right: `${windowSize.width.value - bounds.left + placementOffset - bounds.width - BORDER_OFFSET}px`,
        }
      case 'end':
        return {
          right: `${windowSize.width.value - bounds.left - bounds.width - BORDER_OFFSET}px`,
        }
      default:
        return {}
    }
  }

  switch (currentPlacement.value) {
    case 'start':
      return { top: `${bounds.top - BORDER_OFFSET}px` }
    case 'arrowStart':
      return { top: `${bounds.bottom - bounds.height / 2 - arrowOffset + BORDER_OFFSET}px` }
    case 'arrowEnd':
      return {
        bottom: `${windowSize.height.value - bounds.bottom + bounds.height / 2 - arrowOffset - BORDER_OFFSET}px`,
      }
    case 'end':
      return { bottom: `${windowSize.height.value - bounds.bottom - BORDER_OFFSET}px` }
    default:
      return {}
  }
}

// Pushes the popover off the owner, on the side the available space picked.
const getOrientationStyle = (
  bounds: TargetElementBounds,
  orientationOffset: number,
): Record<string, string> => {
  switch (autoOrientation.value) {
    case 'top':
      return { bottom: `${windowSize.height.value - bounds.top + orientationOffset}px` }
    case 'bottom':
      return { top: `${bounds.top + bounds.height + orientationOffset}px` }
    case 'left':
      return { right: `${windowSize.width.value - bounds.left + orientationOffset}px` }
    case 'right':
      return { left: `${bounds.right + orientationOffset}px` }
    default:
      return {}
  }
}

const popoverStyle = computed(() => {
  if (!targetElementBounds.value) return { top: 0, left: 0, maxHeight: 0 }

  const bounds = targetElementBounds.value

  const maxHeight = hasDirectionUp.value ? bounds.top : windowSize.height.value - bounds.bottom

  const arrowOffset = props.hideArrow ? PLACEMENT_OFFSET_WO_ARROW : PLACEMENT_OFFSET_WITH_ARROW
  const orientationOffset = props.hideArrow
    ? ORIENTATION_OFFSET_WO_ARROW
    : ORIENTATION_OFFSET_WITH_ARROW

  const style: Record<string, string> = {
    maxHeight: `${verticalOrientation.value ? maxHeight - 24 : maxHeight + 34}px`,
    ...getPlacementStyle(bounds, arrowOffset),
    ...getOrientationStyle(bounds, orientationOffset),
  }

  const wideMaxWidth = getWideMaxWidth()
  if (wideMaxWidth) style.maxWidth = `${wideMaxWidth}px`

  style.zIndex = props.zIndex

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

  if (verticalOrientation.value) {
    if (currentPlacement.value === 'start' || currentPlacement.value === 'arrowStart') {
      // eslint-disable-next-line zammad/zammad-tailwind-ltr
      classes['left-7'] = true
    } else if (currentPlacement.value === 'end' || currentPlacement.value === 'arrowEnd') {
      // eslint-disable-next-line zammad/zammad-tailwind-ltr
      classes['right-2'] = true
    }
  } else if (!verticalOrientation.value) {
    if (currentPlacement.value === 'start' || currentPlacement.value === 'arrowStart') {
      classes['top-7'] = true
    } else if (currentPlacement.value === 'end' || currentPlacement.value === 'arrowEnd') {
      classes['bottom-2'] = true
    }
  }

  return classes
})

const { moveNextFocusToTrap } = useTrapTab(popoverElement)

const { instances } = usePopoverInstances()

const updateOwnerAriaExpandedState = () => {
  const element = unrefElement(props.owner)

  if (!element) return

  if ('ariaExpanded' in element) {
    element.ariaExpanded = showPopover.value ? 'true' : 'false'
  }
}

let removeOnKeyUpEscapeHandler: () => void

const lastActiveElement = ref<HTMLElement>()
const ownerElement = useCurrentElement(toRef(props, 'owner') as MaybeElementRef<VueInstance>)

const isLastActiveElementOwner = computed(() => lastActiveElement.value === ownerElement.value)

const closePopover = (isInteractive = false) => {
  if (!showPopover.value) return

  showPopover.value = false
  emit('close')
  removeOnKeyUpEscapeHandler?.()

  nextTick(() => {
    if (!isInteractive && props.owner && isLastActiveElementOwner.value)
      (ownerElement.value as HTMLElement).focus()

    updateOwnerAriaExpandedState()
    testFlags.set('common-popover.closed')
  })
}

const checkHorizontalOverflow = () => {
  if (!popoverElement.value || !showPopover.value) return

  nextTick(() => {
    const popoverElementReference = popoverElement.value as HTMLElement
    const popoverRect = popoverElementReference.getBoundingClientRect()

    // For vertical orientations (top/bottom), check horizontal placement overflow
    if (verticalOrientation.value) {
      // Check if overflowing right edge of viewport
      if (
        (props.placement === 'start' || props.placement === 'arrowStart') &&
        popoverRect.right > windowSize.width.value
      ) {
        overflowHorizontalPlacement.value = props.placement === 'start' ? 'end' : 'arrowEnd'
      }

      // Check if overflowing left edge of viewport
      if ((props.placement === 'end' || props.placement === 'arrowEnd') && popoverRect.left < 0) {
        overflowHorizontalPlacement.value = props.placement === 'end' ? 'start' : 'arrowStart'
      }
    }

    // For horizontal orientations (left/right), check if popover overflows viewport edges
    if (!verticalOrientation.value) {
      // When orientation is 'left' and popover overflows left edge, flip to 'right'
      if (autoOrientation.value === 'left' && popoverRect.left < 0) {
        overflowOrientation.value = 'right'
      }

      // When orientation is 'right' and popover overflows right edge, flip to 'left'
      if (autoOrientation.value === 'right' && popoverRect.right > windowSize.width.value) {
        overflowOrientation.value = 'left'
      }
    }
  })
}

const isOwnerHovered = useElementHover(computed(() => ownerElement.value as Element))

const openPopoverImmediate = () => {
  if (showPopover.value) return

  lastActiveElement.value = document.activeElement as HTMLElement

  targetElementBounds.value = useElementBounding(
    props.owner,
  ) as unknown as UnwrapRef<UseElementBoundingReturn>

  instances.value.forEach((instance) => {
    if (instance.isOpen.value) instance.closePopover()
  })

  showPopover.value = true
  emit('open')

  removeOnKeyUpEscapeHandler = onKeyUp('Escape', (e) => {
    if (!showPopover.value) return

    stopEvent(e)
    closePopover()
  })

  const onClickOutsideHandler = onClickOutside(popoverElement, () => closePopover(true), {
    ignore: [props.owner],
    controls: true,
  })

  if (props?.noCloseOnClickOutside) onClickOutsideHandler.stop()

  requestAnimationFrame(() => {
    nextTick(() => {
      moveNextFocusToTrap()
      updateOwnerAriaExpandedState()
      testFlags.set('common-popover.opened')

      checkHorizontalOverflow()
    })
  })
}

const openPopoverWithHoverCheck = () => {
  // Only open if still hovering over the owner element
  if (!isOwnerHovered.value) return

  openPopoverImmediate()
}

const { timings } = useDelayTimings()
const { transitions } = useTransitionConfig()

const { start: startOpenTimeout, stop: cancelOpenPopover } = useTimeoutFn(
  openPopoverWithHoverCheck,
  timings.value.veryShort,
  { immediate: false },
)

const openPopover = () => openPopoverImmediate()

const openPopoverDelayed = () => {
  cancelOpenPopover()
  startOpenTimeout()
}

const togglePopover = (isInteractive = false) =>
  showPopover.value ? closePopover(isInteractive) : openPopover()

const exposedInstance: CommonPopoverInternalInstance = {
  isOpen: computed(() => showPopover.value),
  openPopover,
  openPopoverDelayed,
  closePopover,
  togglePopover,
  popoverElement,
  cancelOpenPopover,
}

instances.value.add(exposedInstance)

onUnmounted(() => {
  instances.value.delete(exposedInstance)
  removeOnKeyUpEscapeHandler?.()
})

defineExpose(exposedInstance)

defineOptions({
  inheritAttrs: false,
})

const classes = getPopoverClasses()

onMounted(() => {
  testFlags.set(props.id ? `common-popover.mounted-${props.id}` : 'common-popover.mounted')
})

useOnEmitter('close-popover', () => {
  if (showPopover.value) closePopover()
})

// We have certain situation where we don't detect when the positioning is changing
// For example when the popover was opened via long press in the top header
// We resize the sidebar but since it is a grid we are changing css values
// Only changes on the window size and element bounding are detected
// In this cases we need to trigger a manual update
useOnEmitter('resize-layout', () => {
  if (showPopover.value && targetElementBounds.value) closePopover()
})
</script>

<template>
  <Teleport to="body">
    <Transition :name="transitions.fade">
      <div
        v-if="persistent || showPopover"
        v-show="!persistent || showPopover"
        :id="id"
        ref="popover"
        role="region"
        class="popover fixed flex print:hidden"
        :class="[classes.base]"
        :style="popoverStyle"
        :aria-labelledby="owner && '$el' in owner ? owner.$el?.id : owner?.id"
        v-bind="$attrs"
      >
        <div
          class="overflow-y-auto"
          :class="{ 'w-full': !noFullWidth, 'max-w-md': !wide, 'max-w-3xl': wide }"
        >
          <slot />
        </div>
        <div
          v-if="!hideArrow"
          class="absolute -z-10 -rotate-45 transform"
          :class="[arrowPlacementClasses, classes.arrow]"
        />
      </div>
    </Transition>
  </Teleport>
</template>
