<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSimpleTable from '#desktop/components/CommonTable/CommonSimpleTable.vue'
import type { TableSimpleHeader, TableItem } from '#desktop/components/CommonTable/types'

interface Props {
  items: TableItem[]
}

defineProps<Props>()

const headers: TableSimpleHeader[] = [
  { key: 'snipeitAssetId', label: 'ID', truncate: true },
  {
    key: 'name',
    label: __('Name'),
    type: 'link',
    truncate: true,
  },
  { key: 'assetTag', label: __('Asset Tag'), truncate: true },
  { key: 'status', label: __('Status'), truncate: true },
]
</script>

<template>
  <CommonSimpleTable
    v-if="items.length"
    :caption="$t('Snipe-IT assets')"
    :items="items"
    :headers="headers"
    has-checkbox-column
  />
  <CommonLabel v-else>{{ $t('No results found') }}</CommonLabel>
</template>
