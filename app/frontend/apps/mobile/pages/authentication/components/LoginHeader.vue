<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonLogo from '#shared/components/CommonLogo/CommonLogo.vue'

defineProps<{
  title: string
}>()
</script>

<template>
  <div class="flex justify-center p-2">
    <CommonLogo />
  </div>
  <h1 class="mb-6 flex justify-center p-2 text-2xl font-extrabold">
    {{ $t(title) }}
  </h1>
  <template v-if="$c.maintenance_mode">
    <div class="bg-red my-1 flex items-center rounded-xl px-4 py-2 text-white">
      {{
        $t(
          'Zammad is currently in maintenance mode. Only administrators can log in. Please wait until the maintenance window is over.',
        )
      }}
    </div>
  </template>
  <template v-if="$c.maintenance_login && $c.maintenance_login_message">
    <!-- eslint-disable vue/no-v-html -->
    <div
      class="bg-green my-1 flex items-center rounded-xl px-4 py-2 text-white"
      v-html="$c.maintenance_login_message"
    ></div>
  </template>
</template>
