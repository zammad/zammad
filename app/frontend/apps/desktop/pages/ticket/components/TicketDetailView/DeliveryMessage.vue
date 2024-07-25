<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
interface Props {
  content: string
}

defineProps<Props>()
</script>

<template>
  <CommonAlert id="bottom" variant="warning">
    <p>{{ $t('Delivery failed: "%s"', content) }}</p>
  </CommonAlert>
</template>
