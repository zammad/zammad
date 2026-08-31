<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormSubmitData } from '#shared/components/Form/types.ts'
import { useForm } from '#shared/components/Form/useForm.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import CommonFlyout from '#desktop/components/CommonFlyout/CommonFlyout.vue'
import type { ActionFooterOptions } from '#desktop/components/CommonFlyout/types.ts'
import { closeFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import TicketSimpleTable from '#desktop/components/Ticket/TicketSimpleTable/TicketSimpleTable.vue'
import type { TicketRelationAndRecentListItem } from '#desktop/components/Ticket/TicketSimpleTable/types.ts'
import { useObjectLinkMutations } from '#desktop/entities/link/composables/useObjectLinkMutations.ts'
import { useTargetTicketOptions } from '#desktop/entities/ticket/composables/useTargetTicketOptions.ts'
import { useTicketsRecentlyViewedQuery } from '#desktop/entities/ticket/graphql/queries/ticketsRecentlyViewed.api.ts'

// Must match the name the section registers the flyout under.
const FLYOUT_NAME = 'knowledge-base-answer-link-ticket'

const RECENTLY_VIEWED_LIMIT = 10

interface Props {
  // The answer *translation* of the edited locale, which is what a link hangs off.
  translationId: string
}

const props = defineProps<Props>()

const { form, updateFieldValues, onChangedField } = useForm()

const { formListTargetTicketOptions, targetTicketId, handleTicketClick } = useTargetTicketOptions(
  onChangedField,
  updateFieldValues,
  'ticketId',
)

// Only the ticket, and no link type: the section renders one flat list of related tickets, so
//   there is nothing for a type to distinguish - the same as the ticket side does when it links an
//   answer.
const formSchema = [
  {
    name: 'ticketId',
    type: 'ticket',
    label: __('Ticket'),
    options: formListTargetTicketOptions,
    clearable: true,
    required: true,
  },
]

const footerActionOptions = computed<ActionFooterOptions>(() => ({
  actionButton: { variant: 'submit', type: 'submit' },
  actionLabel: __('Link'),
}))

// The ticket just worked on is usually the one being documented, so offering it saves searching for
//   it by number. Only recently viewed ones - "recent customer tickets" needs a customer, and an
//   answer has none.
const recentlyViewedQuery = new QueryHandler(
  useTicketsRecentlyViewedQuery(
    { limit: RECENTLY_VIEWED_LIMIT },
    { fetchPolicy: 'cache-and-network' },
  ),
)

const recentlyViewedIsLoading = recentlyViewedQuery.loadingWithoutCachedResult()
const recentlyViewedResult = recentlyViewedQuery.result()

const recentlyViewedTickets = computed(
  () =>
    recentlyViewedResult.value
      ?.ticketsRecentlyViewed as unknown as TicketRelationAndRecentListItem[],
)

const { addLink } = useObjectLinkMutations(() => props.translationId, 'Ticket')
const { notify } = useNotifications()

const linkTicket = async (formData: FormSubmitData<{ ticketId: string }>) => {
  const result = await addLink(formData.ticketId)

  if (!result?.linkAdd) return

  // Returned rather than run here, so the form is reset before the flyout goes.
  return () => {
    notify({
      type: NotificationTypes.Success,
      id: 'knowledge-base-answer-ticket-linked',
      message: __('Ticket linked successfully.'),
    })

    closeFlyout(FLYOUT_NAME)
  }
}
</script>

<template>
  <CommonFlyout
    :header-title="__('Link ticket')"
    header-icon="link"
    :name="FLYOUT_NAME"
    size="large"
    no-close-on-action
    :form="form"
    :footer-action-options="footerActionOptions"
  >
    <div class="space-y-6">
      <Form
        ref="form"
        :schema="formSchema"
        should-autofocus
        @submit="linkTicket($event as FormSubmitData<{ ticketId: string }>)"
      />

      <CommonLoader :loading="recentlyViewedIsLoading">
        <TicketSimpleTable
          v-if="recentlyViewedTickets?.length"
          :label="$t('Recently viewed tickets')"
          :tickets="recentlyViewedTickets"
          :selected-ticket-id="targetTicketId"
          @click-ticket="handleTicketClick"
        />
      </CommonLoader>
    </div>
  </CommonFlyout>
</template>
