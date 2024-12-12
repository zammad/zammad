<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useTicketSharedDraftStart } from '#shared/entities/ticket-shared-draft-start/composables/useTicketSharedDraftStart.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import {
  GraphQLErrorTypes,
  type GraphQLHandlerError,
} from '#shared/types/error.ts'

import { usePersistentStates } from '#desktop/pages/ticket/composables/usePersistentStates.ts'
import {
  type TicketSidebarProps,
  type TicketSidebarEmits,
} from '#desktop/pages/ticket/types/sidebar.ts'

import TicketSidebarWrapper from '../TicketSidebarWrapper.vue'

import TicketSidebarSharedDraftStartContent from './TicketSidebarSharedDraftStartContent.vue'

const props = defineProps<TicketSidebarProps>()

const { persistentStates } = usePersistentStates()

const emit = defineEmits<TicketSidebarEmits>()

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

const { sharedDraftStartListQuery, sharedDraftStartList } =
  useTicketSharedDraftStart(groupId, errorCallback)

sharedDraftStartListQuery.onResult(({ data }) => {
  if (!data?.ticketSharedDraftStartList) return

  emit('show')
})
</script>

<template>
  <TicketSidebarWrapper
    :key="sidebar"
    :sidebar="sidebar"
    :sidebar-plugin="sidebarPlugin"
    :selected="selected"
  >
    <TicketSidebarSharedDraftStartContent
      v-if="sharedDraftStartList"
      v-model="persistentStates"
      :context="context"
      :sidebar-plugin="sidebarPlugin"
      :shared-draft-start-list="sharedDraftStartList"
    />
  </TicketSidebarWrapper>
</template>
