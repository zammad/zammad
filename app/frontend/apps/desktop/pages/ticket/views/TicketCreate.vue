<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTicketCreateView } from '#shared/entities/ticket/composables/useTicketCreateView.ts'
import { ErrorRouteType, redirectErrorRoute } from '#shared/router/error.ts'
import { ErrorStatusCodes } from '#shared/types/error.ts'

import LayoutTaskbarTabContent from '#desktop/components/layout/LayoutTaskbarTabContent.vue'

import TicketCreateContent from '../components/TicketCreate/TicketCreateContent.vue'

interface Props {
  tabId: string
}

defineOptions({
  beforeRouteEnter(to) {
    const { ticketCreateEnabled, checkUniqueTicketCreateRoute } =
      useTicketCreateView()

    if (!ticketCreateEnabled.value)
      return redirectErrorRoute({
        type: ErrorRouteType.AuthenticatedError,
        title: __('Forbidden'),
        message: __('Creating new tickets via web is disabled.'),
        statusCode: ErrorStatusCodes.Forbidden,
      })

    return checkUniqueTicketCreateRoute(to)
  },
  beforeRouteUpdate(to) {
    // When route is updated we need to check again of the unique identifier.
    const { checkUniqueTicketCreateRoute } = useTicketCreateView()

    return checkUniqueTicketCreateRoute(to)
  },
})

defineProps<Props>()
</script>

<template>
  <LayoutTaskbarTabContent>
    <TicketCreateContent :tab-id="tabId" />
  </LayoutTaskbarTabContent>
</template>
