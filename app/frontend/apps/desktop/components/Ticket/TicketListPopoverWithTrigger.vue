<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { Props as CommonUserAvatarProps } from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import type { TicketsByCustomerQueryVariables } from '#shared/graphql/types.ts'

import { type Props as CommonPopoverProps } from '#desktop//components/CommonPopover/CommonPopover.vue'
import CommonPopoverWithTrigger from '#desktop/components/CommonPopover/CommonPopoverWithTrigger.vue'

import TicketListPopover from './TicketListPopoverWithTrigger/TicketListPopover.vue'

export interface Props {
  filters: TicketsByCustomerQueryVariables
  title: string
  noResults?: boolean
  popoverConfig?: Omit<CommonPopoverProps, 'owner'>
  avatarConfig?: Omit<CommonUserAvatarProps, 'entity'>
  triggerClass?: string | string[]
  triggerLink?: string
  noFocusStyling?: boolean
  noHoverStyling?: boolean
  zIndex?: string
}

defineProps<Props>()

defineOptions({
  inheritAttrs: false,
})

defineSlots<{
  default(props: {
    isOpen?: boolean | undefined
    popoverId?: string
    hasOpenViaLongClick?: boolean
  }): never
}>()
</script>

<template>
  <CommonPopoverWithTrigger
    :class="[
      $slots?.default?.() ? 'rounded-full! focus-visible:outline-2!' : '',
      triggerClass ?? '',
    ]"
    :no-hover-styling="noHoverStyling"
    :no-focus-styling="noFocusStyling"
    :z-index="zIndex"
    :trigger-link="triggerLink"
    :trigger-link-active-class="
      $slots?.default?.()
        ? 'outline-2! outline-offset-1! outline-blue-800! hover:outline-blue-800!'
        : ''
    "
    v-bind="{ ...popoverConfig, ...$attrs }"
  >
    <template #popover-content="{ popoverId, hasOpenedViaLongClick }">
      <TicketListPopover
        :id="popoverId"
        :filters="filters"
        :title="title"
        :no-results="noResults"
        :search-link="triggerLink"
        :has-open-via-long-click="hasOpenedViaLongClick"
      />
    </template>

    <template #default="slotProps">
      <slot v-bind="slotProps">
        <CommonLabel>
          {{ $t(title) }}
        </CommonLabel>
      </slot>
    </template>
  </CommonPopoverWithTrigger>
</template>
