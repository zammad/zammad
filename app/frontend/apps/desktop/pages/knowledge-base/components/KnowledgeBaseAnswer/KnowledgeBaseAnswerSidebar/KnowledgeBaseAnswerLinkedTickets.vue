<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import type { Orientation } from '#desktop/components/CommonPopover/types.ts'
import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import TicketPopoverWithTrigger from '#desktop/components/Ticket/TicketPopoverWithTrigger.vue'
import { useObjectLinkMutations } from '#desktop/entities/link/composables/useObjectLinkMutations.ts'
import { useObjectLinks } from '#desktop/entities/link/composables/useObjectLinks.ts'

import KnowledgeBaseAnswerLinkedTicketsSkeleton from './KnowledgeBaseAnswerLinkedTicketsSkeleton.vue'

import type { KnowledgeBaseAnswerHeader } from '../../../types.ts'

interface Props {
  answer: KnowledgeBaseAnswerHeader
  // Links are written onto the answer the moment they are added or removed, so like the tags above
  //   them they are not form values: nothing about them is submitted with the edit form, and they
  //   are therefore not part of its auto-saved draft nor of "Discard your unsaved changes".
  editable?: boolean
}

const props = withDefaults(defineProps<Props>(), { editable: false })

// Links belong to the answer *translation* of the browsed locale, not to the
//   answer: they differ per locale, and `linkList` only takes a translation ID.
//   An answer without any translation has none to link to, hence the gate.
const translation = computed(() => props.answer.translation ?? undefined)

const enabled = computed(() => Boolean(translation.value))

const { links, linkListIsLoading } = useObjectLinks(translation, 'Ticket', { enabled })

// The link item is a union and the query selects both of its branches; only the
//   ticket one can appear for this target type.
const tickets = computed(() =>
  links.value.flatMap((link) => (link.item.__typename === 'Ticket' ? [link.item] : [])),
)

const popoverConfig: { orientation: Orientation } = { orientation: 'left' }

const { isTouchDevice } = useTouchDevice()
const session = useSessionStore()

// Both link mutations require `ticket.agent`, and the ticket picker is agent-scoped anyway — so an
//   editor without any ticket permission is offered no way in rather than a button the mutation
//   refuses. They still see the tickets already linked.
const canLink = computed(
  () => props.editable && Boolean(translation.value) && session.hasPermission(['ticket.agent']),
)

// A locale the answer has no translation in yet has nothing to hang a link off. Saying so beats an
//   empty section that looks like "none yet" while the add button is missing for a reason nobody
//   can see.
const isUntranslated = computed(() => props.editable && !translation.value)

const { removeLink } = useObjectLinkMutations(() => translation.value?.id, 'Ticket')

const linkFlyout = useFlyout({
  name: 'knowledge-base-answer-link-ticket',
  component: () => import('./KnowledgeBaseAnswerLinkTicketFlyout.vue'),
})

const openLinkFlyout = () => {
  if (!translation.value) return

  linkFlyout.open({ translationId: translation.value.id })
}
</script>

<template>
  <CommonSectionCollapse id="kb-related-tickets" :title="__('Related tickets')">
    <CommonLoader class="w-full" :loading="linkListIsLoading">
      <template #skeleton>
        <KnowledgeBaseAnswerLinkedTicketsSkeleton />
      </template>

      <div class="flex flex-col gap-2">
        <ul v-if="tickets.length" class="flex flex-col rounded-lg bg-blue-200 dark:bg-gray-700">
          <li
            v-for="ticket in tickets"
            :key="ticket.id"
            class="group/link flex items-center gap-1 p-1"
          >
            <TicketPopoverWithTrigger
              :popover-config="popoverConfig"
              class="flex grow items-center rounded-md! px-1.5"
              :ticket="ticket"
              no-wrap
            />

            <!-- Hover-only on a pointer device, always there on a touch one, which has no hover to
                 reveal it with. -->
            <CommonButton
              v-if="canLink"
              v-tooltip="$t('Unlink ticket')"
              :class="{ 'opacity-0 transition-opacity': !isTouchDevice }"
              class="group-hover/link:opacity-100 focus:opacity-100"
              icon="x-lg"
              size="small"
              variant="remove"
              @click.stop="removeLink(ticket.id)"
            />
          </li>
        </ul>

        <CommonLabel v-else-if="isUntranslated" size="small">
          {{ $t('Save the answer in this language before linking tickets to it.') }}
        </CommonLabel>

        <CommonLabel v-else size="small">
          {{ $t('No links added yet.') }}
        </CommonLabel>

        <CommonButton
          v-if="canLink"
          v-tooltip="$t('Link ticket')"
          size="medium"
          class="self-end"
          icon="plus-square-fill"
          @click="openLinkFlyout"
        />
      </div>
    </CommonLoader>
  </CommonSectionCollapse>
</template>
