<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import OnlineNotification from '#desktop/components/layout/LayoutSidebar/LeftSidebar/LeftSidebarHeader/OnlineNotification.vue'

interface Props {
  collapsed?: boolean
}

defineProps<Props>()
</script>

<template>
  <header
    class="flex gap-2 rounded-t-lg pt-0.5"
    :class="{ 'justify-center': collapsed }"
  >
    <!--   :TODO Add search field  -->
    <OnlineNotification :class="{ 'ltr:ml-auto rtl:mr-auto': !collapsed }" />
  </header>
</template>
