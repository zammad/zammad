<!-- Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div v-if="show">
    <h1>{{ msg }}</h1>
    <p>The first component.</p>
  </div>
</template>

<script setup lang="ts">
defineProps<{ msg: string; show: boolean }>()
</script>
