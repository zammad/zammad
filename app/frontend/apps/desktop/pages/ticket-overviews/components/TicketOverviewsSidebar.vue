<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'

import TicketOverviewsList from '#desktop/pages/ticket-overviews/components/TicketOverviewsSidebar/TicketOverviewsList.vue'

const { hasPermission } = useSessionStore()

const hasOverviewSortingPreference = computed(() =>
  hasPermission('user_preferences.overview_sorting'),
)
</script>

<template>
  <section class="flex flex-col gap-2.5">
    <CommonLink
      v-if="hasOverviewSortingPreference"
      class="my-2.5 ltr:ml-auto rtl:mr-auto"
      internal
      link="/personal-setting/ticket-overviews"
    >
      <CommonLabel
        size="small"
        class="text-blue-800!"
        prefix-icon="list-columns-reverse"
      >
        {{ $t('reorder items') }}
      </CommonLabel>
    </CommonLink>

    <TicketOverviewsList />
  </section>
</template>
