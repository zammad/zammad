<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { whenever } from '@vueuse/core'
import { computed } from 'vue'

import { useSessionStore } from '#shared/stores/session.ts'
import emitter from '#shared/utils/emitter.ts'

import OnlineNotification from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification.vue'
import QuickSearchInput from '#desktop/components/Search/QuickSearch/QuickSearchInput/QuickSearchInput.vue'

interface Props {
  collapsed?: boolean
}

defineProps<Props>()

const searchValue = defineModel<string>('search', {
  required: true,
})

const isSearchActive = defineModel<boolean>('search-active', {
  default: false,
})

whenever(
  () => !isSearchActive.value,
  () => {
    emitter.emit('close-popover')
  },
)

const { hasPermission } = useSessionStore()

const isTicketAgent = computed(() => hasPermission('ticket.agent') ?? false)
</script>

<template>
  <header class="flex gap-2 rounded-t-lg" :class="{ 'justify-center': collapsed }">
    <QuickSearchInput
      v-if="!collapsed"
      v-model="searchValue"
      v-model:search-active="isSearchActive"
      class="grow"
    />

    <component
      :is="isTicketAgent ? OnlineNotification : 'div'"
      v-show="!isSearchActive"
      class="flex items-center justify-center"
      :class="{ 'ltr:ml-auto rtl:mr-auto': !collapsed }"
    >
      <!--  :TODO Add custom branding  -->
      <CommonIcon name="logo" class="z-10 block h-9 w-9" />
    </component>
  </header>
</template>
