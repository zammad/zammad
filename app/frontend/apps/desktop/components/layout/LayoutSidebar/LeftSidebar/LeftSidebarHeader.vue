<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import OnlineNotification from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification.vue'
import QuickSearchInput from '#desktop/components/Search/QuickSearch/QuickSearchInput/QuickSearchInput.vue'

interface Props {
  collapsed?: boolean
}

const searchValue = defineModel<string>('search', {
  required: true,
})

const isSearchActive = defineModel<boolean>('search-active', {
  default: false,
})

defineProps<Props>()
</script>

<template>
  <header
    class="flex gap-2 rounded-t-lg"
    :class="{ 'justify-center': collapsed }"
  >
    <QuickSearchInput
      v-if="!collapsed"
      v-model="searchValue"
      v-model:search-active="isSearchActive"
      class="grow"
    />

    <OnlineNotification
      v-show="!isSearchActive"
      :class="{ 'ltr:ml-auto rtl:mr-auto': !collapsed }"
    />
  </header>
</template>
