<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div class="flex flex-col h-screen overflow-hidden">
    <main class="flex-1 overflow-y-scroll">
      <router-view v-slot="{ Component }">
        <TransitionViewNavigation>
          <component v-bind:is="Component" />
        </TransitionViewNavigation>
      </router-view>
    </main>
    <footer
      v-if="showBottomNavigation"
      class="w-full bg-darker text-center border-t p-4"
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
