<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div v-if="show">
    <h1>{{ i18n.t(msg) }}</h1>
    <p>{{ i18n.t('The first component.') }}</p>
  </div>
</template>

<script setup lang="ts">
defineProps<{ msg: string; show: boolean }>()
</script>
