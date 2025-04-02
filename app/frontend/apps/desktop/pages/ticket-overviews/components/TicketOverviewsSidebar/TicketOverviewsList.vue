<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import NavigationMenuList from '#desktop/components/NavigationMenu/NavigationMenuList.vue'
import type { NavigationMenuEntry } from '#desktop/components/NavigationMenu/types.ts'
import { useTicketOverviews } from '#desktop/pages/ticket-overviews/composables/useTicketOverviews.ts'

const { overviews, overviewsTicketCountById } = useTicketOverviews()

const overviewsItems = computed((): NavigationMenuEntry[] =>
  overviews.value?.map((item) => ({
    label: item.name,
    id: item.id,
    route: item.link,
    count: overviewsTicketCountById.value[item.id],
  })),
)
</script>

<template>
  <NavigationMenuList
    :aria-label="$t('Overview navigation list')"
    count-variant="info"
    count-size="xs"
    :items="overviewsItems"
  />
</template>
