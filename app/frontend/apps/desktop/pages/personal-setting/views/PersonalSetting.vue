<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useSessionStore } from '#shared/stores/session.ts'

import LayoutSidebar from '#desktop/components/layout/LayoutSidebar.vue'
import { useResizeGridColumns } from '#desktop/composables/useResizeGridColumns.ts'
import PersonalSettingSidebar from '#desktop/pages/personal-setting/components/PersonalSettingSidebar.vue'

const { userId } = useSessionStore()
const storageKeyId = `${userId}-personal-setting`

const { gridColumns, collapseSidebar, expandSidebar } =
  useResizeGridColumns(storageKeyId)
</script>

<template>
  <div class="grid h-full duration-100" :style="gridColumns">
    <LayoutSidebar
      id="personal-settings-sidebar"
      :name="storageKeyId"
      collapsible
      class="bg-blue-50 dark:bg-gray-800"
      icon-collapsed="person-gear"
      @collapse="collapseSidebar"
      @expand="expandSidebar"
    >
      <PersonalSettingSidebar />
    </LayoutSidebar>

    <RouterView />
  </div>
</template>
