<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div class="flex overflow-hidden flex-col h-screen">
    <main class="overflow-y-scroll flex-1">
      <router-view v-slot="{ Component }">
        <TransitionViewNavigation>
          <component v-bind:is="Component" />
        </TransitionViewNavigation>
      </router-view>
    </main>
    <footer
      v-if="showBottomNavigation"
      class="p-4 w-full text-center bg-black border-t"
    >
      Bottom-Navigation
    </footer>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import TransitionViewNavigation from '@mobile/components/transition/TransitionViewNavigation.vue'

const route = useRoute()

const showBottomNavigation = computed(() => {
  return route.meta.hasBottomNavigation
})
</script>
