<!-- Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div id="Notifications" class="w-full flex justify-center">
    <div class="fixed z-50" style="top: 30px; right: 0">
      <transition-group
        tag="div"
        enter-class="opacity-0"
        leave-active-class="transition-opacity duration-1000 opacity-0"
      >
        <div v-for="notification in notifications" v-bind:key="notification.id">
          <div class="flex justify-center">
            <div class="flex items-center bg-black p-2 rounded text-white m-1">
              <CommonIcon
                name="diagonal-cross"
                v-bind:fixed-size="{ width: 16, height: 16 }"
              />
              <span class="ml-2">{{ notification.message }}</span>
            </div>
          </div>
        </div>
      </transition-group>
    </div>
  </div>
</template>

<script setup lang="ts">
import useNotifications from '@common/composables/useNotifications'

const { notifications } = useNotifications()
</script>
