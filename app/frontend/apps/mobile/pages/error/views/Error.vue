<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { errorOptions } from '@mobile/router/error'
</script>

<template>
  <main>
    <h1>{{ i18n.t('Error - %s', errorOptions.statusCode) }}</h1>
    <p>{{ errorOptions.message }}</p>
    <p v-if="errorOptions.route">
      {{ errorOptions.route }}
    </p>
  </main>
</template>
