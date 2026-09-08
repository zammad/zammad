<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { Link } from '#shared/types/router.ts'

import { type Props as CommonPopoverProps } from '#desktop/components/CommonPopover/CommonPopover.vue'
import CommonPopoverWithTrigger from '#desktop/components/CommonPopover/CommonPopoverWithTrigger.vue'

import KnowledgeBaseAnswerPopoverContent from './KnowledgeBaseAnswerPopoverWithTrigger/KnowledgeBaseAnswerPopoverContent.vue'

export interface Props {
  answerId: string
  /** Locale of the translation being shown, passed through so the popover describes that one. */
  locale?: string
  triggerLink?: Link
  popoverConfig?: Omit<CommonPopoverProps, 'owner'>
  triggerClass?: string
  triggerLinkClass?: string
  triggerLinkActiveClass?: string
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

<!--
  Deliberately ungated, unlike the ticket sidebar's TicketKnowledgeBaseAnswer, which hides its
    popover from agents without `knowledge_base.*`. There the list is a ticket-side suggestion; here
    the caller only offers an answer the user is already permitted to see, and a customer looking at
    a published answer should get its details too. The rows a user may not see are dropped by the
    server: `internalAt` and `archivedAt` are scoped fields on KnowledgeBaseAnswer, so they arrive
    null and the attribute grid leaves their rows out.
-->
<template>
  <CommonPopoverWithTrigger
    :class="triggerClass ?? ''"
    :no-hover-styling="noHoverStyling"
    :no-focus-styling="noFocusStyling"
    :z-index="zIndex"
    :trigger-link="triggerLink"
    :trigger-link-class="triggerLinkClass"
    :trigger-link-active-class="triggerLinkActiveClass"
    v-bind="{ ...popoverConfig, ...$attrs }"
  >
    <template #popover-content="{ popoverId }">
      <KnowledgeBaseAnswerPopoverContent :id="popoverId" :answer-id="answerId" :locale="locale" />
    </template>

    <template #default="slotProps">
      <slot v-bind="slotProps" />
    </template>
  </CommonPopoverWithTrigger>
</template>
