<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
/* eslint-disable vue/no-v-html */
import type { ObjectAttributeRichtext } from './attributeRichtextTypes'

defineProps<{
  attribute: ObjectAttributeRichtext
  value: string
}>()
</script>

<template>
  <div v-html="value" />
</template>
