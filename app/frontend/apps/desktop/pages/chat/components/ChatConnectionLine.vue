<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'

import type { ChatSession } from '#desktop/entities/chat/types.ts'

interface Props {
  // The page heads the thread; the address and the host name are for the info panel.
  session: Pick<ChatSession, 'createdAt' | 'geoIp'>
}

const props = defineProps<Props>()

const geoLocation = computed(() =>
  [props.session.geoIp?.countryName, props.session.geoIp?.cityName].filter(Boolean).join(', '),
)
</script>

<template>
  <div class="flex items-center justify-between gap-2 px-3 py-2">
    <CommonLabel class="shrink-0" size="small">
      <CommonDateTime :date-time="session.createdAt" />
    </CommonLabel>

    <CommonLabel
      v-if="geoLocation"
      class="min-w-0"
      icon-color="text-muted"
      size="small"
      suffix-icon="globe"
    >
      <span v-tooltip.truncate.supportive="geoLocation" class="truncate">{{ geoLocation }}</span>
    </CommonLabel>
  </div>
</template>
