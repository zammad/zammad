<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTicketCreate } from '#shared/entities/ticket/composables/useTicketCreate.ts'

const { ticketCreateEnabled } = useTicketCreate()
</script>

<template>
  <div
    v-if="ticketCreateEnabled"
    class="flex cursor-pointer items-center justify-end"
  >
    <CommonLink link="/tickets/create" :aria-label="$t('Create new ticket')">
      <CommonIcon name="mobile-add" size="small" decorative />
    </CommonLink>
  </div>
</template>
