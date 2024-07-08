<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, provide } from 'vue'

import AvatarMenu from '#desktop/components/layout/LayoutSidebar/LeftSidebar/AvatarMenu/AvatarMenu.vue'
import MenuContainer from '#desktop/components/layout/LayoutSidebar/LeftSidebar/MenuContainer/MenuContainer.vue'
import { COLLAPSED_STATE_KEY } from '#desktop/components/layout/LayoutSidebar/LeftSidebar/useCollapsedState.ts'

const props = defineProps<{
  collapsed?: boolean
}>()

provide(
  COLLAPSED_STATE_KEY,
  computed(() => props.collapsed),
)
</script>

<template>
  <section
    class="flex flex-row items-center justify-between"
    :class="{ 'mx-auto mb-0.5 flex-col': collapsed }"
  >
    <AvatarMenu />
    <MenuContainer />
  </section>
</template>
