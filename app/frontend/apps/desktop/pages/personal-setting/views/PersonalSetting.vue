<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import LayoutSidebar from '#desktop/components/layout/LayoutSidebar.vue'
import { SidebarName } from '#desktop/components/layout/types.ts'
import PersonalSettingSidebar from '#desktop/pages/personal-setting/components/PersonalSettingSidebar.vue'

import { usePersonalSettingStore } from '../stores/personalSetting.ts'

defineOptions({
  beforeRouteEnter(to) {
    usePersonalSettingStore().setPreviousPersonalSettingScreen(to.fullPath)

    return true
  },

  beforeRouteUpdate(to) {
    usePersonalSettingStore().setPreviousPersonalSettingScreen(to.fullPath)

    return true
  },
})
</script>

<template>
  <div class="grid h-full grid-cols-1 lg:grid-cols-[260px_1fr]">
    <LayoutSidebar
      id="personal-settings-sidebar"
      class="hidden lg:flex"
      :name="SidebarName.PersonalSetting"
      background-variant="secondary"
    >
      <PersonalSettingSidebar />
    </LayoutSidebar>

    <RouterView #default="{ Component }">
      <KeepAlive max="1">
        <component :is="Component" />
      </KeepAlive>
    </RouterView>
  </div>
</template>
