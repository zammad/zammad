<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import type { Orientation } from '#desktop/components/CommonPopover/types.ts'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import TicketPopoverWithTrigger from '#desktop/components/Ticket/TicketPopoverWithTrigger.vue'
import { useObjectLinks } from '#desktop/entities/link/composables/useObjectLinks.ts'

import KnowledgeBaseAnswerLinkedTicketsSkeleton from './KnowledgeBaseAnswerLinkedTicketsSkeleton.vue'

import type { KnowledgeBaseAnswerHeader } from '../../../types.ts'

interface Props {
  answer: KnowledgeBaseAnswerHeader
}

const props = defineProps<Props>()

// Links belong to the answer *translation* of the browsed locale, not to the
//   answer: they differ per locale, and `linkList` only takes a translation ID.
//   An answer without any translation has none to link to, hence the gate.
const translation = computed(() =>
  props.answer.translationId ? { id: props.answer.translationId } : undefined,
)

const enabled = computed(() => Boolean(props.answer.translationId))

const { links, linkListIsLoading } = useObjectLinks(translation, 'Ticket', { enabled })

// The link item is a union and the query selects both of its branches; only the
//   ticket one can appear for this target type.
const tickets = computed(() =>
  links.value.flatMap((link) => (link.item.__typename === 'Ticket' ? [link.item] : [])),
)

const popoverConfig: { orientation: Orientation } = { orientation: 'left' }
</script>

<template>
  <CommonSectionCollapse id="kb-related-tickets" :title="__('Related tickets')">
    <CommonLoader class="w-full" :loading="linkListIsLoading">
      <template #skeleton>
        <KnowledgeBaseAnswerLinkedTicketsSkeleton />
      </template>

      <ul v-if="tickets.length" class="flex flex-col rounded-lg bg-blue-200 dark:bg-gray-700">
        <li v-for="ticket in tickets" :key="ticket.id" class="flex items-center p-1">
          <TicketPopoverWithTrigger
            :popover-config="popoverConfig"
            class="flex grow items-center rounded-md! px-1.5"
            :ticket="ticket"
            no-wrap
          />
        </li>
      </ul>

      <CommonLabel v-else size="small">
        {{ $t('No links added yet.') }}
      </CommonLabel>
    </CommonLoader>
  </CommonSectionCollapse>
</template>
