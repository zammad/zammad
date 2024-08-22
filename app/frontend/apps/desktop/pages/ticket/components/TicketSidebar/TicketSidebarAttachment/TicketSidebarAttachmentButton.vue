<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, watch } from 'vue'

import { useArticleContext } from '#desktop/pages/ticket/composables/useArticleContext.ts'

import {
  type TicketSidebarButtonProps,
  type TicketSidebarButtonEmits,
  type TicketSidebarButtonBadgeDetails,
  TicketSidebarButtonBadgeType,
} from '../../types.ts'
import TicketSidebarButton from '../TicketSidebarButton.vue'

import { useTicketAttachments } from './useTicketAttachments.ts'

defineProps<TicketSidebarButtonProps>()

const emit = defineEmits<TicketSidebarButtonEmits>()

const { ticketAttachments, ticketAttachmentsQuery } = useTicketAttachments()

const { context: contextArticle } = useArticleContext()

watch(contextArticle.articles, (_, oldValue) => {
  if (oldValue === undefined) {
    return
  }

  ticketAttachmentsQuery.refetch()
})

watch(ticketAttachments, (newValue) => {
  if (newValue.length === 0) {
    emit('hide')
    return
  }
  emit('show')
})

const badge = computed<TicketSidebarButtonBadgeDetails | undefined>(() => {
  const label = __('Attachments')

  return {
    type: TicketSidebarButtonBadgeType.Info,
    value: ticketAttachments.value.length,
    label,
  }
})
</script>

<template>
  <TicketSidebarButton
    :key="sidebar"
    :name="sidebar"
    :label="sidebarPlugin.title"
    :icon="sidebarPlugin.icon"
    :selected="selected"
    :badge="badge"
  />
</template>
