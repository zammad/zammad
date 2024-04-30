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
        <CommonLabel
          class="font-normal text-stone-200 dark:text-neutral-500"
          size="small"
          >{{
            $t(header.label, ...(header.labelPlaceholder || []))
          }}</CommonLabel
        >

        <slot :name="`header-suffix-${header.key}`" :item="header" />
      </th>
      <th v-if="actions" class="h-10 w-0 p-2.5 text-center">
        <CommonLabel
          class="font-normal text-stone-200 dark:text-neutral-500"
          size="small"
          >{{ $t('Actions') }}</CommonLabel
        >
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
          <CommonLabel class="text-black dark:text-white">
            <template v-if="!item[header.key]">-</template>
            <template v-else-if="header.type === 'timestamp'">
              <CommonDateTime :date-time="item[header.key] as string" />
            </template>
            <template v-else>
              {{ item[header.key] }}
            </template>
          </CommonLabel>

          <slot :name="`item-suffix-${header.key}`" :item="item" />
        </td>
        <td
          v-if="actions"
          class="h-10 w-0 px-2.5 first:rounded-s-md last:rounded-e-md"
          :class="{ 'bg-blue-200 dark:bg-gray-700': (index + 1) % 2 }"
        >
          <CommonActionMenu
            class="flex items-center justify-center"
            :actions="actions"
            :entity="item"
            button-size="medium"
          />
        </td>
      </tr>
    </tbody>
  </table>
</template>
