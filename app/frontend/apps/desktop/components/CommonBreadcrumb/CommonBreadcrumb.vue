<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useLocaleStore } from '#shared/stores/locale.ts'

import type { BreadcrumbItem } from './types.ts'

defineProps<{
  items: BreadcrumbItem[]
}>()

const locale = useLocaleStore()
// TODO: Missing handling when there is not enough space for the breadcrumb
</script>

<template>
  <nav :aria-label="$t('Breadcrumb navigation')" class="max-w-full">
    <ol class="flex">
      <li v-for="(item, idx) in items" :key="item.label">
        <CommonIcon
          v-if="item.icon"
          :name="item.icon"
          size="xs"
          class="ltr:mr-1 rtl:ml-1"
        />

        <CommonLink v-if="item.route" :link="item.route" internal>
          <CommonLabel size="large" class="hover:underline">{{
            $t(item.label)
          }}</CommonLabel>
        </CommonLink>
        <h1 v-else aria-current="page">
          {{ $t(item.label) }}
        </h1>

        <CommonIcon
          v-if="idx !== items.length - 1"
          :name="
            locale.localeData?.dir === 'rtl' ? 'chevron-left' : 'chevron-right'
          "
          size="xs"
          class="mx-1 inline-flex"
        />
      </li>
    </ol>
  </nav>
</template>
