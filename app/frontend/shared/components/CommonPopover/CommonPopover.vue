<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import {
  onClickOutside,
  onKeyUp,
  useElementBounding,
  useWindowSize,
  type UseElementBoundingReturn,
} from '@vueuse/core'
import {
  type ComponentPublicInstance,
  computed,
  nextTick,
  onMounted,
  onUnmounted,
  ref,
  type UnwrapRef,
  useTemplateRef,
} from 'vue'

import { useTransitionConfig } from '#shared/composables/useTransitionConfig.ts'
import { useTrapTab } from '#shared/composables/useTrapTab.ts'
import { EnumTextDirection } from '#shared/graphql/types.ts'
import { getPopoverClasses } from '#shared/initializer/initializePopover.ts'
import { useLocaleStore } from '#shared/stores/locale.ts'
import emitter from '#shared/utils/emitter.ts'
import stopEvent from '#shared/utils/events.ts'
import testFlags from '#shared/utils/testFlags.ts'

import { usePopoverInstances } from './usePopoverInstances.ts'

import type {
  Placement,
  CommonPopoverInternalInstance,
  Orientation,
} from './types.ts'

export interface Props {
  owner: HTMLElement | ComponentPublicInstance | undefined
  orientation?: Orientation
  placement?: Placement
  hideArrow?: boolean
  id?: string
  noAutoFocus?: boolean
  persistent?: boolean
  noCloseOnClickOutside?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  placement: 'start',
  orientation: 'autoVertical',
})

const emit = defineEmits<{
  open: []
  close: []
}>()

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

// eslint-disable-next-line sonarjs/cognitive-complexity
const currentPlacement = computed(() => {
  if (props.placement === 'arrowStart' || props.placement === 'arrowEnd') {
    if (locale.localeData?.dir === EnumTextDirection.Rtl) {
      if (props.placement === 'arrowStart') return 'arrowEnd'
      return 'arrowStart'
    }
    return props.placement
  }

  if (verticalOrientation.value) {
    if (locale.localeData?.dir === EnumTextDirection.Rtl) {
      if (props.placement === 'start') return 'end'
      if (props.placement === 'end') return 'start'
      return props.hideArrow ? 'start' : 'arrowStart'
    }
    return props.placement
  }
  if (hasDirectionUp.value) return props.hideArrow ? 'end' : 'arrowEnd'
  return props.hideArrow ? 'start' : 'arrowStart'
})

const BORDER_OFFSET = 2
const PLACEMENT_OFFSET_WO_ARROW = 16
const PLACEMENT_OFFSET_WITH_ARROW = 30
const ORIENTATION_OFFSET_WO_ARROW = 6
const ORIENTATION_OFFSET_WITH_ARROW = 16

// eslint-disable-next-line sonarjs/cognitive-complexity
const popoverStyle = computed(() => {
  if (!targetElementBounds.value) return { top: 0, left: 0, maxHeight: 0 }

  const maxHeight = hasDirectionUp.value
    ? targetElementBounds.value.top
    : windowSize.height.value - targetElementBounds.value.bottom

  const style: Record<string, string> = {
    maxHeight: `${verticalOrientation.value ? maxHeight - 24 : maxHeight + 34}px`,
  }

  const arrowOffset = props.hideArrow
    ? PLACEMENT_OFFSET_WO_ARROW
    : PLACEMENT_OFFSET_WITH_ARROW

  const placementOffset = targetElementBounds.value.width / 2 - arrowOffset

  if (verticalOrientation.value) {
    if (currentPlacement.value === 'start') {
      style.left = `${targetElementBounds.value.left - BORDER_OFFSET}px`
    } else if (currentPlacement.value === 'arrowStart') {
      style.left = `${targetElementBounds.value.left + placementOffset + BORDER_OFFSET}px`
    } else if (currentPlacement.value === 'arrowEnd') {
      style.right = `${windowSize.width.value - targetElementBounds.value.left + placementOffset - targetElementBounds.value.width - BORDER_OFFSET}px`
    } else if (currentPlacement.value === 'end') {
      style.right = `${windowSize.width.value - targetElementBounds.value.left - targetElementBounds.value.width - BORDER_OFFSET}px`
    }
  } else if (!verticalOrientation.value) {
    if (currentPlacement.value === 'start') {
      style.top = `${targetElementBounds.value.top - BORDER_OFFSET}px`
    } else if (currentPlacement.value === 'arrowStart') {
      style.top = `${targetElementBounds.value.bottom - targetElementBounds.value.height / 2 - arrowOffset + BORDER_OFFSET}px`
    } else if (currentPlacement.value === 'arrowEnd') {
      style.bottom = `${windowSize.height.value - targetElementBounds.value.bottom + targetElementBounds.value.height / 2 - arrowOffset - BORDER_OFFSET}px`
    } else if (currentPlacement.value === 'end') {
      style.bottom = `${windowSize.height.value - targetElementBounds.value.bottom - BORDER_OFFSET}px`
    }
  }

  const orientationOffset = props.hideArrow
    ? ORIENTATION_OFFSET_WO_ARROW
    : ORIENTATION_OFFSET_WITH_ARROW

  switch (autoOrientation.value) {
    case 'top':
      style.bottom = `${windowSize.height.value - targetElementBounds.value.top + orientationOffset}px`
      break
    case 'bottom':
      style.top = `${
        targetElementBounds.value.top +
        targetElementBounds.value.height +
        orientationOffset
      }px`
      break
    case 'left':
      style.right = `${windowSize.width.value - targetElementBounds.value.left + orientationOffset}px`
      break
    case 'right':
      style.left = `${targetElementBounds.value.right + orientationOffset}px`
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

  if (verticalOrientation.value) {
    if (
      currentPlacement.value === 'start' ||
      currentPlacement.value === 'arrowStart'
    ) {
      // eslint-disable-next-line zammad/zammad-tailwind-ltr
      classes['left-7'] = true
    } else if (
      currentPlacement.value === 'end' ||
      currentPlacement.value === 'arrowEnd'
    ) {
      // eslint-disable-next-line zammad/zammad-tailwind-ltr
      classes['right-2'] = true
    }
  } else if (!verticalOrientation.value) {
    if (
      currentPlacement.value === 'start' ||
      currentPlacement.value === 'arrowStart'
    ) {
      classes['top-7'] = true
    } else if (
      currentPlacement.value === 'end' ||
      currentPlacement.value === 'arrowEnd'
    ) {
      classes['bottom-2'] = true
    }
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

let removeOnKeyUpEscapeHandler: () => void

const closePopover = (isInteractive = false) => {
  if (!showPopover.value) return

  showPopover.value = false
  emit('close')
  removeOnKeyUpEscapeHandler?.()

  nextTick(() => {
    if (!isInteractive && props.owner) {
      // eslint-disable-next-line @typescript-eslint/no-unused-expressions
      '$el' in props.owner ? props.owner.$el?.focus?.() : props.owner?.focus?.()
    }
    updateOwnerAriaExpandedState()
    testFlags.set('common-popover.closed')
  })
}

const openPopover = () => {
  if (showPopover.value) return

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

  const onClickOutsideHandler = onClickOutside(
    popoverElement,
    () => closePopover(true),
    {
      ignore: [props.owner],
      controls: true,
    },
  )

  if (props?.noCloseOnClickOutside) onClickOutsideHandler.stop()

  requestAnimationFrame(() => {
    nextTick(() => {
      if (!props.noAutoFocus) moveNextFocusToTrap()
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

const exposedInstance: CommonPopoverInternalInstance = {
  isOpen: computed(() => showPopover.value),
  openPopover,
  closePopover,
  togglePopover,
  popoverElement,
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

const { durations } = useTransitionConfig()

const classes = getPopoverClasses()

onMounted(() => {
  testFlags.set(
    props.id ? `common-popover.mounted-${props.id}` : 'common-popover.mounted',
  )
})

emitter.on('close-popover', () => {
  if (showPopover.value) closePopover()
})
</script>

<template>
  <Teleport to="body">
    <Transition name="fade" :duration="durations.normal">
      <div
        v-if="persistent"
        v-show="showPopover"
        :id="id"
        ref="popover"
        role="region"
        class="popover fixed z-50 flex"
        :class="[classes.base]"
        :style="popoverStyle"
        :aria-labelledby="owner && '$el' in owner ? owner.$el?.id : owner?.id"
        v-bind="$attrs"
      >
        <div class="w-full overflow-y-auto">
          <slot />
        </div>
        <div
          v-if="!hideArrow"
          class="absolute -z-10 -rotate-45 transform"
          :class="[arrowPlacementClasses, classes.arrow]"
        />
      </div>
      <div
        v-else-if="showPopover"
        :id="id"
        ref="popover"
        role="region"
        class="popover fixed z-50 flex"
        :class="[classes.base]"
        :style="popoverStyle"
        :aria-labelledby="owner && '$el' in owner ? owner.$el?.id : owner?.id"
        v-bind="$attrs"
      >
        <div class="w-full overflow-y-auto">
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
