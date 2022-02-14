<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div v-if="show">
    <h1>{{ i18n.t(msg) }}</h1>
    <p>{{ i18n.t('The first component.') }}</p>
    <p>{{ manualTranslation }}</p>
  </div>
</template>

<script setup lang="ts">
import { i18n } from '@common/utils/i18n'
import { computed } from 'vue'

defineProps<{ msg: string; show: boolean }>()

const manualTranslation = computed(() => {
  return i18n.t('The second component.')
})
</script>
