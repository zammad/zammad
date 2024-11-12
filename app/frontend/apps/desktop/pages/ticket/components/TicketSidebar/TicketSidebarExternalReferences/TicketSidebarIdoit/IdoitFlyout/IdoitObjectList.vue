<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSimpleTable from '#desktop/components/CommonSimpleTable/CommonSimpleTable.vue'
import type {
  TableHeader,
  TableItem,
} from '#desktop/components/CommonSimpleTable/types.ts'

interface Props {
  items: TableItem[]
}

defineProps<Props>()

const headers: TableHeader[] = [
  { key: 'idoitObjectId', label: 'ID', truncate: true },
  {
    key: 'title',
    label: __('Name'),
    type: 'link',
    truncate: true,
  },
  { key: 'status', label: __('Status'), truncate: true },
]
</script>

<template>
  <CommonSimpleTable
    v-if="items.length"
    :items="items"
    :headers="headers"
    has-checkbox-column
  />
  <CommonLabel v-else>{{ $t('No results found') }}</CommonLabel>
</template>
