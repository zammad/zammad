<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

import CommonEmptyMessage from '#desktop/components/CommonEmptyMessage/CommonEmptyMessage.vue'

// The same backends the old caller log lists, linked to their admin pages in the old UI.
const backends = [
  { name: __('CTI (generic)'), link: '/#system/integration/cti' },
  { name: 'sipgate.io', link: '/#system/integration/sipgate' },
  { name: __('Placetel'), link: '/#system/integration/placetel' },
]

const session = useSessionStore()

const canConfigure = computed(() => session.hasPermission('admin.integration'))
</script>

<template>
  <CommonEmptyMessage
    class="absolute top-1/2 w-full -translate-y-1/2 text-center ltr:left-1/2 ltr:-translate-x-1/2 rtl:right-1/2 rtl:translate-x-1/2"
    :title="$t('Sorry, there is currently no CTI backend enabled.')"
    icon="x-circle"
  >
    <CommonLabel tag="p" class="block! pt-5">
      {{ $t('These are supported:') }}
    </CommonLabel>
    <ul class="mt-2 space-y-1">
      <li v-for="backend in backends" :key="backend.link">
        <CommonLink v-if="canConfigure" :link="backend.link" external size="medium">
          {{ $t(backend.name) }}
        </CommonLink>
        <CommonLabel v-else>{{ $t(backend.name) }}</CommonLabel>
      </li>
    </ul>
  </CommonEmptyMessage>
</template>
