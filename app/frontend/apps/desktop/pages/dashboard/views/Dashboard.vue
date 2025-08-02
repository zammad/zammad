<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useSessionStore } from '#shared/stores/session.ts'

import LayoutMain from '#desktop/components/layout/LayoutMain.vue'
import TodaysTicketsWidget from '#desktop/components/TodaysTicketsWidget/TodaysTicketsWidget.vue'

const session = useSessionStore()
</script>

<template>
  <LayoutMain>
    <div class="p-6">
      <h1 class="mb-6 text-2xl font-bold">
        {{ $t('Welcome, %s!', session.user?.fullname) }}
      </h1>

      <div class="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
        <div class="md:col-span-2 lg:col-span-2">
          <TodaysTicketsWidget />
        </div>
      </div>
    </div>
  </LayoutMain>
</template>
