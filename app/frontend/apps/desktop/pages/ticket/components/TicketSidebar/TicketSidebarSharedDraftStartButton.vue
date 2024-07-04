<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useTicketSharedDraftStart } from '#shared/entities/ticket-shared-draft-start/composables/useTicketSharedDraftStart.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import {
  GraphQLErrorTypes,
  type GraphQLHandlerError,
} from '#shared/types/error.ts'

import TicketSidebarButton from './TicketSidebarButton.vue'

import type {
  TicketSidebarButtonProps,
  TicketSidebarButtonEmits,
} from '../types.ts'

const props = defineProps<TicketSidebarButtonProps>()

const emit = defineEmits<TicketSidebarButtonEmits>()

const groupId = computed(() =>
  convertToGraphQLId('Group', Number(props.context.formValues.group_id)),
)

// Silence query error notification in the frontend in case of unknown errors.
//   The query may raise a non-specific error if the group has inactive shared drafts.
//   Hide the sidebar in that case.
//   FIXME: Check if it's possible to silence the console error too.
const errorCallback = (error: GraphQLHandlerError) => {
  if (error.type === GraphQLErrorTypes.UnknownError) {
    emit('hide')
    return false
  }

  return true
}

const { sharedDraftStartListQuery } = useTicketSharedDraftStart(
  groupId,
  errorCallback,
)

sharedDraftStartListQuery.onResult(({ data }) => {
  if (!data?.ticketSharedDraftStartList) return

  emit('show')
})
</script>

<template>
  <TicketSidebarButton
    :key="sidebar"
    :name="sidebar"
    :label="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :selected="selected"
  />
</template>
