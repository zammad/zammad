<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'

interface Props {
  message?: string
}

defineProps<Props>()
</script>

<template>
  <div class="mt-1 text-center">
    <CommonLabel v-if="message">
      {{ $t(message) }}
    </CommonLabel>
    <CommonLoader class="mt-5 mb-3" loading />
  </div>
</template>
