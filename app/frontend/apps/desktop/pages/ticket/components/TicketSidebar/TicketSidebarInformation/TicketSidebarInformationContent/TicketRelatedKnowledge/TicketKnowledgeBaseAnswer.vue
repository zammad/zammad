<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useTemplateRef } from 'vue'

import type { KnowledgeBaseAnswerTranslationFragment } from '#shared/graphql/types.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { prepareLegacyAppLinkNavigation } from '#desktop/components/BetaUi/utils/legacyAppLink.ts'
import CommonPopoverWithTrigger from '#desktop/components/CommonPopover/CommonPopoverWithTrigger.vue'
import KnowledgeBaseAnswerIcon from '#desktop/components/KnowledgeBaseAnswerIcon/KnowledgeBaseAnswerIcon.vue'

import TicketKnowledgeBaseAnswerPopover from './TicketKnowledgeBaseAnswerPopover.vue'

interface Props {
  translation: KnowledgeBaseAnswerTranslationFragment
  link?: string
}

const props = defineProps<Props>()

const { hasPermission } = useSessionStore()

// Agents without knowledge base permission only get the plain item.
const showPopover = computed(() => hasPermission('knowledge_base.*'))

const popoverWithTriggerInstance = useTemplateRef('popover-with-trigger')

const hasOpenedViaLongPress = computed(
  () => popoverWithTriggerInstance.value?.hasOpenedViaLongPress,
)

// The answer view is still part of the legacy app - the public answer page (where users without
//   knowledge base permission are sent) is not, so it needs no preparation.
// NB: A middle-button (or other auxiliary button) activation, e.g. opening the link in a new
//   tab, fires `auxclick` instead of `click`, so both need to be handled here.
const onTriggerClick = () => {
  if (!props.link?.startsWith('/#')) return

  prepareLegacyAppLinkNavigation()
}
</script>

<template>
  <li class="group flex list-none items-center gap-1.5 ltr:pr-1.5 rtl:pl-1.5">
    <CommonPopoverWithTrigger
      ref="popover-with-trigger"
      :trigger-link="link"
      :disabled="!showPopover"
      orientation="left"
      trigger-link-class="flex h-9 w-full items-center gap-1.5 rounded-md! px-1.5 hover:text-blue-850! hover:dark:text-blue-600! text-blue-800!"
      trigger-link-active-class="outline-2! outline-blue-800! text-blue-850! dark:text-blue-600!"
      @click="onTriggerClick"
      @auxclick="onTriggerClick"
    >
      <template #popover-content>
        <TicketKnowledgeBaseAnswerPopover :translation="translation" />
      </template>

      <KnowledgeBaseAnswerIcon show-tooltip :visibility="translation.visibility" size="tiny" />

      <CommonLabel
        v-tooltip.supportive="translation.title"
        class="line-clamp-1! grow text-current!"
      >
        {{ translation.title }}
      </CommonLabel>

      <slot name="link-trailing" />
    </CommonPopoverWithTrigger>

    <slot name="action" :has-opened-via-long-press="hasOpenedViaLongPress" />
  </li>
</template>
