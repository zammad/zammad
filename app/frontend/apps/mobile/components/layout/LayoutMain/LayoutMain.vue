<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import TransitionViewNavigation from '../../transition/TransitionViewNavigation/TransitionViewNavigation.vue'

const route = useRoute()

const showBottomNavigation = computed(() => {
  return route.meta.hasBottomNavigation
})
</script>

<template>
  <div class="flex h-full flex-col overflow-hidden">
    <main class="flex-1 overflow-y-scroll">
      <router-view v-slot="{ Component }">
        <TransitionViewNavigation>
          <component :is="Component" />
        </TransitionViewNavigation>
      </router-view>
    </main>
    <footer
      v-if="showBottomNavigation"
      class="w-full border-t bg-black p-4 text-center"
    >
      Bottom-Navigation
    </footer>
  </div>
</template>
