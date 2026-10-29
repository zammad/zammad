<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import { isSystemUser } from '#shared/entities/user/utils/isSystemUser.ts'

interface Props {
  ticket: TicketById
}

const props = defineProps<Props>()

const hasCustomer = computed(() => !isSystemUser(props.ticket.customer))

const organizationName = computed(() => props.ticket.organization?.name)
</script>

<template>
  <div v-if="hasCustomer || organizationName" class="mb-1 flex items-center gap-1">
    <CommonLabel v-if="hasCustomer" tag="p" class="line-clamp-1! max-w-1/2 shrink break-all">
      {{ ticket.customer.fullname }}
    </CommonLabel>
    <span v-if="hasCustomer && organizationName" aria-hidden="true"> &middot; </span>
    <CommonLabel v-if="organizationName" class="line-clamp-1! flex-1 grow break-all">
      {{ organizationName }}
    </CommonLabel>
  </div>
</template>
