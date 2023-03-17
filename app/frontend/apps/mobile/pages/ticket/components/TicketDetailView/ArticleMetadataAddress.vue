<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSectionMenuItem from '@mobile/components/CommonSectionMenu/CommonSectionMenuItem.vue'
import { computed } from 'vue'
import type { TicketArticle } from '@shared/entities/ticket/types'

interface Props {
  address?: TicketArticle['from']
  label: string
}

const props = defineProps<Props>()

const show = computed(() => {
  const { address } = props
  if (!address) return false
  return (address.raw && address.raw !== '-  <>') || address.parsed?.length
})
</script>

<template>
  <CommonSectionMenuItem v-if="address && show" :label="label">
    <div v-if="!address.parsed">{{ address.raw }}</div>
    <!-- TODO no design for how it looks, if there are more than 1 address -->
    <div
      v-for="(contact, idx) of address.parsed || []"
      :key="idx"
      data-test-id="metadataAddress"
    >
      <div>{{ contact.name }}</div>
      <div class="text-sm text-white/75">
        &lt;{{ contact.emailAddress }}&gt;
      </div>
    </div>
  </CommonSectionMenuItem>
</template>
