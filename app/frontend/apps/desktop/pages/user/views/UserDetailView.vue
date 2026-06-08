<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import LayoutTaskbarTabContent from '#desktop/components/layout/LayoutTaskbarTabContent.vue'

import UserDetailViewContent from '../components/UserDetailViewContent.vue'

interface Props {
  internalId: string
}

defineProps<Props>()
</script>

<template>
  <LayoutTaskbarTabContent>
    <UserDetailViewContent :internal-id="internalId" />
  </LayoutTaskbarTabContent>
</template>
