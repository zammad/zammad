<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { DropdownItem } from '#desktop/components/CommonDropdown/types.ts'

import TopBarHeaderRow from './TopBarHeaderRow.vue'

import type { TopBarHeaderProps } from './types.ts'

defineProps<TopBarHeaderProps & { copyLabel?: string }>()

const selectedLocale = defineModel<DropdownItem>('selectedLocale')
</script>

<template>
  <header
    class="flex w-full items-center gap-x-2 border-b border-neutral-100 bg-neutral-50/80 px-5.5 py-3 backdrop-blur-2xs dark:border-gray-900 dark:bg-gray-500/80"
  >
    <TopBarHeaderRow v-bind="$props" v-model:selected-locale="selectedLocale" variant="compact">
      <template #stepper>
        <slot name="stepper" />
      </template>
    </TopBarHeaderRow>
  </header>
</template>
