<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onClickOutside, onLongPress, useElementHover, whenever } from '@vueuse/core'
import { computed, onDeactivated, onUnmounted, shallowRef, watch } from 'vue'

import getUuid from '#shared/utils/getUuid.ts'

import CommonPopover, {
  type Props as CommonPopoverProps,
} from '#desktop/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#desktop/components/CommonPopover/usePopover.ts'
import { useTransitionConfig } from '#desktop/composables/useTransitionConfig.ts'

export interface Props extends Omit<CommonPopoverProps, 'owner'> {
  triggerLink?: string
  triggerLinkClass?: string
  triggerLinkActiveClass?: string
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
  hasOpenedViaLongPress.value = true

  open()
})

const { timings } = useTransitionConfig()

const isPopoverHovered = useElementHover(popoverElement, {
  delayEnter: timings.veryShort,
  delayLeave: timings.short,
})

const isPopoverTargetHovered = useElementHover(popoverTarget, {
  delayEnter: timings.veryShort,
  delayLeave: timings.short,
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
</script>

<template>
  <!-- on long click we don't want to navigate -->
  <CommonPopover
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
    :aria-controls="uniqueId"
    :aria-expanded="isOpen"
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
    @keydown.space.prevent="open()"
    @click="hasOpenedViaLongPress && $event.preventDefault()"
  >
    <slot
      :popover-id="uniqueId"
      :is-open="isOpen"
      :has-open-via-long-click="hasOpenedViaLongPress"
    />
  </component>
</template>
