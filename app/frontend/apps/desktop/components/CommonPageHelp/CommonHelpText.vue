<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'

interface Props {
  helpText?: string | string[]
}

defineProps<Props>()
</script>

<template>
  <div class="ltr:text-left rtl:text-right">
    <template v-if="Array.isArray(helpText)">
      <CommonLabel
        v-for="(text, index) in helpText"
        :key="`${text}-${index}`"
        tag="p"
        >{{ text }}</CommonLabel
      >
    </template>
    <CommonLabel v-else tag="p">{{ helpText }}</CommonLabel>
  </div>
</template>
