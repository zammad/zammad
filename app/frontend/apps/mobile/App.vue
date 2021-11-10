<!-- Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <CommonNotifications />
  <div
    class="
      h-full
      max-h-full
      overflow-auto
      w-full
      bg-gray-200
      text-center text-sm
      antialiased
      font-sans
      select-none
    "
  >
    <router-view v-if="applicationLoaded.value" v-slot="{ Component }">
      <transition>
        <component v-bind:is="Component" />
      </transition>
    </router-view>
  </div>
</template>

<script setup lang="ts">
import CommonNotifications from '@common/components/CommonNotifications.vue'
import useApplicationLoadedStore from '@common/stores/application/loaded'

const applicationLoaded = useApplicationLoadedStore()

applicationLoaded.setLoaded()
</script>
