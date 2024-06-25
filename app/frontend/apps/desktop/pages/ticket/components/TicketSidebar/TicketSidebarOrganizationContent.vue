<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script lang="ts" setup>
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

import TicketSidebarContent from './TicketSidebarContent.vue'

import type { TicketSidebarContext } from '../types.ts'

interface Props {
  context: TicketSidebarContext
}

defineProps<Props>()

// TODO: Draw the rest of the owl.
const organization = {}
const actions: MenuItem[] = []
</script>

<template>
  <TicketSidebarContent
    :title="__('Organization')"
    icon="buildings"
    :entity="organization"
    :actions="actions"
  >
    <CommonLabel class="font-mono text-stone-200 dark:text-neutral-500"
      >// TODO</CommonLabel
    >
  </TicketSidebarContent>
</template>
