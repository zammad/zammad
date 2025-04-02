<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSimpleTable from '#desktop/components/CommonTable/CommonSimpleTable.vue'
import type {
  TableSimpleHeader,
  TableItem,
} from '#desktop/components/CommonTable/types'

interface Props {
  items: TableItem[]
}

defineProps<Props>()

const headers: TableSimpleHeader[] = [
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
  <!-- TODO: Set needed props to disable infinite scrolling etc. -->
  <CommonSimpleTable
    v-if="items.length"
    :caption="$t('Idoit objects')"
    :items="items"
    :headers="headers"
    has-checkbox-column
  />
  <CommonLabel v-else>{{ $t('No results found') }}</CommonLabel>
</template>
