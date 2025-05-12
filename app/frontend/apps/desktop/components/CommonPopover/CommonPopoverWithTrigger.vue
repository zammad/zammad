<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import {
  onClickOutside,
  onLongPress,
  useElementHover,
  whenever,
} from '@vueuse/core'
import { computed, onDeactivated, onUnmounted, shallowRef, watch } from 'vue'

import CommonPopover, {
  type Props as CommonPopoverProps,
} from '#shared/components/CommonPopover/CommonPopover.vue'
import { usePopover } from '#shared/components/CommonPopover/usePopover.ts'
import getUuid from '#shared/utils/getUuid.ts'

interface Props extends Omit<CommonPopoverProps, 'owner'> {
  triggerLink?: string
  triggerLinkActiveClass?: string
  noFocusStyling?: boolean
  noHoverStyling?: boolean
}

const props = defineProps<Props>()

const triggerTag = computed(() => (props.triggerLink ? 'CommonLink' : 'div'))

const { popoverTarget, popover, isOpen, open, close } = usePopover()

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

const isPopoverHovered = useElementHover(popoverElement, {
  delayEnter: 100,
  delayLeave: 200,
})

const isPopoverTargetHovered = useElementHover(popoverTarget, {
  delayEnter: 100,
  delayLeave: 200,
})

watch(
  [isPopoverHovered, isPopoverTargetHovered],
  ([isPopoverHovered, isPopoverTargetHovered]) => {
    if (hasOpenedViaLongPress.value) return

    const shouldOpen = isPopoverTargetHovered || isPopoverHovered

    if (shouldOpen && !isOpen.value) {
      open()
      return
    }

    if (!shouldOpen && isOpen.value) {
      close()
    }
  },
)

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
    class="min-w-[17rem]"
    no-close-on-click-outside
    :owner="popoverTarget"
  >
    <slot
      name="popover-content"
      :popover-id="uniqueId"
      :is-open="isOpen"
      :has-opened-via-long-click="hasOpenedViaLongPress"
    />
  </CommonPopover>

  <component
    v-bind="$attrs"
    :is="triggerTag"
    ref="popoverTarget"
    :role="triggerLink ? undefined : 'button'"
    :link="triggerLink ? triggerLink : undefined"
    tabindex="0"
    :aria-controls="uniqueId"
    :aria-expanded="isOpen"
    class="group"
    :class="[
      {
        [triggerLinkActiveClass ?? '']: isOpen && hasOpenedViaLongPress,
        'hover:no-underline!': triggerLink,
        'focus-visible:outline-1 focus-visible:outline-blue-800 hover:focus-visible:outline-blue-800':
          !noFocusStyling,
        'outline-transparent!': noFocusStyling,
        'hover:outline-1 hover:outline-blue-900': !noHoverStyling,
      },
    ]"
    @keydown.space.prevent="open"
    @click="hasOpenedViaLongPress && $event.preventDefault()"
  >
    <slot
      :popover-id="uniqueId"
      :is-open="isOpen"
      :has-open-via-long-click="hasOpenedViaLongPress"
    />
  </component>
</template>
