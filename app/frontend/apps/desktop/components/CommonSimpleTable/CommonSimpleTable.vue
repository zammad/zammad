<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import type { MenuItem } from '#desktop/components/CommonPopover/types.ts'
import type { TableHeader, TableItem } from './types.ts'

export interface Props {
  headers: TableHeader[]
  items: TableItem[]
  actions?: MenuItem[]
}

defineProps<Props>()
</script>

<template>
  <table class="pb-3">
    <thead>
      <th
        v-for="header in headers"
        :key="header.key"
        class="h-10 p-2.5 text-xs font-normal text-stone-200 ltr:text-left rtl:text-right dark:text-neutral-500"
      >
        <span>{{ $t(header.label, ...(header.labelPlaceholder || [])) }}</span>
      </th>
      <th
        v-if="actions"
        class="h-10 p-2.5 text-xs font-normal text-stone-200 dark:text-neutral-500"
      >
        <span>{{ $t('Actions') }}</span>
      </th>
    </thead>
    <tbody>
      <tr v-for="(item, index) in items" :key="item.id">
        <td
          v-for="header in headers"
          :key="`${item.id}-${header.key}`"
          class="h-10 p-2.5 text-sm text-gray-100 first:rounded-s-md last:rounded-e-md dark:text-neutral-400"
          :class="{ 'bg-blue-200 dark:bg-gray-700': (index + 1) % 2 }"
        >
          <span>{{ item[header.key] || '-' }}</span>
        </td>
        <td
          v-if="actions"
          class="h-10 p-2.5 text-center first:rounded-s-md last:rounded-e-md"
          :class="{ 'bg-blue-200 dark:bg-gray-700': (index + 1) % 2 }"
        >
          <CommonActionMenu :actions="actions" :entity="item" />
        </td>
      </tr>
    </tbody>
  </table>
</template>
