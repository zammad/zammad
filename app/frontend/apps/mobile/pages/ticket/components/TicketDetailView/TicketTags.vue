<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { ref, toRef, watch } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import FormGroup from '#shared/components/Form/FormGroup.vue'
import { useTagAssignmentUpdateMutation } from '#shared/entities/tags/graphql/mutations/assignment/update.api.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import type { FormKitNode } from '@formkit/core'

interface Props {
  ticket: TicketById
}

const props = defineProps<Props>()
const ticketData = toRef(props, 'ticket')

const ticketTags = ref<string[]>(ticketData.value.tags || [])

watch(
  () => ticketData.value.tags,
  () => {
    ticketTags.value = ticketData.value.tags || []
  },
)

const tagAssigmentUpdateHandler = new MutationHandler(
  useTagAssignmentUpdateMutation({}),
  {
    errorNotificationMessage: __('Ticket tags could not be updated.'),
  },
)

const { notify } = useNotifications()

const handleChangedTicketTags = (node: FormKitNode) => {
  node.on('dialog:afterClose', async () => {
    const ticketId = ticketData.value.id

    // Wait until the value is updated after the dialog is closed (when it's used very fast).
    await node.settled

    if (!ticketId || isEqual(ticketTags.value, ticketData.value.tags)) return

    tagAssigmentUpdateHandler
      .send({
        objectId: ticketId,
        tags: ticketTags.value,
      })
      .then(() => {
        notify({
          id: 'ticket-tags-updated',
          type: NotificationTypes.Success,
          message: __('Ticket tags updated successfully.'),
        })
      })
      .catch(() => {
        // Reset tags again, when error occurs.
        ticketTags.value = ticketData.value.tags || []
      })
  })
}
</script>

<template>
  <FormGroup>
    <FormKit
      v-model="ticketTags"
      type="tags"
      name="tags"
      :label="__('Tags')"
      :plugins="[handleChangedTicketTags]"
      :can-create="Boolean($c.tag_new)"
    ></FormKit>
  </FormGroup>
</template>
