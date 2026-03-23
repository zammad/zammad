<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onMounted } from 'vue'

const props = defineProps<{
  data: Record<string, unknown> | null
}>()

onMounted(() => {
  if (typeof props.data?.url === 'string') {
    window.location.href = props.data.url
  }
})
</script>

<template>
  <div class="text-center">{{ $t('Redirecting to authorization…') }}</div>
</template>
