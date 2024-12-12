<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import LayoutTaskbarTabContent from '#desktop/components/layout/LayoutTaskbarTabContent.vue'

import TicketDetailViewContent from '../components/TicketDetailView/TicketDetailViewContent.vue'

interface Props {
  internalId: string
}

defineProps<Props>()
</script>

<template>
  <LayoutTaskbarTabContent>
    <TicketDetailViewContent :internal-id="internalId" />
  </LayoutTaskbarTabContent>
</template>
