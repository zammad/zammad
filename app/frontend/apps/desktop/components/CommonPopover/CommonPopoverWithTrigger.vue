<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onClickOutside, onLongPress, useElementHover, whenever } from '@vueuse/core'
import { computed, onDeactivated, onUnmounted, shallowRef, watch } from 'vue'

import getUuid from '#shared/utils/getUuid.ts'

import CommonPopover, {
  type Props as CommonPopoverProps,
} from '#desktop/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#desktop/components/CommonPopover/usePopover.ts'

export interface Props extends Omit<CommonPopoverProps, 'owner'> {
  triggerLink?: string
  triggerLinkClass?: string
  triggerLinkActiveClass?: string
  /**
   * If set, the popover will not show up
   */
  disabled?: boolean
  noFocusStyling?: boolean
  noHoverStyling?: boolean
  noMinWidth?: boolean
  zIndex?: string
}

const props = defineProps<Props>()

const triggerTag = computed(() => (props.triggerLink ? 'CommonLink' : 'div'))

const { popoverTarget, popover, isOpen, openDelayed, open, close } = usePopover()

const uniqueId = `popover-${getUuid()}`

const popoverElement = computed(() => popover.value?.popoverElement)

const hasOpenedViaLongPress = shallowRef(false)

onClickOutside(
  popoverElement,
  () => {
    if (!hasOpenedViaLongPress.value) return

    hasOpenedViaLongPress.value = false

    close()
  },
  {
    ignore: [popoverTarget],
  },
)

onLongPress(popoverTarget, () => {
  if (props.disabled) return

  hasOpenedViaLongPress.value = true

  open()
})

const onTriggerSpace = (event: KeyboardEvent) => {
  if (props.disabled) return

  event.preventDefault()

  open()
}

// NB: We purposefully don't use `useDelayTimings` values here, because they may be 0 for users with reduced motion
//   preferences. This delay is meant to prevent accidental popover opening/closing when the user is moving their mouse
//   across the screen,  and it's not related to transitions. We want it to be a small, but noticeable delay always.
const isPopoverHovered = useElementHover(popoverElement, {
  delayEnter: 100,
  delayLeave: 200,
})

const isPopoverTargetHovered = useElementHover(popoverTarget, {
  delayEnter: 100,
  delayLeave: 200,
})

watch([isPopoverHovered, isPopoverTargetHovered], ([isPopoverHovered, isPopoverTargetHovered]) => {
  if (hasOpenedViaLongPress.value) return

  const shouldOpen = isPopoverTargetHovered || isPopoverHovered

  if (shouldOpen && !isOpen.value) {
    openDelayed()
    return
  }

  if (!shouldOpen && isOpen.value) {
    close()
  }
})

whenever(
  () => !isOpen.value,
  () => {
    hasOpenedViaLongPress.value = false
  },
)

onDeactivated(() => {
  if (isOpen.value) close()
})

onUnmounted(() => {
  if (isOpen.value) close()
})

defineExpose({ hasOpenedViaLongPress })
</script>

<template>
  <!-- on long click we don't want to navigate -->
  <CommonPopover
    v-if="!disabled"
    v-bind="$props"
    :id="uniqueId"
    ref="popover"
    :class="{ 'min-w-68': !noMinWidth }"
    :z-index="zIndex"
    no-close-on-click-outside
    :owner="popoverTarget"
  >
    <slot
      name="popover-content"
      :popover-id="uniqueId"
      :popover="popover"
      :is-open="isOpen"
      :has-opened-via-long-click="hasOpenedViaLongPress"
      :close="close"
    />
  </CommonPopover>

  <component
    v-bind="$attrs"
    :is="triggerTag"
    ref="popoverTarget"
    :role="triggerLink ? undefined : 'button'"
    :link="triggerLink ? triggerLink : undefined"
    :disabled="(triggerLink && hasOpenedViaLongPress) || undefined"
    tabindex="0"
    :aria-controls="disabled ? undefined : uniqueId"
    :aria-expanded="disabled ? undefined : isOpen"
    class="group transition-none empty:hidden"
    :class="[
      triggerLinkClass ?? '',
      {
        [triggerLinkActiveClass ?? '']: isOpen && hasOpenedViaLongPress,
        'hover:no-underline!': triggerLink,
        'focus-visible-app-default': !noFocusStyling,
        'outline-transparent!': noFocusStyling,
        'hover:outline-1 hover:outline-blue-600 hover:dark:outline-blue-900': !noHoverStyling,
      },
    ]"
    @keydown.space="onTriggerSpace"
    @click="hasOpenedViaLongPress && $event.preventDefault()"
  >
    <slot
      :popover-id="uniqueId"
      :is-open="isOpen"
      :has-open-via-long-click="hasOpenedViaLongPress"
    />
  </component>
</template>
