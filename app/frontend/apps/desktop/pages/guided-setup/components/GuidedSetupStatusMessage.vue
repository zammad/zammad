<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'

interface Props {
  message?: string
}

defineProps<Props>()
</script>

<template>
  <div class="text-center mt-1">
    <CommonLabel v-if="message">
      {{ $t(message) }}
    </CommonLabel>
    <CommonLoader class="mt-9 mb-3" loading />
  </div>
</template>
